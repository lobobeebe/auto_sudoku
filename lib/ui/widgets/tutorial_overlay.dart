import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/state/board_state/unit_state.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:auto_sudoku_solver/data/tutorial.dart';
import 'package:auto_sudoku_solver/data/tutorial_step.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shared controller so overlay mask and bottom panel stay in sync
class TutorialController extends ChangeNotifier {
  final Tutorial tutorial;
  int index;
  bool _isDone = false;
  final Map<int, BoardSnapshot> _stepSnapshots = {};

  TutorialController({required this.tutorial, this.index = 0});

  TutorialStep get current => tutorial.steps[index];
  bool get hasPrev => index > 0;
  bool get hasNext => index < tutorial.steps.length - 1;
  bool get isDone => _isDone;

  void captureSnapshotIfNeeded(SudokuBoardState board) {
    if (_stepSnapshots.containsKey(index)) return;
    final snap = board.makeSnapshot();
    _stepSnapshots[index] = snap;
    board.pushSnapshot(snapshot: snap);
  }

  void next() {
    if (hasNext) {
      index++;
      notifyListeners();
    } else {
      _isDone = true;
      notifyListeners();
    }
  }

  void back(SudokuBoardState board) {
    if (hasPrev) {
      final target = index - 1;
      index = target;
      final snap = _stepSnapshots[target];
      if (snap != null) {
        board.restoreSnapshot(snap);
      }
      _isDone = false;
      notifyListeners();
    }
  }

  static TutorialController? of(BuildContext context) {
    try {
      return Provider.of<TutorialController>(context);
    } catch (_) {
      return null;
    }
  }
}

/// Grid-only mask that can be used with [TutorialController]
class GridMaskOverlay extends StatelessWidget {
  const GridMaskOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TutorialController.of(context);
    final board = Provider.of<SudokuBoardState>(context, listen: false);

    // If no active tutorial, ensure no auto-advance listener remains.
    if (controller == null || controller.isDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        board.onHintApplied = null;
      });
      return SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final enterStep = controller.current;
        controller.captureSnapshotIfNeeded(board);

        if (enterStep.selectedIndices != null) {
          // Defer mutation + notify to after this build to avoid
          // setState/notify during build exceptions.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            board.selectedIndices
              ..clear()
              ..addAll(enterStep.selectedIndices!);
            if (enterStep.selectedIndices!.isEmpty) {
              board.setMode(UnitMode(board));
            }
            board.emitChange();
          });
        }

        // Apply per-step solver settings (default to none if not provided)
        board.applyTutorialSolverSettings(
          enterStep.solverSettings ?? const SolverSettings(),
        );
        board.applyAutoNextSettings(
          SolverSettings(allowed: enterStep.autoSolveAllowed),
        );

        final maskBase = _stepForMask(
          controller.tutorial.steps,
          controller.index,
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final grid = _gridRect(size);
            // Build allowed rects: if explicit mask indices are provided,
            // they take precedence. Otherwise, use the step's units/cells.
            final allowedRects = enterStep.maskIndices != null
                ? _computeVisualRects(
                    grid,
                    TutorialStep(
                      cells: enterStep.maskIndices!,
                      title: '',
                      body: '',
                    ),
                  )
                : _computeVisualRects(grid, maskBase);
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _OverlayPainter(allowed: allowedRects, grid: grid),
                ),
                AnimatedBuilder(
                  animation: board,
                  builder: (context, _) {
                    final highlights = _resolveHighlightIndices(
                      enterStep,
                      board,
                    );
                    if (highlights.isEmpty) return const SizedBox.shrink();
                    return _TappableHighlights(
                      gridRect: grid,
                      highlightedIndices: highlights,
                    );
                  },
                ),
                _TouchShield(
                  gridRect: grid,
                  step: enterStep,
                  board: board,
                  controller: controller,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Bottom panel suitable for above the Action Bar
class TutorialPanel extends StatelessWidget {
  const TutorialPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final controller = TutorialController.of(context);
    final board = Provider.of<SudokuBoardState>(context, listen: false);

    if (controller == null || controller.isDone) {
      // Ensure any previous auto-advance listener is removed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        board.onHintApplied = null;
      });
      return SizedBox.shrink();
    }

    // Choose panel alignment: top, center, or bottom (default center)
    final align = () {
      switch (controller.current.dialogAlignment) {
        case TutorialDialogAlignment.top:
          return Alignment.topCenter;
        case TutorialDialogAlignment.center:
          return Alignment.center;
        case TutorialDialogAlignment.bottom:
          return Alignment.bottomCenter;
      }
    }();

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: SafeArea(
          child: Align(
            alignment: align,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final step = controller.current;
                    final canGoNext =
                        controller.hasNext &&
                        step.advanceOnValue == null &&
                        step.advanceOnStrategy == null &&
                        (step.advanceOnIndices == null ||
                            step.advanceOnIndices!.isEmpty);
                    void handleNextPressed() {
                      controller.next();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        board.runAutoSolverIfAvailable();
                      });
                    }

                    // Install or update board-level hooks so advancing and
                    // auto-solve work even when the grid mask is not present.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      // Advance on matching strategy whenever a hint is applied.
                      board.onHintApplied = (hint) {
                        final expect = controller.current.advanceOnStrategy;
                        if (!controller.isDone &&
                            expect != null &&
                            hint.strategy == expect) {
                          controller.next();
                        }
                      };
                    });
                    return Card(
                      elevation: 3,
                      color: colors.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step.body,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton.filledTonal(
                                  tooltip: 'Back',
                                  onPressed: controller.hasPrev
                                      ? () => controller.back(board)
                                      : null,
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                                const Spacer(),
                                if (controller.hasNext)
                                  IconButton.filled(
                                    tooltip: 'Next',
                                    onPressed: canGoNext
                                        ? handleNextPressed
                                        : null,
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                    ),
                                  )
                                else
                                  IconButton.filled(
                                    onPressed: handleNextPressed,
                                    icon: const Icon(Icons.check_rounded),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared dialog card used by tutorial overlays to render step content
class TutorialStepDialog extends StatelessWidget {
  final String title;
  final String body;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final bool showDoneLabel;
  final EdgeInsetsGeometry padding;
  final double elevation;

  const TutorialStepDialog({
    super.key,
    required this.title,
    required this.body,
    required this.hasPrev,
    required this.hasNext,
    required this.onBack,
    required this.onNext,
    this.showDoneLabel = true,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 12, 12),
    this.elevation = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Back',
                  onPressed: hasPrev ? onBack : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                if (hasNext)
                  IconButton.filled(
                    tooltip: 'Next',
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  )
                else if (showDoneLabel)
                  FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Done'),
                  )
                else
                  IconButton.filled(
                    onPressed: onNext,
                    icon: const Icon(Icons.check_rounded),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Visual clear areas (rounded rects) with a bit of padding outside the unit
List<RRect> _computeVisualRects(Rect grid, TutorialStep step) {
  final w = grid.width / 9;
  final h = grid.height / 9;
  final borderRadius = Radius.circular((w + h) * 0.06);
  // Padding expands outside unit to provide breathing room
  const pad = 6.0;
  final rects = <RRect>[];

  // Rows
  for (final r in step.maskRows) {
    if (r < 0 || r > 8) continue;
    final base = Rect.fromLTWH(grid.left, grid.top + r * h, grid.width, h);
    final rr = _inflateAndClampRRect(base, borderRadius, pad, grid.size, grid);
    rects.add(rr);
  }
  // Cols
  for (final c in step.maskCols) {
    if (c < 0 || c > 8) continue;
    final base = Rect.fromLTWH(grid.left + c * w, grid.top, w, grid.height);
    final rr = _inflateAndClampRRect(base, borderRadius, pad, grid.size, grid);
    rects.add(rr);
  }
  // Boxes
  for (final b in step.maskBoxes) {
    if (b < 0 || b > 8) continue;
    final br = b ~/ 3;
    final bc = b % 3;
    final base = Rect.fromLTWH(
      grid.left + bc * 3 * w,
      grid.top + br * 3 * h,
      3 * w,
      3 * h,
    );
    final rr = _inflateAndClampRRect(base, borderRadius, pad, grid.size, grid);
    rects.add(rr);
  }
  // Cells
  for (final idx in step.cells) {
    if (idx < 0 || idx > 80) continue;
    final r = idx ~/ 9;
    final c = idx % 9;
    final base = Rect.fromLTWH(grid.left + c * w, grid.top + r * h, w, h);
    final rr = _inflateAndClampRRect(base, borderRadius, pad, grid.size, grid);
    rects.add(rr);
  }

  return rects;
}

RRect _inflateAndClampRRect(
  Rect base,
  Radius radius,
  double pad,
  Size bounds,
  Rect grid,
) {
  final inflated = base.inflate(pad);
  // Clamp to grid rect, not full parent.
  final left = math.max(grid.left, inflated.left);
  final top = math.max(grid.top, inflated.top);
  final right = math.min(grid.right, inflated.right);
  final bottom = math.min(grid.bottom, inflated.bottom);
  final width = math.max(0.0, right - left);
  final height = math.max(0.0, bottom - top);
  final clamped = Rect.fromLTWH(left, top, width, height);
  final maxRadius = math.min(width, height) / 2;
  final eff = Radius.circular(math.min(radius.x, maxRadius));
  return RRect.fromRectAndRadius(clamped, eff);
}

Rect _gridRect(Size size) {
  final side = math.min(size.width, size.height);
  final dx = (size.width - side) / 2;
  final dy = (size.height - side) / 2;
  return Rect.fromLTWH(dx, dy, side, side);
}

// Fallback-friendly access so older summaries still compile if the dependency
// surface hasn't been rebuilt yet.
extension _TutorialStepHighlightAccess on TutorialStep {
  Set<int>? get highlightedIndicesCompat {
    try {
      final dynamic self = this;
      return self.highlightedIndices as Set<int>?;
    } catch (_) {
      return null;
    }
  }
}

Set<int> _resolveHighlightIndices(TutorialStep step, SudokuBoardState board) {
  final base = step.highlightedIndicesCompat ?? step.tappableIndices;
  if (base == null || base.isEmpty) return const <int>{};
  final selected = board.selectedIndices.toSet();
  final filtered = <int>{};
  for (final idx in base) {
    if (idx < 0 || idx > 80) continue;
    if (selected.contains(idx)) continue;
    filtered.add(idx);
  }
  return filtered;
}

// Determine the mask for the current step only (no merging from others).
TutorialStep _stepForMask(List<TutorialStep> steps, int index) {
  if (index < 0 || index >= steps.length) return steps.first;
  return steps[index];
}

bool _isTapAllowed({
  required int row,
  required int col,
  required TutorialStep step,
  required SudokuBoardState board,
}) {
  if (step.preventGridTaps) return false;

  final idx = row * 9 + col;
  final box = (row ~/ 3) * 3 + (col ~/ 3);

  final hasAny =
      (step.maskIndices != null && step.maskIndices!.isNotEmpty) ||
      (step.tappableIndices != null && step.tappableIndices!.isNotEmpty) ||
      step.maskRows.isNotEmpty ||
      step.maskCols.isNotEmpty ||
      step.maskBoxes.isNotEmpty ||
      step.cells.isNotEmpty ||
      step.advanceOnValue != null;
  if (!hasAny) return false;

  bool baseAllowed =
      (step.maskIndices?.contains(idx) ?? false) ||
      (step.tappableIndices?.contains(idx) ?? false) ||
      step.cells.contains(idx) ||
      step.maskRows.contains(row) ||
      step.maskCols.contains(col) ||
      step.maskBoxes.contains(box);
  if (!baseAllowed) return false;

  if (step.advanceOnValue != null) {
    final required = step.advanceOnValue!;
    if (board.sudoku.isEmpty(idx) || board.sudoku.valueAt(idx) != required) {
      return false;
    }
  }

  if (step.tappableIndices != null && !step.tappableIndices!.contains(idx)) {
    return false;
  }

  return true;
}

bool _processGridTap({
  required int row,
  required int col,
  required TutorialStep step,
  required SudokuBoardState board,
  TutorialController? controller,
}) {
  if (!_isTapAllowed(row: row, col: col, step: step, board: board)) {
    return false;
  }

  board.requestSelectCell(row, col);
  final idx = row * 9 + col;
  if (step.advanceOnIndices != null && step.advanceOnIndices!.contains(idx)) {
    controller?.next();
    return true;
  }
  if (step.advanceOnValue != null) {
    controller?.next();
  }
  return true;
}

class _TappableHighlights extends StatefulWidget {
  final Rect gridRect;
  final Set<int> highlightedIndices;

  const _TappableHighlights({
    required this.gridRect,
    required this.highlightedIndices,
  });

  @override
  State<_TappableHighlights> createState() => _TappableHighlightsState();
}

class _TappableHighlightsState extends State<_TappableHighlights>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _TappableHighlights oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightedIndices != widget.highlightedIndices ||
        oldWidget.gridRect != widget.gridRect) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.highlightedIndices.isEmpty) {
      return const SizedBox.shrink();
    }

    final anim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final t = anim.value;
        final pulse = 0.94 + 0.08 * t;
        final borderColor = const Color(0xFF2D8CFF);
        final cellW = widget.gridRect.width / 9;
        final cellH = widget.gridRect.height / 9;

        return IgnorePointer(
          child: Stack(
            children: [
              for (final idx in widget.highlightedIndices)
                Positioned(
                  left: widget.gridRect.left + (idx % 9) * cellW,
                  top: widget.gridRect.top + (idx ~/ 9) * cellH,
                  width: cellW,
                  height: cellH,
                  child: Transform.scale(
                    scale: pulse,
                    alignment: Alignment.center,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: borderColor.withValues(alpha: 0.65 + 0.25 * t),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final List<RRect> allowed;
  final Rect grid;
  _OverlayPainter({required this.allowed, required this.grid});

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.5);
    // Build a single union of holes to avoid even-odd toggling when they overlap.
    final holes = Path();
    for (final r in allowed) {
      holes.addRRect(r);
    }
    // Only cover the grid area, not the full widget.
    final full = Path()..addRect(grid);
    final mask = Path.combine(PathOperation.difference, full, holes);
    canvas.drawPath(mask, scrim);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.allowed != allowed || oldDelegate.grid != grid;
  }
}

class _TouchShield extends StatelessWidget {
  final Rect gridRect; // Square grid area within parent
  final TutorialStep step; // For precise hit-testing
  final SudokuBoardState board;
  final TutorialController? controller;
  const _TouchShield({
    required this.gridRect,
    required this.step,
    required this.board,
    this.controller,
  });

  bool _hitAllowed(Offset pos, Size size) {
    final w = size.width / 9;
    final h = size.height / 9;
    final col = (pos.dx ~/ w).clamp(0, 8);
    final row = (pos.dy ~/ h).clamp(0, 8);
    return _isTapAllowed(row: row, col: col, step: step, board: board);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final pos = details.localPosition;
        // Only handle touches inside the grid bounds
        if (!gridRect.contains(pos)) {
          // Block
          return;
        }
        final rel = Offset(pos.dx - gridRect.left, pos.dy - gridRect.top);
        if (!_hitAllowed(rel, gridRect.size)) {
          return;
        }
        // Map to row/col and forward selection within the square grid
        final cellW = gridRect.width / 9;
        final cellH = gridRect.height / 9;
        int col = (rel.dx ~/ cellW).clamp(0, 8);
        int row = (rel.dy ~/ cellH).clamp(0, 8);
        _processGridTap(
          row: row,
          col: col,
          step: step,
          board: board,
          controller: controller,
        );
      },
    );
  }
}
