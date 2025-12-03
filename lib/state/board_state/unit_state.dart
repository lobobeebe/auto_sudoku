import 'package:auto_sudoku/state/board_mode.dart';
import 'package:auto_sudoku/state/board_state/animating_state.dart';
import 'package:auto_sudoku/state/board_state/highlight_state.dart';
import 'package:auto_sudoku/state/board_state/hint_state.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

class UnitMode extends BoardMode {
  UnitMode(super.board);

  @override
  String get name => "Unit";

  @override
  void onRequestSelectCell(int row, int col) {
    final index = board.getIndex(row, col);

    if (!board.sudoku.isEmpty(index)) {
      board.selectedIndices.clear();
      board.selectedIndices.add(index);
      board.setMode(HighlightMode(board));
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
    final solver = board.getUnitSolver();
    final hint = solver.getHintByClues(board.sudoku, board.selectedIndices);

    if (hint == null) {
      return;
    }

    final snapshot = board.makeSnapshot();
    final applied = board.applyHintToBoard(hint);

    if (!applied) {
      return;
    }

    // Toast the technique name when a hint is applied automatically
    board.showHintToastIfPossible(hint.strategy.toString());

    board.pushSnapshot(snapshot: snapshot);

    board.selectedIndices.clear();

    final result = board.evaluateResult();
    if (result != null) {
      board.setMode(CompleteMode(board, result, this));
      return;
    }

    if (board.canAutoFinish()) {
      board.setMode(AnimatingMode(board, this));
      return;
    }
  }

  @override
  void onRequestSetHint(Hint hint) {
    board.setMode(HintMode(board, hint, this));
  }
}
