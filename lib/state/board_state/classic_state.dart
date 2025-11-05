// class DefaultMode extends BoardMode {
//   DefaultMode(super.board);
//   @override
//   String get name => 'Default';

//   @override
//   void onRequestSelectCell(int row, int col) {
//     final newIndex = board.getIndex(row, col);

//     final cell = board.getCellAtIndex(newIndex);
//     if (cell == null || cell.isGiven || cell.value != null) {
//       return;
//     }

//     if (board.selectedIndices.contains(newIndex)) {
//       board.selectedIndices.remove(newIndex);
//     } else {
//       board.selectedIndices.add(newIndex);
//     }

//     board.emitChange();
//   }

//   // @override
//   // bool onRequestEnterDigit(int digit) {
//   //   final idx = 0;
//   //   if (idx == null || digit < 1 || digit > 9) {
//   //     return false;
//   //   }
//   //   final cell = board.getCellAtIndex(idx);

//   //   if (cell == null || cell.isGiven) {
//   //     return false;
//   //   }

//   //   // Push snapshot for undo point
//   //   board.pushSnapshot();

//   //   // Set cell
//   //   board.setCellAtIndex(idx, cell.withValue(digit));

//   //   // Evaluate completion
//   //   final result = board.evaluateResult();
//   //   if (result != null) {
//   //     board.setMode(CompleteMode(board, result));
//   //     return true;
//   //   }

//   //   // Remove the notes in conflict with this change.
//   //   board.pruneNotesAround(idx, digit);

//   //   // If there are singles to remove, transition to animating
//   //   if (board.nextSingle() != null) {
//   //     board.setMode(AnimatingMode(board, this));
//   //     return true;
//   //   }

//   //   board.emitChange();

//   //   return true;
//   // }

//   @override
//   void onRequestInteractive(Set<StrategyType> types) {
//     board.setMode(InteractiveMode(board, types));
//   }

//   @override
//   void onRequestNoteMode() {
//     board.setMode(NoteMode(board));
//   }

//   @override
//   void onRequestSetHint(Hint hint) {
//     board.setMode(HintMode(board, hint, this));
//   }

//   // @override
//   // bool canPressDigit(int digit) {
//   //   final idx = _selectedIndex;
//   //   if (idx == null || digit < 1 || digit > 9) {
//   //     return false;
//   //   }

//   //   return board.canPlaceDigit(idx, digit);
//   // }
// }
