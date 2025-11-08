import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

class TutorialStep {
  final Set<int> maskRows;
  final Set<int> maskCols;
  final Set<int> maskBoxes;
  final Set<int> cells; // indices 0..80
  final String title;
  final String body;
  // When true, show a centered dialog and do not
  // highlight any specific grid region for this step.
  final bool centerDialog;
  // If set, this step requires the user to tap a grid cell whose
  // filled-in value equals this digit; upon a valid tap, the tutorial
  // auto-advances. All other grid taps are blocked.
  final int? expectSelectValue;
  // Whether the Action Bar should be enabled during this step.
  // Defaults to false so controls are disabled unless explicitly allowed.
  final bool enableActionBar;
  // When not null, sets the current grid selection when the step becomes active.
  final Set<int>? selectedIndices;
  // When true, block all grid taps for this step regardless of highlights.
  // Defaults to true to keep the tutorial strictly guided unless opted out.
  final bool preventGridTaps;
  // Optional: explicit set of grid indices (0..80) to show/allow in the
  // mask overlay for this step. When provided, this takes precedence over
  // rows/cols/boxes/cells for visual holes and tap allowance.
  final Set<int>? maskIndices;
  // Optional per-step solver settings to apply on the board while
  // this step is active. If null, defaults to none (disable hints).
  final SolverSettings? solverSettings;

  const TutorialStep({
    this.maskRows = const {},
    this.maskCols = const {},
    this.maskBoxes = const {},
    this.cells = const {},
    required this.title,
    required this.body,
    this.centerDialog = false,
    this.expectSelectValue,
    this.enableActionBar = false,
    this.selectedIndices,
    this.solverSettings,
    this.preventGridTaps = true,
    this.maskIndices,
  });

  bool get hasAnyAllow =>
      (maskIndices != null && maskIndices!.isNotEmpty) ||
      maskRows.isNotEmpty ||
      maskCols.isNotEmpty ||
      maskBoxes.isNotEmpty ||
      cells.isNotEmpty;
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback? onDone;

  const TutorialOverlay({super.key, required this.steps, this.onDone});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

/// Shared controller so overlay mask and bottom panel stay in sync
class TutorialController extends ChangeNotifier {
  final List<TutorialStep> steps;
  int index;
  final VoidCallback? onDone;

  TutorialController({required this.steps, this.index = 0, this.onDone});

  TutorialStep get current => steps[index];
  bool get hasPrev => index > 0;
  bool get hasNext => index < steps.length - 1;

  void next() {
    if (hasNext) {
      index++;
      notifyListeners();
    } else {
      onDone?.call();
    }
  }

  void back() {
    if (hasPrev) {
      index--;
      notifyListeners();
    }
  }
}

/// Grid-only mask that can be used with [TutorialController]
class GridMaskOverlay extends StatefulWidget {
  final TutorialController controller;
  const GridMaskOverlay({super.key, required this.controller});

  @override
  State<GridMaskOverlay> createState() => _GridMaskOverlayState();
}

class _GridMaskOverlayState extends State<GridMaskOverlay> {
  int _lastIndex = -1;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final board = Provider.of<SudokuBoardState>(context, listen: false);

        // Step-change hook: run enter behaviors once when index changes
        if (_lastIndex != widget.controller.index) {
          _lastIndex = widget.controller.index;
          final enterStep = widget.controller.current;
          if (enterStep.selectedIndices != null) {
            // Defer mutation + notify to after this build to avoid
            // setState/notify during build exceptions.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              board.selectedIndices
                ..clear()
                ..addAll(enterStep.selectedIndices!);
              board.emitChange();
            });
          }
        }

        // Determine which areas should be allowed for this step.
        final logicalStep = widget.controller.current;
        // Apply per-step solver settings (default to none if not provided)
        board.applyTutorialSolverSettings(
          logicalStep.solverSettings ?? const SolverSettings(),
        );
        final maskBase = _stepForMask(
          widget.controller.steps,
          widget.controller.index,
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final grid = _gridRect(size);
            // Build allowed rects: if explicit mask indices are provided,
            // they take precedence. Otherwise, use the step's units/cells.
            final allowedRects = logicalStep.maskIndices != null
                ? _computeVisualRects(
                    grid,
                    TutorialStep(
                      cells: logicalStep.maskIndices!,
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
                _TouchShield(
                  gridRect: grid,
                  step: logicalStep,
                  board: board,
                  controller: widget.controller,
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
  final TutorialController controller;
  const TutorialPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final step = controller.current;
        final canGoNext = controller.hasNext && step.expectSelectValue == null;
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Back',
                      onPressed: controller.hasPrev ? controller.back : null,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Spacer(),
                    if (controller.hasNext)
                      IconButton.filled(
                        tooltip: 'Next',
                        onPressed: canGoNext ? controller.next : null,
                        icon: const Icon(Icons.arrow_forward_rounded),
                      )
                    else
                      IconButton.filled(
                        onPressed: controller.next,
                        icon: const Icon(Icons.check_rounded),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

/// Centered dialog overlay that listens to the same TutorialController
/// and only renders for steps marked with `centerDialog`.
class CenterDialogOverlay extends StatelessWidget {
  final TutorialController controller;
  const CenterDialogOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final step = controller.current;
        if (!step.centerDialog) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final grid = _gridRect(size);
            return Stack(
              fit: StackFit.expand,
              children: [
                // The grid mask is painted by GridMaskOverlay; this widget
                // focuses on presenting a centered dialog.
                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: grid.width * 0.7),
                    child: TutorialStepDialog(
                      title: step.title,
                      body: step.body,
                      hasPrev: controller.hasPrev,
                      hasNext: controller.hasNext,
                      onBack: controller.back,
                      onNext: step.expectSelectValue == null
                          ? controller.next
                          : null,
                      showDoneLabel: true,
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                      elevation: 10,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _index = 0;

  void _next() {
    if (_index < widget.steps.length - 1) {
      setState(() => _index++);
    } else {
      widget.onDone?.call();
    }
  }

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final displayStep = widget.steps[_index];
    final maskStep = _stepForMask(widget.steps, _index);

    return LayoutBuilder(
      builder: (context, constraints) {
        final board = Provider.of<SudokuBoardState>(context, listen: false);
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final grid = _gridRect(size);
        final allowedRects = _computeVisualRects(grid, maskStep);
        final union = _unionRect(allowedRects);

        // Decide dialog placement opposite the union center (within grid)
        final gridCenter = grid.center;
        final center = union?.center ?? gridCenter;
        final placeTop = center.dy > gridCenter.dy;
        final placeLeft = center.dx > gridCenter.dx;
        final alignment = Alignment(
          placeLeft ? -0.9 : 0.9,
          placeTop ? -0.9 : 0.9,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // Dimmer with cutouts
            CustomPaint(
              painter: _OverlayPainter(allowed: allowedRects, grid: grid),
            ),

            // Capture touches and forward only inside allowed
            _TouchShield(
              gridRect: grid,
              step: maskStep,
              board: board,
              controller: null,
            ),

            // Small dialog
            Align(
              alignment: alignment,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: grid.width * 0.58),
                child: TutorialStepDialog(
                  title: displayStep.title,
                  body: displayStep.body,
                  hasPrev: _index > 0,
                  hasNext: _index < widget.steps.length - 1,
                  onBack: _back,
                  onNext: displayStep.expectSelectValue == null ? _next : null,
                  showDoneLabel: true,
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                  elevation: 8,
                ),
              ),
            ),
          ],
        );
      },
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

// Determine the mask for the current step only (no merging from others).
TutorialStep _stepForMask(List<TutorialStep> steps, int index) {
  if (index < 0 || index >= steps.length) return steps.first;
  return steps[index];
}

// Helper: build a step that highlights all cells containing a given value
TutorialStep _stepWithMatchingValue(SudokuBoardState board, int value) {
  final cells = <int>{};
  for (int i = 0; i < 81; i++) {
    if (!board.sudoku.isEmpty(i) && board.sudoku.valueAt(i) == value) {
      cells.add(i);
    }
  }
  return TutorialStep(cells: cells, title: '', body: '');
}

Rect? _unionRect(List<RRect> rects) {
  if (rects.isEmpty) return null;
  Rect? u;
  for (final r in rects) {
    u = u == null ? r.outerRect : u.expandToInclude(r.outerRect);
  }
  return u;
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
    // Global per-step block: when set, never allow grid taps
    if (step.preventGridTaps) return false;

    // No targets -> block (unless expecting a specific value tap)
    final hasAny =
        (step.maskIndices != null && step.maskIndices!.isNotEmpty) ||
        step.maskRows.isNotEmpty ||
        step.maskCols.isNotEmpty ||
        step.maskBoxes.isNotEmpty ||
        step.cells.isNotEmpty ||
        step.expectSelectValue != null;
    if (!hasAny) return false;

    final w = size.width / 9;
    final h = size.height / 9;
    final col = (pos.dx ~/ w).clamp(0, 8);
    final row = (pos.dy ~/ h).clamp(0, 8);
    final box = (row ~/ 3) * 3 + (col ~/ 3);
    final idx = row * 9 + col;

    // If explicit mask indices provided, restrict taps to those indices.
    if (step.maskIndices != null) {
      if (!step.maskIndices!.contains(idx)) return false;
    } else {
      if (step.cells.contains(idx)) return true;
      if (step.maskRows.contains(row)) return true;
      if (step.maskCols.contains(col)) return true;
      if (step.maskBoxes.contains(box)) return true;
      // if none matched, reject
      return false;
    }

    // If a specific selection value is required, further restrict to cells
    // whose filled value matches that digit.
    if (step.expectSelectValue != null) {
      final required = step.expectSelectValue!;
      if (board.sudoku.isEmpty(idx) || board.sudoku.valueAt(idx) != required) {
        return false;
      }
    }

    return true;
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
        board.requestSelectCell(row, col);
        if (step.expectSelectValue != null) {
          controller?.next();
        }
      },
    );
  }
}
