import 'package:auto_sudoku/ui/widgets/cell_notes.dart';
import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:provider/provider.dart';

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sudokuTheme = SudokuTheme.of(context);
    final board = Provider.of<SudokuBoardState>(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: SudokuBoardState.size * SudokuBoardState.size,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: SudokuBoardState.size,
          ),
          itemBuilder: (context, index) {
            final row = index ~/ SudokuBoardState.size;
            final col = index % SudokuBoardState.size;
            final cell = board.cellAt(row, col);
            final isSelected = board.selectedIndex == index;
            final selectedRow = board.selectedRow;
            final selectedCol = board.selectedCol;
            final selectedValue = board.selectedValue;
            final isSameRow = selectedRow != null && selectedRow == row;
            final isSameCol = selectedCol != null && selectedCol == col;
            final isSameBox =
                selectedRow != null &&
                selectedCol != null &&
                (selectedRow ~/ 3 == row ~/ 3) &&
                (selectedCol ~/ 3 == col ~/ 3);
            final isPeer = !isSelected && (isSameRow || isSameCol || isSameBox);
            final matchesSelectedValue =
                !isSelected &&
                selectedValue != null &&
                cell.value != null &&
                cell.value == selectedValue;
            final isHighlighted = board.autoFillHighlightIndex == index;
            Color background = sudokuTheme.boardSurface;
            if (isPeer) {
              background = sudokuTheme.peerCellBackground;
            }
            if (matchesSelectedValue) {
              background = sudokuTheme.matchingValueBackground;
            }
            if (isSelected) {
              background = sudokuTheme.selectedCellBackground;
            }
            if (isHighlighted) {
              background = sudokuTheme.autoFillHighlightBackground;
            }

            final borderColor = colorScheme.outlineVariant;
            final border = Border(
              top: BorderSide(
                color: borderColor,
                width: row == 0 ? 2 : (row % 3 == 0 ? 1.5 : 0.5),
              ),
              left: BorderSide(
                color: borderColor,
                width: col == 0 ? 2 : (col % 3 == 0 ? 1.5 : 0.5),
              ),
              right: BorderSide(
                color: borderColor,
                width: col == SudokuBoardState.size - 1
                    ? 2
                    : ((col + 1) % 3 == 0 ? 1.5 : 0.5),
              ),
              bottom: BorderSide(
                color: borderColor,
                width: row == SudokuBoardState.size - 1
                    ? 2
                    : ((row + 1) % 3 == 0 ? 1.5 : 0.5),
              ),
            );

            return GestureDetector(
              onTap: board.isAnimatingSingles
                  ? null
                  : () => board.selectCell(row, col),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(color: background, border: border),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: SudokuCellContents(
                    index: index,
                    cell: cell,
                    isSelected: isSelected,
                    isHighlighted: isHighlighted,
                    selectedValue: selectedValue,
                    sudokuTheme: sudokuTheme,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SudokuCellContents extends StatelessWidget {
  final int index;
  final SudokuCell cell;
  final bool isSelected;
  final bool isHighlighted;
  final int? selectedValue;
  final SudokuTheme sudokuTheme;

  const SudokuCellContents({
    super.key,
    required this.index,
    required this.cell,
    required this.isSelected,
    required this.isHighlighted,
    required this.selectedValue,
    required this.sudokuTheme,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (cell.value != null) {
          final fontSize = constraints.maxHeight * 0.65;
          final bool useHighlightFont = isHighlighted;
          Color textColor;
          if (cell.isGiven) {
            textColor = sudokuTheme.givenCellTextColor;
          } else if (useHighlightFont || isSelected) {
            textColor = sudokuTheme.valueHighlightColor;
          } else {
            textColor = sudokuTheme.valueRegularTextColor;
          }
          return AnimatedScale(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutBack,
            scale: isHighlighted ? 1.12 : 1.0,
            child: Center(
              child: Text(
                '${cell.value}',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: (isSelected || useHighlightFont)
                      ? FontWeight.w900
                      : FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          );
        }

        if (cell.notes.isEmpty) {
          return const SizedBox.shrink();
        }

        return CellNotes(index: index, activeNotes: cell.notes);
      },
    );
  }
}
