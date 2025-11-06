import 'package:auto_sudoku/state/board_mode.dart';
import 'package:auto_sudoku/state/board_state/animating_state.dart';
import 'package:auto_sudoku/state/board_state/highlight_state.dart';
import 'package:auto_sudoku/state/board_state/hint_state.dart';
import 'package:auto_sudoku/ui/widgets/strategy_category_popup_menu.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';

class UnitMode extends BoardMode {
  final Map<StrategyCategory, Solver> _categorySolverMap = {
    StrategyCategory.nakedHidden: Solver(
      settings: SolverSettings(
        allowed: {
          StrategyType.nakedSingle,
          StrategyType.nakedPair,
          StrategyType.nakedTriple,
          StrategyType.nakedQuad,
          StrategyType.hiddenSingle,
          StrategyType.hiddenPair,
          StrategyType.hiddenTriple,
          StrategyType.hiddenQuad,
        },
      ),
    ),
    StrategyCategory.locked: Solver(
      settings: SolverSettings(
        allowed: {StrategyType.pointing, StrategyType.claiming},
      ),
    ),
    StrategyCategory.wings: Solver(
      settings: SolverSettings(
        allowed: {StrategyType.xWing, StrategyType.xyWing},
      ),
    ),
  };

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
    final cell = board.getCellAtIndex(index);
    if (cell == null) return;

    if (cell.value != null) {
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
    final solver = _categorySolverMap[board.strategyCategory];

    if (solver == null) {
      debugPrintStack(label: "No solver for ${board.strategyCategory}");
      return;
    }

    final hint = solver.getHintByClues(
      Sudoku(board.toValueList(), notes: board.toNotesList()),
      board.selectedIndices,
    );

    if (hint == null) {
      return;
    }

    final snapshot = board.makeSnapshot();
    final applied = board.applyHintToBoard(hint);

    if (!applied) {
      return;
    }

    board.pushSnapshot(snapshot: snapshot);
    board.selectedIndices.clear();
    board.strategyCategory = StrategyCategory.nakedHidden;

    final result = board.evaluateResult();
    if (result != null) {
      board.setMode(CompleteMode(board, result, this));
      return;
    }

    if (board.canWinBySingles()) {
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
