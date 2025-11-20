import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final int? advanceOnValue;
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
  // Optional: when provided, moving to the next step automatically if the
  // user taps any of these indices.
  final Set<int>? advanceOnIndices;
  // Optional: when provided, only these indices are allowed to be tapped,
  // even if the overlay/mask visually allows more. The overlay still
  // prevents taps; this list adds an extra restriction.
  final Set<int>? tappableIndices;
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
    this.advanceOnValue,
    this.enableActionBar = false,
    this.selectedIndices,
    this.solverSettings,
    this.preventGridTaps = true,
    this.maskIndices,
    this.advanceOnIndices,
    this.tappableIndices,
  });

  bool get hasAnyAllow =>
      (maskIndices != null && maskIndices!.isNotEmpty) ||
      maskRows.isNotEmpty ||
      maskCols.isNotEmpty ||
      maskBoxes.isNotEmpty ||
      cells.isNotEmpty;

  // Deserialize a step from JSON.
  // Supported keys:
  // - title, body, centerDialog, enableActionBar, preventGridTaps
  // - maskRows, maskCols, maskBoxes, cells, maskIndices, selectedIndices,
  //   advanceOnIndices, tappableIndices (all arrays of ints)
  // - advanceOnValue (int)
  // - solver: { allowed: [StrategyType names or labels] }
  factory TutorialStep.fromJson(Map<String, dynamic> json) {
    Set<int> set(dynamic v) {
      final list = (v is List) ? v : const <dynamic>[];
      return list
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>()
          .toSet();
    }

    SolverSettings? solverSettings;
    final solver = json['solver'];
    if (solver is Map) {
      final allowedRaw = solver['allowed'];
      if (allowedRaw is List) {
        final allowed = <StrategyType>{};
        for (final item in allowedRaw) {
          final s = item.toString();
          // Match by enum name or toString label
          StrategyType? match;
          for (final t in StrategyType.values) {
            if (t.name.toLowerCase() == s.toLowerCase() ||
                t.toString().toLowerCase() == s.toLowerCase()) {
              match = t;
              break;
            }
          }
          if (match != null) allowed.add(match);
        }
        solverSettings = SolverSettings(allowed: allowed);
      }
    }

    return TutorialStep(
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      centerDialog: json['centerDialog'] == true,
      enableActionBar: json['enableActionBar'] == true,
      preventGridTaps: json['preventGridTaps'] != false, // default true
      advanceOnValue: json['advanceOnValue'] is int
          ? json['advanceOnValue'] as int
          : int.tryParse(json['advanceOnValue']?.toString() ?? ''),
      maskRows: set(json['maskRows']),
      maskCols: set(json['maskCols']),
      maskBoxes: set(json['maskBoxes']),
      cells: set(json['cells']),
      maskIndices: set(json['maskIndices']).isEmpty
          ? null
          : set(json['maskIndices']),
      selectedIndices: set(json['selectedIndices']).isEmpty
          ? null
          : set(json['selectedIndices']),
      advanceOnIndices: set(json['advanceOnIndices']).isEmpty
          ? null
          : set(json['advanceOnIndices']),
      tappableIndices: set(json['tappableIndices']).isEmpty
          ? null
          : set(json['tappableIndices']),
      solverSettings: solverSettings,
    );
  }
}

/// Shared controller so overlay mask and bottom panel stay in sync
class TutorialController extends ChangeNotifier {
  final List<TutorialStep> steps;
  int index;
  bool _isDone = false;

  TutorialController({required this.steps, this.index = 0});

  TutorialStep get current => steps[index];
  bool get hasPrev => index > 0;
  bool get hasNext => index < steps.length - 1;
  bool get isDone => _isDone;

  void next() {
    if (hasNext) {
      index++;
      notifyListeners();
    } else {
      _isDone = true;
      notifyListeners();
    }
  }

  void back() {
    if (hasPrev) {
      index--;
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

    if (controller == null || controller.isDone) {
      return SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final board = Provider.of<SudokuBoardState>(context, listen: false);
        final enterStep = controller.current;

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

        // Apply per-step solver settings (default to none if not provided)
        board.applyTutorialSolverSettings(
          enterStep.solverSettings ?? const SolverSettings(),
        );
        final maskBase = _stepForMask(controller.steps, controller.index);
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

    if (controller == null || controller.isDone) {
      return SizedBox.shrink();
    }

    bool center = controller.current.centerDialog;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: SafeArea(
          child: Align(
            alignment: center ? Alignment.center : Alignment.bottomCenter,
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
                        (step.advanceOnIndices == null ||
                            step.advanceOnIndices!.isEmpty);
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
                                      ? controller.back
                                      : null,
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                                const Spacer(),
                                if (controller.hasNext)
                                  IconButton.filled(
                                    tooltip: 'Next',
                                    onPressed: canGoNext
                                        ? controller.next
                                        : null,
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                    ),
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

// Determine the mask for the current step only (no merging from others).
TutorialStep _stepForMask(List<TutorialStep> steps, int index) {
  if (index < 0 || index >= steps.length) return steps.first;
  return steps[index];
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
        (step.tappableIndices != null && step.tappableIndices!.isNotEmpty) ||
        step.maskRows.isNotEmpty ||
        step.maskCols.isNotEmpty ||
        step.maskBoxes.isNotEmpty ||
        step.cells.isNotEmpty ||
        step.advanceOnValue != null;
    if (!hasAny) return false;

    final w = size.width / 9;
    final h = size.height / 9;
    final col = (pos.dx ~/ w).clamp(0, 8);
    final row = (pos.dy ~/ h).clamp(0, 8);
    final box = (row ~/ 3) * 3 + (col ~/ 3);
    final idx = row * 9 + col;

    // Compute base allowance from masks/units
    bool baseAllowed;
    if (step.maskIndices != null) {
      baseAllowed = step.maskIndices!.contains(idx);
    } else {
      baseAllowed =
          step.cells.contains(idx) ||
          step.maskRows.contains(row) ||
          step.maskCols.contains(col) ||
          step.maskBoxes.contains(box);
    }
    if (!baseAllowed) return false;

    // If a specific selection value is required, further restrict to cells
    // whose filled value matches that digit.
    if (step.advanceOnValue != null) {
      final required = step.advanceOnValue!;
      if (board.sudoku.isEmpty(idx) || board.sudoku.valueAt(idx) != required) {
        return false;
      }
    }

    // Further restrict with explicit tappable indices if provided.
    if (step.tappableIndices != null && !step.tappableIndices!.contains(idx)) {
      return false;
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
        // Auto-advance rules
        final idx = row * 9 + col;
        if (step.advanceOnIndices != null &&
            step.advanceOnIndices!.contains(idx)) {
          controller?.next();
          return;
        }
        if (step.advanceOnValue != null) {
          controller?.next();
          return;
        }
      },
    );
  }
}
