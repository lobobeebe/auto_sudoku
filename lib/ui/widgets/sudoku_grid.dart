import 'package:auto_sudoku/data/cell_view_model.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:auto_sudoku/ui/widgets/cell_notes_widget.dart';
import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:provider/provider.dart';

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final board = Provider.of<SudokuBoardState>(context);
    final theme = SudokuTheme.of(context);

    return Center(
      child: AspectRatio(
        aspectRatio: 1, // enforce a perfect square
        child: DecoratedBox(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final grid = SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
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
                    final cell = board.getCellAt(row, col);

                    CellViewModel cellVM = board.buildCellViewModel(
                      index,
                      theme,
                    );

                    final background = cellVM.backgroundColor;

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
                      onTap: () => board.requestSelectCell(row, col),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: background,
                          border: border,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: cell != null
                              ? SudokuCellContents(
                                  index: index,
                                  cell: cell,
                                  viewModel: cellVM,
                                )
                              : SizedBox(),
                        ),
                      ),
                    );
                  },
                ),
              );

              return grid;
            },
          ),
        ),
      ),
    );
  }
}

class SudokuCellContents extends StatelessWidget {
  final int index;
  final SudokuCell cell;
  final CellViewModel viewModel;

  const SudokuCellContents({
    super.key,
    required this.index,
    required this.cell,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (cell.value != null) {
          final fontSize = constraints.maxHeight * 0.65;
          return AnimatedScale(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutBack,
            scale: viewModel.valueScale ?? 1,
            child: Center(
              child: Text(
                '${cell.value}',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: viewModel.valueFontWeight,
                  color: viewModel.valueTextColor,
                ),
              ),
            ),
          );
        }

        if (cell.notes.isEmpty) {
          return const SizedBox.shrink();
        }

        return CellNotesWidget(
          index: index,
          activeNotes: cell.notes,
          viewModel: viewModel,
        );
      },
    );
  }
}
