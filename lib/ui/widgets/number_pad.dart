import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:auto_sudoku/ui/widgets/color_pad.dart';
import 'package:auto_sudoku/ui/widgets/pad_button.dart';
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

        final linksCandidateDigits = board.linksMode
            ? board.digitsAvailableForLinks()
            : null;

        return SizedBox(
          width: maxWidth,
          child: Row(
            spacing: spacing,
            children: digits.map((digit) {
              final isComplete = board.isDigitSolved(digit);
              final isLinkSelected =
                  board.linksMode && board.linksDigit == digit;
              final hasCandidates =
                  linksCandidateDigits?.contains(digit) ?? false;
              final buttonEnabled = board.linksMode
                  ? isEnabled && !isComplete && hasCandidates
                  : isEnabled && !isComplete && board.canPlaceDigit(digit);
              final background = board.linksMode
                  ? (isComplete || !hasCandidates
                        ? Colors.transparent
                        : (isLinkSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest))
                  : (board.noteMode
                        ? colorScheme.primary
                        : sudokuTheme.numberPadBackground);
              final foreground = board.linksMode
                  ? (isLinkSelected
                        ? colorScheme.onPrimary
                        : (hasCandidates
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface.withValues(alpha: 0.38)))
                  : (board.noteMode
                        ? colorScheme.onPrimary
                        : sudokuTheme.numberPadForeground);
              final disabledBackground = board.linksMode
                  ? Colors.transparent
                  : (isComplete ? Colors.transparent : null);
              final padding = EdgeInsets.symmetric(
                vertical: verticalPadding.clamp(8.0, 16.0),
              );

              return Flexible(
                child: PadButton(
                  label: '$digit',
                  width: buttonWidth,
                  padding: padding,
                  background: background,
                  foreground: foreground,
                  disabledBackground: disabledBackground,
                  textStyle: sudokuTheme.numberPadTextStyle.copyWith(
                    fontSize: fontSize,
                  ),
                  isEnabled: buttonEnabled,
                  onPressed: () => board.linksMode
                      ? board.setLinksDigit(digit)
                      : _handleDigit(context, digit),
                ),
              );
            }).toList(),
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
