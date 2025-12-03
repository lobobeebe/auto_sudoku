import 'package:auto_sudoku/data/cell_view_model.dart';
import 'package:auto_sudoku/state/board_mode.dart';
import 'package:auto_sudoku/state/board_state/animating_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:auto_sudoku/ui/widgets/common_container.dart';
import 'package:auto_sudoku/ui/widgets/hint_steps_panel.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';

class HintMode extends BoardMode {
  final Hint hint;
  final BoardMode previousMode;
  HintMode(super.board, this.hint, this.previousMode);

  @override
  String get name => "Hint";

  @override
  bool onRequestApplyCurrentHint() {
    final snapshot = board.makeSnapshot();
    final mutated = board.applyHintToBoard(hint);
    if (mutated) {
      board.pushSnapshot(snapshot: snapshot);
    }

    board.selectedIndices.clear();

    board.setMode(AnimatingMode(board, previousMode));

    return mutated;
  }

  @override
  void onRequestClearHint() {
    board.setMode(previousMode);
  }

  @override
  bool allowRequestHint() => false;

  @override
  Widget buildBottomBar() => CommonContainer(
    key: const ValueKey('hintPanel'),
    child: HintStepsPanel(hint: hint),
  );

  @override
  CellViewModel buildCellViewModel(int index, SudokuTheme theme) {
    bool isHintCell =
        hint.eliminations.containsKey(index) || hint.cells.contains(index);

    if (!isHintCell) {
      return super.buildCellViewModel(index, theme);
    }

    final notes = List.generate(9, (digitIndex) {
      final digit = digitIndex + 1;
      bool isEliminationNote =
          hint.eliminations[index]?.contains(digit) ?? false;
      bool isClueNote = hint.digits.contains(digit);
      Color? textColor = isEliminationNote
          ? theme.noteEliminationTextColor
          : (isClueNote ? theme.noteClueTextColor : null);

      return CellNoteViewModel(
        scale: (isEliminationNote || isClueNote)
            ? theme.noteEmphasisScale
            : theme.noteDefaultScale,
        textColor: textColor,
        fontWeight: (isEliminationNote || isClueNote)
            ? theme.noteEmphasisFontWeight
            : null,
      );
    });

    return CellViewModel(
      // TODO Create hint cell background in theme
      backgroundColor: board.isIndexSelected(index)
          ? theme.selectedCellBackground
          : theme.peerCellBackground,
      notes: notes,
    );
  }
}
