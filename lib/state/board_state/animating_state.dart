import 'dart:async';

import 'package:auto_sudoku/state/board_mode.dart';

/// Animating: auto-singles animation is running; block user interactions.
class AnimatingMode extends BoardMode {
  final BoardMode nextMode;

  final Duration _autoFillStepDelay = const Duration(milliseconds: 160);

  int? _autoFillHighlightIndex;

  AnimatingMode(super.board, this.nextMode);
  @override
  String get name => 'Animating';

  @override
  void onEnter() {
    board.selectedIndices.clear();
    board.emitChange();

    unawaited(_runSingles());
  }

  Future<void> _runSingles() async {
    var nextSingle = board.nextSingle();
    while (nextSingle != null) {
      var elimination = nextSingle.eliminations.keys.firstOrNull;
      var index = elimination;

      _autoFillHighlightIndex = index;

      var mutated = board.applyHintToBoard(nextSingle);
      if (mutated) {
        board.emitChange();
      }

      // Wait for animation
      await Future.delayed(_autoFillStepDelay);

      // Find the next single to repeat animation
      nextSingle = board.nextSingle();
    }

    final result = board.evaluateResult();

    // Keep playing or complete
    if (result == null) {
      board.setMode(nextMode);
    } else {
      board.setMode(CompleteMode(board, result, nextMode));
    }
  }

  @override
  bool allowReset() => false;

  @override
  bool allowUndo() => false;

  @override
  bool allowRequestHint() => false;

  @override
  bool allowControls() => false;
}
