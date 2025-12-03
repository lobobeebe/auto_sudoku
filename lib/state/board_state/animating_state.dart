import 'dart:async';

import 'package:auto_sudoku/data/cell_view_model.dart';
import 'package:auto_sudoku/state/board_mode.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:flutter/material.dart';

/// Animating: auto-singles animation is running; block user interactions.
class AnimatingMode extends BoardMode {
  final BoardMode nextMode;
  int? _animatingIndex;

  final Duration _autoFillStepDelay = const Duration(milliseconds: 120);

  AnimatingMode(super.board, this.nextMode);
  @override
  String get name => 'Animating';

  @override
  void onEnter() {
    board.selectedIndices.clear();
    board.emitChange();

    unawaited(_run());
  }

  Future<void> _run() async {
    // Custom auto-solver animation with provided strategies
    while (true) {
      final hint = board.nextAutoMove();
      if (hint == null) break;
      _animatingIndex = hint.placements.keys.firstOrNull;
      final mutated = board.applyHintToBoard(hint);
      if (!mutated) break;
      board.emitChange();
      await Future.delayed(_autoFillStepDelay);
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

  @override
  CellViewModel buildCellViewModel(int index, SudokuTheme theme) {
    bool isSelected = _animatingIndex == index;

    Color bg = isSelected ? theme.selectedCellBackground : theme.boardSurface;

    Color valueTextColor = (isSelected
        ? theme.valueHighlightColor
        : theme.valueRegularTextColor);

    final notes = List.generate(9, (digit) {
      return CellNoteViewModel();
    });

    return CellViewModel(
      backgroundColor: bg,
      valueTextColor: valueTextColor,
      notes: notes,
    );
  }
}
