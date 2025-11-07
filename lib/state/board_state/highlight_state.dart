import 'package:auto_sudoku/data/cell_view_model.dart';
import 'package:auto_sudoku/state/board_mode.dart';
import 'package:auto_sudoku/state/board_state/hint_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';

class HighlightMode extends BoardMode {
  final BoardMode lastMode;
  HighlightMode(super.board, this.lastMode);
  @override
  String get name => 'Highlight';

  @override
  void onRequestSelectCell(int row, int col) {
    final newIndex = board.getIndex(row, col);

    board.selectedIndices.clear();
    board.selectedIndices.add(newIndex);

    if (board.sudoku.isEmpty(newIndex)) {
      board.setMode(lastMode);
    } else {
      board.emitChange();
    }
  }

  @override
  CellViewModel buildCellViewModel(int index, SudokuTheme theme) {
    bool isSelected = board.isIndexSelected(index);
    bool isPeer = board.isPeersWithAnyMatching(index);
    bool isMatching = board.matchesAnySelected(index);
    bool isEmpty = board.sudoku.isEmpty(index);

    Color bg = theme.boardSurface;
    if (isSelected) {
      bg = theme.selectedCellBackground;
    } else if (isMatching) {
      bg = theme.matchingValueBackground;
    } else if (isPeer || !isEmpty) {
      bg = theme.peerCellBackground;
    }

    Color valueTextColor = isSelected
        ? theme.valueHighlightColor
        : theme.valueRegularTextColor;

    final notes = List.generate(9, (digit) {
      bool digitSelected = board.selectedValues.contains(digit + 1);

      return CellNoteViewModel(
        scale: digitSelected ? 1.25 : 1,
        fontWeight: digitSelected ? FontWeight.w600 : null,
      );
    });

    return CellViewModel(
      backgroundColor: bg,
      valueTextColor: valueTextColor,
      notes: notes,
    );
  }

  @override
  void onRequestSetHint(Hint hint) {
    board.setMode(HintMode(board, hint, this));
  }
}
