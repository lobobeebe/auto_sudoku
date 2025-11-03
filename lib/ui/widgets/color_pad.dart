import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';

class ColorPad extends StatelessWidget {
  const ColorPad({
    super.key,
    required this.maxWidth,
    required this.spacing,
    required this.board,
    required this.sudokuTheme,
    required this.colorScheme,
    required this.isEnabled,
  });

  final double maxWidth;
  final double spacing;
  final SudokuBoardState board;
  final SudokuTheme sudokuTheme;
  final ColorScheme colorScheme;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxWidth,
      child: Row(
        spacing: spacing,
        children: [
          _ColorSwatchButton(
            tooltip: 'Brush — Color A',
            color: sudokuTheme.coloringPrimary,
            checkColor: sudokuTheme.coloringPrimaryTextColor,
            isSelected: board.coloringBrush == ColoringBrush.colorA,
            onPressed: isEnabled
                ? () => board.setColoringBrush(ColoringBrush.colorA)
                : null,
          ),
          _ColorSwatchButton(
            tooltip: 'Brush — Color B',
            color: sudokuTheme.coloringSecondary,
            checkColor: sudokuTheme.coloringSecondaryTextColor,
            isSelected: board.coloringBrush == ColoringBrush.colorB,
            onPressed: isEnabled
                ? () => board.setColoringBrush(ColoringBrush.colorB)
                : null,
          ),
          Expanded(child: SizedBox()),
          _IconToolButton(
            tooltip: 'Brush — Eraser',
            background: colorScheme.surfaceContainerHighest,
            foreground: colorScheme.onSurfaceVariant,
            icon: Icons.backspace_outlined,
            isSelected: board.coloringBrush == ColoringBrush.eraser,
            onPressed: isEnabled
                ? () => board.setColoringBrush(ColoringBrush.eraser)
                : null,
          ),
          _IconToolButton(
            tooltip: 'Clear coloring marks',
            background: Colors.transparent,
            foreground: colorScheme.onSurfaceVariant,
            icon: Icons.clear_all,
            isSelected: false,
            onPressed: (isEnabled && board.hasColoringMarks)
                ? board.clearColoringMarks
                : null,
            outlineColor: colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  const _ColorSwatchButton({
    required this.tooltip,
    required this.color,
    required this.checkColor,
    required this.isSelected,
    required this.onPressed,
  });

  final String tooltip;
  final Color color;
  final Color checkColor;
  final bool isSelected;
  final VoidCallback? onPressed;

  static const _size = 52.0;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? Colors.black.withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.18);

    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 3 : 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: checkColor, size: 24)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconToolButton extends StatelessWidget {
  const _IconToolButton({
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
    this.outlineColor,
  });

  final String tooltip;
  final Color background;
  final Color foreground;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onPressed;
  final Color? outlineColor;

  static const _size = 52.0;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? foreground
        : (outlineColor ?? Colors.black.withValues(alpha: 0.18));

    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: background == Colors.transparent ? null : background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 2.4 : 1.5,
                ),
              ),
              child: Center(child: Icon(icon, color: foreground, size: 24)),
            ),
          ),
        ),
      ),
    );
  }
}
