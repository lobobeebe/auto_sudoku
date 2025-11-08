import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TutorialStep {
  final Set<int> rows;
  final Set<int> cols;
  final Set<int> boxes;
  final Set<int> cells; // indices 0..80
  final String title;
  final String body;

  const TutorialStep({
    this.rows = const {},
    this.cols = const {},
    this.boxes = const {},
    this.cells = const {},
    required this.title,
    required this.body,
  });

  bool get hasAnyAllow =>
      rows.isNotEmpty ||
      cols.isNotEmpty ||
      boxes.isNotEmpty ||
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
class GridMaskOverlay extends StatelessWidget {
  final TutorialController controller;
  const GridMaskOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Determine which areas should be allowed for this step.
        final step = _stepForMask(controller.steps, controller.index);
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final grid = _gridRect(size);
            final allowedRects = _computeVisualRects(grid, step);
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _OverlayPainter(allowed: allowedRects, grid: grid)),
                _TouchShield(gridRect: grid, step: step),
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
                    TextButton(
                      onPressed: controller.onDone,
                      child: const Text('Skip'),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      tooltip: 'Back',
                      onPressed: controller.hasPrev ? controller.back : null,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    if (controller.hasNext)
                      IconButton.filled(
                        tooltip: 'Next',
                        onPressed: controller.next,
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
    final colors = Theme.of(context).colorScheme;
    final displayStep = widget.steps[_index];
    final maskStep = _stepForMask(widget.steps, _index);

    return LayoutBuilder(
      builder: (context, constraints) {
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
            CustomPaint(painter: _OverlayPainter(allowed: allowedRects, grid: grid)),

            // Capture touches and forward only inside allowed
            _TouchShield(gridRect: grid, step: maskStep),

            // Small dialog
            Align(
              alignment: alignment,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: grid.width * 0.58),
                child: Card(
                  elevation: 8,
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
                          displayStep.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayStep.body,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton(
                              onPressed: widget.onDone,
                              child: const Text('Skip'),
                            ),
                            const Spacer(),
                            IconButton.filledTonal(
                              tooltip: 'Back',
                              onPressed: _index == 0 ? null : _back,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: 8),
                            if (_index < widget.steps.length - 1)
                              IconButton.filled(
                                tooltip: 'Next',
                                onPressed: _next,
                                icon: const Icon(Icons.arrow_forward_rounded),
                              )
                            else
                              FilledButton.icon(
                                onPressed: _next,
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Done'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
  for (final r in step.rows) {
    if (r < 0 || r > 8) continue;
    final base = Rect.fromLTWH(grid.left, grid.top + r * h, grid.width, h);
    final rr = _inflateAndClampRRect(base, borderRadius, pad, grid.size, grid);
    rects.add(rr);
  }
  // Cols
  for (final c in step.cols) {
    if (c < 0 || c > 8) continue;
    final base = Rect.fromLTWH(grid.left + c * w, grid.top, w, grid.height);
    final rr = _inflateAndClampRRect(base, borderRadius, pad, grid.size, grid);
    rects.add(rr);
  }
  // Boxes
  for (final b in step.boxes) {
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

// Returns the current step if it has allows; otherwise merges allows from
// subsequent steps to enable multiple units for introductory pages.
TutorialStep _stepForMask(List<TutorialStep> steps, int index) {
  if (index < 0 || index >= steps.length) return steps.first;
  final cur = steps[index];
  if (cur.hasAnyAllow) return cur;

  final rows = <int>{};
  final cols = <int>{};
  final boxes = <int>{};
  final cells = <int>{};
  for (int i = index + 1; i < steps.length; i++) {
    rows.addAll(steps[i].rows);
    cols.addAll(steps[i].cols);
    boxes.addAll(steps[i].boxes);
    cells.addAll(steps[i].cells);
  }
  if (rows.isEmpty && cols.isEmpty && boxes.isEmpty && cells.isEmpty) {
    return cur; // nothing to merge; keep as-is
  }
  return TutorialStep(
    rows: rows,
    cols: cols,
    boxes: boxes,
    cells: cells,
    title: cur.title,
    body: cur.body,
  );
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
    final scrim = Paint()..color = Colors.black.withOpacity(0.5);
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
  const _TouchShield({required this.gridRect, required this.step});

  bool _hitAllowed(Offset pos, Size size) {
    // No targets -> block
    final hasAny =
        step.rows.isNotEmpty ||
        step.cols.isNotEmpty ||
        step.boxes.isNotEmpty ||
        step.cells.isNotEmpty;
    if (!hasAny) return false;

    final w = size.width / 9;
    final h = size.height / 9;
    final col = (pos.dx ~/ w).clamp(0, 8);
    final row = (pos.dy ~/ h).clamp(0, 8);
    final box = (row ~/ 3) * 3 + (col ~/ 3);
    final idx = row * 9 + col;

    if (step.cells.contains(idx)) return true;
    if (step.rows.contains(row)) return true;
    if (step.cols.contains(col)) return true;
    if (step.boxes.contains(box)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final board = Provider.of<SudokuBoardState>(context, listen: false);
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
      },
    );
  }
}
