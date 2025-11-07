// --- Board State Machine ----------------------------------------------------

import 'package:auto_sudoku/data/cell_view_model.dart';
import 'package:auto_sudoku/data/sudoku_model.dart';
import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:auto_sudoku/ui/widgets/action_bar.dart';
import 'package:auto_sudoku/ui/widgets/common_container.dart';
import 'package:auto_sudoku/ui/widgets/result_dialog.dart';
import 'package:auto_sudoku/ui/widgets/strategy_category_popup_menu.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';

abstract class BoardMode {
  final SudokuBoardState board;
  const BoardMode(this.board);

  String get name;

  /// When this mode becomes active.
  void onEnter() {}

  /// When this mode is replaced.
  void onExit() {}

  // Interaction hooks (override as needed)
  void onRequestInitPuzzle(SudokuModel? puzzle, String? error) {}
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

  void onRequestStrategyCategory(StrategyCategory category) {}

  // UI allowances
  bool allowReset() => true;
  Widget? buildBodyOverride(BuildContext context) => null;
  void onFirstBuild(BuildContext context) {}
  bool allowUndo() => true;
  bool allowRequestHint() => true;
  bool allowControls() => true;
  bool canPressDigit(int digit) => false;
  bool isNoteMode() => false;

  CellViewModel buildCellViewModel(int index, SudokuTheme theme) {
    bool isSelected = board.isIndexSelected(index);
    bool isPeer = board.isPeerWithAllSelected(index);

    bool isMatching = board.matchesAnySelected(index);
    Set<int> selectedNoteDigits = board.selectedIndices.fold(
      <int>{},
      (set, index) => set..addAll(board.sudoku.notesSet(index)),
    );

    Color bg = theme.boardSurface;
    if (isSelected) {
      bg = theme.selectedCellBackground;
    } else if (isPeer) {
      bg = theme.peerCellBackground;
    } else if (isMatching) {
      bg = theme.matchingValueBackground;
    }

    Color valueTextColor = isSelected
        ? theme.valueHighlightColor
        : theme.valueRegularTextColor;

    final notes = List.generate(9, (digit) {
      bool digitSelected =
          (isSelected || isPeer) && selectedNoteDigits.contains(digit + 1);

      return CellNoteViewModel(
        scale: digitSelected ? 1.25 : null,
        fontWeight: digitSelected ? FontWeight.w600 : null,
      );
    });

    return CellViewModel(
      backgroundColor: bg,
      valueTextColor: valueTextColor,
      notes: notes,
    );
  }

  Widget buildBottomBar() =>
      CommonContainer(key: const ValueKey("controls"), child: ActionBar());
}

class CompleteMode extends BoardMode {
  final GameResult result;
  final BoardMode lastMode;
  CompleteMode(super.board, this.result, this.lastMode);

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
    board.setMode(lastMode);
  }
}
