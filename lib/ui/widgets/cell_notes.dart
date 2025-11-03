import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CellNotes extends StatelessWidget {
  final int index;
  final Set<int> activeNotes;
  final SudokuTheme sudokuTheme;
  const CellNotes({
    super.key,
    required this.index,
    required this.activeNotes,
    required this.sudokuTheme,
  });
  @override
  Widget build(BuildContext context) {
    final board = Provider.of<SudokuBoardState>(context);
    final digits = List<int>.generate(9, (index) => index + 1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 3;
        final cellHeight = constraints.maxHeight / 3;
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: List.generate(3, (row) {
            return SizedBox(
              height: cellHeight,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: List.generate(3, (col) {
                  final digit = digits[row * 3 + col];
                  return _CellNote(
                    index: index,
                    width: cellWidth,
                    height: cellHeight,
                    isActive: activeNotes.contains(digit),
                    state: board,
                    digit: digit,
                    sudokuTheme: sudokuTheme,
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}

class _CellNote extends StatelessWidget {
  final int index;
  final int? digit;
  final bool isActive;
  final SudokuBoardState state;
  final double width;
  final double height;
  final SudokuTheme sudokuTheme;
  const _CellNote({
    required this.index,
    required this.digit,
    required this.isActive,
    required this.state,
    required this.width,
    required this.height,
    required this.sudokuTheme,
  });
  @override
  Widget build(BuildContext context) {
    final board = Provider.of<SudokuBoardState>(context);
    final hint = board.hint;
    final isMatching =
        board.selectedValue != null && board.selectedValue == digit;
    final isElimination =
        hint != null && hint.eliminations.contains((index, digit));
    final isClue =
        hint != null &&
        hint.cells.contains(index) &&
        hint.digits.contains(digit);
    final isBig = isMatching || isElimination || isClue;
    final fontSize = height * (isBig ? .825 : .66);
    final fontWeight = isBig ? FontWeight.w700 : FontWeight.w500;
    final fontColor = isElimination
        ? sudokuTheme.noteEliminationTextColor
        : (isClue
              ? sudokuTheme.noteClueTextColor
              : (isMatching
                    ? sudokuTheme.noteHighlightTextColor
                    : sudokuTheme.noteDefaultColor));
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: isActive
            ? Text(
                "${digit ?? ""}",
                style: TextStyle(
                  fontSize: fontSize,
                  color: fontColor,
                  fontWeight: fontWeight,
                ),
              )
            : SizedBox.shrink(),
      ),
    );
  }
}
