import 'package:auto_sudoku/state/board_mode.dart';
import 'package:auto_sudoku/state/board_state/animating_state.dart';
import 'package:auto_sudoku/state/board_state/highlight_state.dart';
import 'package:auto_sudoku/state/board_state/hint_state.dart';
import 'package:auto_sudoku/ui/widgets/strategy_category_popup_menu.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';

class UnitMode extends BoardMode {
  UnitMode(super.board);

  @override
  String get name => "Unit";

  @override
  void onEnter() {
    _trySolve();
  }

  @override
  void onRequestSelectCell(int row, int col) {
    final index = board.getIndex(row, col);

    if (!board.sudoku.isEmpty(index)) {
      board.selectedIndices.clear();
      board.selectedIndices.add(index);
      board.setMode(HighlightMode(board, this));
      return;
    }

    if (board.selectedIndices.contains(index)) {
      board.selectedIndices.remove(index);
    } else {
      board.selectedIndices.add(index);
    }

    _trySolve();

    board.emitChange();
  }

  void _trySolve() {
    final solver = board.getUnitSolverForCategory(board.strategyCategory);
    final hint = solver.getHintByClues(board.sudoku, board.selectedIndices);

    if (hint == null) {
      return;
    }

    final snapshot = board.makeSnapshot();
    final applied = board.applyHintToBoard(hint);

    if (!applied) {
      return;
    }

    board.pushSnapshot(snapshot: snapshot);
    board.strategyCategory = StrategyCategory.nakedHidden;

    final lastSelectedIndex = board.selectedIndices.lastOrNull;
    board.selectedIndices.clear();
    if (lastSelectedIndex != null && !board.sudoku.isEmpty(lastSelectedIndex)) {
      board.selectedIndices.add(lastSelectedIndex);
      board.setMode(HighlightMode(board, this));
      return;
    }

    final result = board.evaluateResult();
    if (result != null) {
      board.setMode(CompleteMode(board, result, this));
      return;
    }

    if (board.autoFinish && board.canWinBySingles()) {
      board.setMode(AnimatingMode(board, this));
    }
  }

  @override
  void onRequestSetHint(Hint hint) {
    board.setMode(HintMode(board, hint, this));
  }

  @override
  void onRequestStrategyCategory(StrategyCategory category) {
    board.strategyCategory = category;

    _trySolve();

    board.emitChange();
  }
}
