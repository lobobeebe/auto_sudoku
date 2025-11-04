import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CellViewModel {
  final Color? backgroundColor;
  final Color? valueTextColor;
  final FontWeight? valueFontWeight;
  final double? valueScale;
  final List<CellNoteViewModel> notes;

  CellViewModel({
    this.backgroundColor,
    this.valueTextColor,
    this.valueFontWeight,
    this.valueScale,
    required this.notes,
  });
}

class CellNoteViewModel {
  final Color? textColor;
  final double? scale;
  final FontWeight? fontWeight;

  CellNoteViewModel({this.textColor, this.scale, required this.fontWeight});
}

abstract class GridHighlighter {
  const GridHighlighter();

  CellViewModel getByIndex(BuildContext context, int index);
}

/// Default highlighter used during normal play (no interactive technique mode).
class DefaultHighlighter extends GridHighlighter {
  const DefaultHighlighter();

  @override
  CellViewModel getByIndex(BuildContext context, int index) {
    final board = Provider.of<SudokuBoardState>(context);
    final theme = SudokuTheme.of(context);

    SudokuCell cell = board.getCellAtIndex(index)!;
    bool isSelected = board.isIndexSelected(index);
    bool isPeer = board.isPeerWithAllSelected(index);
    bool isMatching = board.matchesAnySelected(index);

    Color bg = theme.boardSurface;
    if (isSelected) {
      bg = theme.selectedCellBackground;
    } else if (isPeer) {
      bg = theme.peerCellBackground;
    } else if (isMatching) {
      bg = theme.matchingValueBackground;
    }

    Color valueTextColor = cell.isGiven
        ? theme.givenCellTextColor
        : (isSelected
              ? theme.valueHighlightColor
              : theme.valueRegularTextColor);

    final notes = List.generate(9, (digit) {
      bool digitSelected = board.isDigitSelected(digit + 1);
      return CellNoteViewModel(
        scale: digitSelected ? 1.1 : 1,
        fontWeight: digitSelected ? FontWeight.w600 : null,
      );
    });

    return CellViewModel(
      backgroundColor: bg,
      valueTextColor: valueTextColor,
      notes: notes,
    );
  }
}

/// Highlighter for interactive hint/technique selection mode.
/// Emphasizes the currently selected technique cells and subtly dims others.
class HintHighlighter extends GridHighlighter {
  final Hint hint;
  const HintHighlighter(this.hint);

  @override
  CellViewModel getByIndex(BuildContext context, int index) {
    final board = Provider.of<SudokuBoardState>(context);
    final theme = SudokuTheme.of(context);

    SudokuCell cell = board.getCellAtIndex(index)!;
    bool isSelected = board.isIndexSelected(index);
    bool isPeer = board.isPeerWithAllSelected(index);
    bool isMatching = board.matchesAnySelected(index);

    Color bg = theme.boardSurface;
    if (isSelected) {
      bg = theme.selectedCellBackground;
    } else if (isPeer) {
      bg = theme.peerCellBackground;
    } else if (isMatching) {
      bg = theme.matchingValueBackground;
    }

    Color valueTextColor = cell.isGiven
        ? theme.givenCellTextColor
        : (isSelected
              ? theme.valueHighlightColor
              : theme.valueRegularTextColor);

    final notes = List.generate(9, (digit) {
      bool matchesSelectedDigit = board.isDigitSelected(digit);
      return CellNoteViewModel(
        scale: matchesSelectedDigit ? 1.2 : 1,
        fontWeight: matchesSelectedDigit ? FontWeight.w600 : null,
      );
    });

    return CellViewModel(
      backgroundColor: bg,
      valueTextColor: valueTextColor,
      notes: notes,
    );
  }
}
