// import 'package:auto_sudoku/state/board_mode.dart';
// import 'package:auto_sudoku/state/board_state/hint_state.dart';
// import 'package:auto_sudoku/ui/utils/utils.dart';
// import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

// class NoteMode extends BoardMode {
//   NoteMode(super.board);

//   int? get _selectedIndex => board.selectedIndices.lastOrNull;
//   set _selectedIndex(int? idx) {
//     final oldIndex = _selectedIndex;
//     board.selectedIndices.clear();

//     if (idx != null && oldIndex != idx) {
//       board.selectedIndices.add(idx);
//     }
//   }

//   @override
//   String get name => "Notes";

//   @override
//   bool onRequestEnterDigit(int digit) {
//     final idx = _selectedIndex;
//     if (idx == null || digit < 1 || digit > 9) {
//       return false;
//     }
//     final cell = board.getCellAtIndex(idx);

//     if (cell == null || cell.isGiven) {
//       return false;
//     }

//     board.pushSnapshot();

//     if (cell.value != null) {
//       return false;
//     }

//     // Make update to clone
//     final updatedNotes = {...cell.notes};
//     if (updatedNotes.contains(digit)) {
//       updatedNotes.remove(digit);
//     } else {
//       updatedNotes.add(digit);
//     }

//     // If no change, skip
//     final wasChanged = !SudokuUtils.notesEqual(updatedNotes, cell.notes);
//     if (!wasChanged) {
//       return false;
//     }

//     // Push snapshot for undo
//     board.pushSnapshot();

//     // Apply Note clone to Cell
//     board.setCellAtIndex(idx, cell.withNotes(updatedNotes));

//     board.emitChange();

//     // If singles are now present in the board, transition to Animating
//     if (board.nextSingle() != null) {
//       board.setMode(AnimatingMode(board, this));
//     }
//     return true;
//   }

//   @override
//   bool isNoteMode() => true;

//   @override
//   bool canPressDigit(int digit) {
//     final idx = _selectedIndex;
//     if (idx == null || digit < 1 || digit > 9) {
//       return false;
//     }

//     final cell = board.getCellAtIndex(idx);

//     if (cell == null || cell.isGiven) {
//       return false;
//     }

//     return cell.value == null;
//   }

//   @override
//   void onRequestSelectCell(int row, int col) {
//     final newIndex = board.getIndex(row, col);
//     _selectedIndex = newIndex;
//     board.emitChange();
//   }

//   @override
//   void onRequestNoteMode() {
//     board.setMode(DefaultMode(board));
//   }

//   @override
//   void onRequestSetHint(Hint hint) {
//     board.setMode(HintMode(board, hint, this));
//   }
// }
