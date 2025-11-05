import 'package:auto_sudoku/data/cell_view_model.dart';
import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CellNotesWidget extends StatelessWidget {
  final int index;
  final Set<int> activeNotes;
  final CellViewModel viewModel;

  const CellNotesWidget({
    super.key,
    required this.index,
    required this.activeNotes,
    required this.viewModel,
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
                  final index = row * 3 + col;
                  final digit = digits[index];
                  return _CellNote(
                    index: index,
                    width: cellWidth,
                    height: cellHeight,
                    isActive: activeNotes.contains(digit),
                    viewModel: viewModel.notes[index],
                    state: board,
                    digit: digit,
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
  final CellNoteViewModel viewModel;
  const _CellNote({
    required this.index,
    required this.digit,
    required this.isActive,
    required this.state,
    required this.width,
    required this.height,
    required this.viewModel,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: isActive
            ? Text(
                "${digit ?? ""}",
                style: TextStyle(
                  fontSize: (viewModel.scale ?? 1) * 10,
                  color: viewModel.textColor,
                  fontWeight: viewModel.fontWeight,
                  height: .5,
                ),
              )
            : SizedBox.expand(),
      ),
    );
  }
}
