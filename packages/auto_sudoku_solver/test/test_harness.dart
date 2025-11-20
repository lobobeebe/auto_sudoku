import 'package:auto_sudoku_solver/src/sudoku.dart';

/// Utility: build a Sudoku with all zeros and a CandidateMap from a list of sets.
/// Adjust construction if your real Sudoku / CandidateMap have different APIs.
class SudokuTestHarness {
  final Sudoku s;

  SudokuTestHarness._(this.s);

  /// Creates:
  /// - Sudoku with all cells empty (0)
  static SudokuTestHarness make(List<Set<int>> notes) {
    assert(notes.length == 81, 'Expected 81 notes sets');

    // Construct a blank Sudoku with helpers rowIndices/colIndices/boxIndices available.
    // If your Sudoku has a different constructor, adjust here.
    final sudoku = Sudoku(List<int>.filled(81, 0), notes: notes);

    return SudokuTestHarness._(sudoku);
  }
}

/// Quick helpers to address indices.
int idx(int r, int c) => r * 9 + c;
