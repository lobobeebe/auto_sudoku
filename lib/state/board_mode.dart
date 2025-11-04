// --- Board State Machine ----------------------------------------------------

import 'dart:async';

import 'package:auto_sudoku/data/sudoku_puzzle_model.dart';
import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/highlighters/grid_highlighter.dart';
import 'package:auto_sudoku/ui/utils/utils.dart';
import 'package:auto_sudoku/ui/widgets/common_container.dart';
import 'package:auto_sudoku/ui/widgets/control_bar.dart';
import 'package:auto_sudoku/ui/widgets/error_panel.dart';
import 'package:auto_sudoku/ui/widgets/hint_steps_panel.dart';
import 'package:auto_sudoku/ui/widgets/interactive_strategy_card.dart';
import 'package:auto_sudoku/ui/widgets/result_dialog.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';

abstract class BoardMode {
  static const GridHighlighter defaultHighlighter = DefaultHighlighter();
  final SudokuBoardState board;
  const BoardMode(this.board);

  String get name;

  /// When this mode becomes active.
  void onEnter() {}

  /// When this mode is replaced.
  void onExit() {}

  // Interaction hooks (override as needed)
  void onRequestInitPuzzle(SudokuPuzzleModel? puzzle, String? error) {}
  void onRequestClearHint() {}
  void onRequestSetHint(Hint hint) {}
  bool onRequestApplyCurrentHint() => false;
  bool onRequestEnterDigit(int digit) => false;
  void onRequestSelectCell(int row, int col) {}
  void onRequestInteractive(Set<StrategyType> types) {}
  void onRequestCancelInteractive() {}
  void onRequestNoteMode() {}
  void onRequestUndo() {
    if (allowUndo()) board.undo();
  }

  // UI allowances
  bool allowReset() => true;
  Widget? buildBodyOverride(BuildContext context) => null;
  void onFirstBuild(BuildContext context) {}
  bool allowUndo() => true;
  bool allowRequestHint() => true;
  bool allowControls() => true;
  bool canPressDigit(int digit) => false;

  bool isNoteMode() => false;

  Widget buildBottomBar() =>
      CommonContainer(key: const ValueKey("controls"), child: ControlBar());

  GridHighlighter getGridHighlighter() => defaultHighlighter;
}

class ErrorMode extends BoardMode {
  final String? error;
  const ErrorMode(super.board, this.error);

  @override
  String get name => "Error";

  @override
  Widget? buildBodyOverride(BuildContext context) => ErrorPanel(
    key: const ValueKey('error'),
    message: error ?? "Unknown Error",
    onReturn: () => Navigator.pop(context),
  );

  @override
  bool allowUndo() => false;

  @override
  bool allowRequestHint() => false;

  @override
  bool allowControls() => false;
}

class LoadingMode extends BoardMode {
  @override
  String get name => "Loading";

  LoadingMode(super.board);

  @override
  void onRequestInitPuzzle(SudokuPuzzleModel? puzzle, String? error) {
    if (puzzle != null && error == null) {
      board.initPuzzle(puzzle);
      board.setMode(AnimatingMode(board, DefaultMode(board)));
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

class NoteMode extends BoardMode {
  NoteMode(super.board);

  int? get _selectedIndex => board.selectedIndices.lastOrNull;
  set _selectedIndex(int? idx) {
    final oldIndex = _selectedIndex;
    board.selectedIndices.clear();

    if (idx != null && oldIndex != idx) {
      board.selectedIndices.add(idx);
    }
  }

  @override
  String get name => "Notes";

  @override
  bool onRequestEnterDigit(int digit) {
    final idx = _selectedIndex;
    if (idx == null || digit < 1 || digit > 9) {
      return false;
    }
    final cell = board.getCellAtIndex(idx);

    if (cell == null || cell.isGiven) {
      return false;
    }

    board.pushSnapshot();

    if (cell.value != null) {
      return false;
    }

    // Make update to clone
    final updatedNotes = {...cell.notes};
    if (updatedNotes.contains(digit)) {
      updatedNotes.remove(digit);
    } else {
      updatedNotes.add(digit);
    }

    // If no change, skip
    final wasChanged = !SudokuUtils.notesEqual(updatedNotes, cell.notes);
    if (!wasChanged) {
      return false;
    }

    // Push snapshot for undo
    board.pushSnapshot();

    // Apply Note clone to Cell
    board.setCellAtIndex(idx, cell.withNotes(updatedNotes));

    board.emitChange();

    // If singles are now present in the board, transition to Animating
    if (board.nextSingle() != null) {
      board.setMode(AnimatingMode(board, this));
    }
    return true;
  }

  @override
  bool isNoteMode() => true;

  @override
  bool canPressDigit(int digit) {
    final idx = _selectedIndex;
    if (idx == null || digit < 1 || digit > 9) {
      return false;
    }

    final cell = board.getCellAtIndex(idx);

    if (cell == null || cell.isGiven) {
      return false;
    }

    return cell.value == null;
  }

  @override
  void onRequestSelectCell(int row, int col) {
    final newIndex = board.getIndex(row, col);
    _selectedIndex = newIndex;
    board.emitChange();
  }

  @override
  void onRequestNoteMode() {
    board.setMode(DefaultMode(board));
  }

  @override
  void onRequestSetHint(Hint hint) {
    board.setMode(HintMode(board, hint));
  }
}

/// Default: normal play – single selection, placements, notes, etc.
class DefaultMode extends BoardMode {
  DefaultMode(super.board);
  @override
  String get name => 'Default';

  int? get _selectedIndex => board.selectedIndices.lastOrNull;
  set _selectedIndex(int? idx) {
    final oldIndex = _selectedIndex;
    board.selectedIndices.clear();

    if (idx != null && oldIndex != idx) {
      board.selectedIndices.add(idx);
    }
  }

  @override
  void onEnter() {
    // Reduce selected indices down to one
    if (board.selectedIndices.length > 1) {
      final idx = board.selectedIndices.last;
      board.selectedIndices.clear();
      board.selectedIndices.add(idx);
      board.emitChange();
    }
  }

  @override
  void onRequestSelectCell(int row, int col) {
    final newIndex = board.getIndex(row, col);
    _selectedIndex = newIndex;
    board.emitChange();
  }

  @override
  bool onRequestEnterDigit(int digit) {
    final idx = _selectedIndex;
    if (idx == null || digit < 1 || digit > 9) {
      return false;
    }
    final cell = board.getCellAtIndex(idx);

    if (cell == null || cell.isGiven) {
      return false;
    }

    // Push snapshot for undo point
    board.pushSnapshot();

    // Set cell
    board.setCellAtIndex(idx, cell.withValue(digit));

    // Evaluate completion
    final result = board.evaluateResult();
    if (result != null) {
      board.setMode(CompleteMode(board, result));
      return true;
    }

    // Remove the notes in conflict with this change.
    board.pruneNotesAround(idx, digit);

    // If there are singles to remove, transition to animating
    if (board.nextSingle() != null) {
      board.setMode(AnimatingMode(board, this));
      return true;
    }

    board.emitChange();

    return true;
  }

  @override
  void onRequestInteractive(Set<StrategyType> types) {
    board.setMode(InteractiveMode(board, types));
  }

  @override
  void onRequestNoteMode() {
    board.setMode(NoteMode(board));
  }

  @override
  void onRequestSetHint(Hint hint) {
    board.setMode(HintMode(board, hint));
  }

  @override
  bool canPressDigit(int digit) {
    final idx = _selectedIndex;
    if (idx == null || digit < 1 || digit > 9) {
      return false;
    }

    return board.canPlaceDigit(idx, digit);
  }
}

class HintMode extends BoardMode {
  final Hint hint;
  HintMode(super.board, this.hint);

  @override
  String get name => "Hint";

  @override
  bool onRequestApplyCurrentHint() {
    final snapshot = board.makeSnapshot();
    final mutated = board.applyHintToBoard(hint);
    if (mutated) {
      board.pushSnapshot(snapshot: snapshot);
    }

    board.setMode(AnimatingMode(board, DefaultMode(board)));
    return mutated;
  }

  @override
  void onRequestClearHint() {
    board.setMode(DefaultMode(board));
  }

  @override
  bool allowRequestHint() => false;

  @override
  Widget buildBottomBar() => CommonContainer(
    key: const ValueKey('hintPanel'),
    child: HintStepsPanel(hint: hint),
  );
}

/// Interactive: user is selecting multiple cells to request a technique hint.
class InteractiveMode extends BoardMode {
  final Set<StrategyType> _types;
  final Solver _solver;

  InteractiveMode(super.board, this._types)
    : _solver = Solver(settings: SolverSettings(allowed: _types));

  @override
  String get name => 'Interactive';

  @override
  void onEnter() {
    board.selectedIndices.clear();
  }

  @override
  void onExit() {
    board.selectedIndices.clear();
  }

  @override
  void onRequestSelectCell(int row, int col) {
    final index = board.getIndex(row, col);
    final cell = board.getCellAtIndex(index);
    if (cell == null || cell.isGiven || cell.value != null) return;

    if (board.selectedIndices.contains(index)) {
      board.selectedIndices.remove(index);
    } else {
      board.selectedIndices.add(index);
    }

    final hint = _solver.getHintByClues(
      Sudoku(board.toValueList(), notes: board.toNotesList()),
      board.selectedIndices,
    );

    // TODO Change this to just draw a different highlight
    if (hint != null) {
      board.setMode(HintMode(board, hint));
    } else {
      board.emitChange();
    }
  }

  @override
  void onRequestCancelInteractive() {
    board.setMode(DefaultMode(board));
  }

  @override
  bool allowRequestHint() => false;

  @override
  Widget buildBottomBar() => CommonContainer(
    key: const ValueKey('technique_pair'),
    child: InteractiveStrategyCard(strategy: _types.first),
  );
}

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
    unawaited(_runSingles());
  }

  Future<void> _runSingles() async {
    var nextSingle = board.nextSingle();
    while (nextSingle != null) {
      var elimination = nextSingle.eliminations.firstOrNull;
      var index = elimination?.$1;

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
      board.setMode(CompleteMode(board, result));
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

class CompleteMode extends BoardMode {
  final GameResult result;
  CompleteMode(super.board, this.result);

  @override
  String get name => "Complete";

  @override
  void onFirstBuild(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ResultDialog.show(context, result == GameResult.won);
    });
  }

  @override
  bool allowRequestHint() => false;

  @override
  void onRequestUndo() {
    super.onRequestUndo();
    board.setMode(DefaultMode(board));
  }
}
