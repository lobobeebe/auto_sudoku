import 'package:auto_sudoku/data/sudoku_model.dart';
import 'package:auto_sudoku/state/board_mode.dart';
import 'package:auto_sudoku/state/board_state/animating_state.dart';
import 'package:auto_sudoku/state/board_state/error_state.dart';
import 'package:auto_sudoku/state/board_state/unit_state.dart';
import 'package:flutter/material.dart';

class LoadingMode extends BoardMode {
  @override
  String get name => "Loading";

  LoadingMode(super.board);

  @override
  void onRequestInitPuzzle(SudokuModel? puzzle, String? error) {
    if (puzzle != null && error == null) {
      board.initPuzzle(puzzle);
      if (board.shouldAnimate) {
        board.setMode(AnimatingMode(board, UnitMode(board)));
      } else {
        board.setMode(UnitMode(board));
      }
      return;
    }

    board.setMode(ErrorMode(board, error));
  }

  @override
  bool allowReset() => false;

  @override
  bool allowUndo() => false;

  @override
  bool allowRequestHint() => false;

  @override
  bool allowControls() => false;

  @override
  Widget? buildBodyOverride(BuildContext context) => const Center(
    key: ValueKey('loading'),
    child: CircularProgressIndicator.adaptive(),
  );
}
