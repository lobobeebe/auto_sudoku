import 'package:auto_sudoku/data/cell_view_model.dart';
import 'package:auto_sudoku/state/board_mode.dart';
import 'package:auto_sudoku/state/board_state/animating_state.dart';
import 'package:auto_sudoku/state/board_state/hint_state.dart';
import 'package:auto_sudoku/state/board_state/unit_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';

class HighlightMode extends BoardMode {
  HighlightMode(super.board);
  @override
  String get name => 'Highlight';

  @override
  void onRequestSelectCell(int row, int col) {
    final oldIndex = board.selectedIndices.firstOrNull;
    final newIndex = board.getIndex(row, col);

    board.selectedIndices.clear();

    // Same cell selected - just unselect and move out of the highlight mode.
    if (oldIndex == newIndex) {
      board.setMode(UnitMode(board));
      return;
    }

    // New Cell selected
    board.selectedIndices.add(newIndex);

    // If new cell is empty, attempt to solve a hidden single to stay in Highlight mode.
    if (board.sudoku.isEmpty(newIndex)) {
      if (!_trySolveEmpty()) // Attempt to solve a hidden single
      {
        // Enter Unit Mode
        board.setMode(UnitMode(board));
        return;
      }
    }

    board.emitChange(); // Notify the selection
  }

  bool _trySolveEmpty() {
    final solver = board.getUnitSolver();
    final hint = solver.getHintByClues(board.sudoku, board.selectedIndices);

    if (hint == null) {
      return false;
    }

    final snapshot = board.makeSnapshot();
    final applied = board.applyHintToBoard(hint);

    if (!applied) {
      return false;
    }

    // Toast the technique name when a hint is applied automatically
    board.showHintToastIfPossible(hint.strategy.toString());

    board.pushSnapshot(snapshot: snapshot);

    final result = board.evaluateResult();
    if (result != null) {
      board.setMode(CompleteMode(board, result, this));
      return true;
    }

    if (board.nextAutoMove() != null) {
      board.setMode(AnimatingMode(board, this));
      return true;
    }

    return true;
  }

  @override
  CellViewModel buildCellViewModel(int index, SudokuTheme theme) {
    bool isSelected = board.isIndexSelected(index);
    bool isMatching = board.matchesAnySelected(index);
    bool isEmpty = board.sudoku.isEmpty(index);
    bool hasSelectedNote = board.selectedValues.any(
      (selected) => board.sudoku.hasNote(index, selected),
    );

    Color bg = theme.boardSurface;
    if (isSelected) {
      bg = theme.selectedCellBackground;
    } else if (isMatching) {
      bg = theme.matchingValueBackground;
    } else if (!hasSelectedNote || !isEmpty) {
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
