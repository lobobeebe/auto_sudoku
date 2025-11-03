import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:auto_sudoku/ui/utils/feedback.dart';
import 'package:provider/provider.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({super.key});

  @override
  Widget build(BuildContext context) {
    final sudokuTheme = SudokuTheme.of(context);
    final board = context.watch<SudokuBoardState>();
    final digits = List.generate(9, (index) => index + 1);
    final isEnabled = !board.isAnimatingSingles && board.hint == null;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        const columns = 3;
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 32;
        final availableWidth = maxWidth - spacing * (columns - 1);
        final computedWidth = availableWidth / columns;
        final buttonWidth = computedWidth < 72.0
            ? (computedWidth > 0 ? computedWidth : 72.0)
            : 72.0;

        return SizedBox(
          width: maxWidth,
          child: Wrap(
            spacing: spacing,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: digits
                .map(
                  (digit) => _PadButton(
                    label: '$digit',
                    width: buttonWidth,
                    isEnabled: isEnabled && board.canPlaceDigit(digit),
                    isComplete: board.isDigitSolved(digit),
                    sudokuTheme: sudokuTheme,
                    noteMode: board.noteMode,
                    onPressed: () => _handleDigit(context, digit),
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

  const _PadButton({
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
    required this.isComplete,
    required this.sudokuTheme,
    required this.noteMode,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: FilledButton(
        onPressed: (isEnabled && !isComplete) ? onPressed : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
        child: Text(label, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
