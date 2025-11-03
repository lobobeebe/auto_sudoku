import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:auto_sudoku/ui/widgets/color_pad.dart';
import 'package:auto_sudoku/ui/utils/feedback.dart';
import 'package:provider/provider.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({super.key});

  @override
  Widget build(BuildContext context) {
    final sudokuTheme = SudokuTheme.of(context);
    final board = context.watch<SudokuBoardState>();
    final colorScheme = Theme.of(context).colorScheme;
    final digits = List.generate(9, (index) => index + 1);
    final isEnabled = !board.isAnimatingSingles && board.hint == null;

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const baseButtonWidth = 72.0;
        const baseSpacing = 8.0;
        const minScale = 0.4;
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 32;

        final baseTotalWidth =
            columns * baseButtonWidth + (columns - 1) * baseSpacing;
        final needsScaleDown = maxWidth.isFinite && maxWidth < baseTotalWidth;

        double scale = 1.0;
        double spacing = baseSpacing;
        double buttonWidth = baseButtonWidth;

        if (needsScaleDown) {
          scale = (maxWidth / baseTotalWidth).clamp(minScale, 1.0);
          spacing = baseSpacing * scale;
          final double adjustedWidth =
              (maxWidth - spacing * (columns - 1)) / columns;
          buttonWidth = adjustedWidth.clamp(36.0, baseButtonWidth);
        }

        final verticalPadding = 16.0 * scale.clamp(0.6, 1.0);
        final fontSize = 24.0 * scale.clamp(0.7, 1.0);

        if (board.coloringMode) {
          return ColorPad(
            maxWidth: maxWidth,
            spacing: spacing,
            board: board,
            sudokuTheme: sudokuTheme,
            colorScheme: colorScheme,
            isEnabled: isEnabled,
          );
        }

        return SizedBox(
          width: maxWidth,
          child: Row(
            spacing: spacing,
            children: digits
                .map(
                  (digit) => Flexible(
                    child: _PadButton(
                      label: '$digit',
                      width: buttonWidth,
                      verticalPadding: verticalPadding,
                      fontSize: fontSize,
                      isEnabled: isEnabled && board.canPlaceDigit(digit),
                      isComplete: board.isDigitSolved(digit),
                      sudokuTheme: sudokuTheme,
                      noteMode: board.noteMode,
                      onPressed: () => _handleDigit(context, digit),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  void _handleDigit(BuildContext context, int digit) {
    final board = context.read<SudokuBoardState>();
    if (board.selectedIndex == null) {
      showFeedback(context, 'Select a cell before entering numbers.');
      return;
    }
    final updated = board.enterDigit(digit);
    if (!updated) {
      showFeedback(context, 'Cannot update this cell right now.');
    }
  }
}

class _PadButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isEnabled;
  final bool isComplete;
  final SudokuTheme sudokuTheme;
  final bool noteMode;
  final double width;
  final double verticalPadding;
  final double fontSize;

  const _PadButton({
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
    required this.isComplete,
    required this.sudokuTheme,
    required this.noteMode,
    required this.width,
    required this.verticalPadding,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: FilledButton(
        onPressed: (isEnabled && !isComplete) ? onPressed : null,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding.clamp(8.0, 16.0),
          ),
          disabledBackgroundColor: isComplete ? Colors.transparent : null,
          backgroundColor: noteMode
              ? colorScheme.primary
              : sudokuTheme.numberPadBackground,
          foregroundColor: noteMode
              ? colorScheme.onPrimary
              : sudokuTheme.numberPadForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: sudokuTheme.numberPadTextStyle,
        ),
        child: Text(label, style: TextStyle(fontSize: fontSize)),
      ),
    );
  }
}
