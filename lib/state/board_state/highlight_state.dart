import 'package:auto_sudoku/data/cell_view_model.dart';
import 'package:auto_sudoku/state/board_mode.dart';
import 'package:auto_sudoku/state/board_state/hint_state.dart';
import 'package:auto_sudoku/state/sudoku_board_state.dart';
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

    final cell = board.getCellAtIndex(newIndex);
    if (cell == null) {
      return;
    }

    board.selectedIndices.clear();
    board.selectedIndices.add(newIndex);

    if (cell.value == null) {
      board.setMode(lastMode);
    } else {
      board.emitChange();
    }
  }

  @override
  CellViewModel buildCellViewModel(int index, SudokuTheme theme) {
    SudokuCell cell = board.getCellAtIndex(index)!;
    bool isSelected = board.isIndexSelected(index);
    bool isPeer = board.isPeerWithAnySelected(index);
    bool isMatching = board.matchesAnySelected(index);

    Color bg = theme.boardSurface;
    if (isSelected) {
      bg = theme.selectedCellBackground;
    } else if (isPeer) {
      bg = theme.peerCellBackground;
    } else if (isMatching) {
      bg = theme.matchingValueBackground;
    }

    Color valueTextColor = cell.isGiven
        ? theme.givenCellTextColor
        : (isSelected
              ? theme.valueHighlightColor
              : theme.valueRegularTextColor);

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
