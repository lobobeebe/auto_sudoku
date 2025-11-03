import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

/// Utility: build a Sudoku with all zeros and a CandidateMap from a list of sets.
/// Adjust construction if your real Sudoku / CandidateMap have different APIs.
class SudokuTestHarness {
  final Sudoku s;
  final CandidateMap cand;

  SudokuTestHarness._(this.s, this.cand);

  /// Creates:
  /// - Sudoku with all cells empty (0)
  /// - CandidateMap from [cands], a List<Set<int>> length 81 (cands[i] are candidates at index i)
  static SudokuTestHarness make(List<Set<int>> cands) {
    assert(cands.length == 81, 'Expected 81 candidate sets');

    // Construct a blank Sudoku with helpers rowIndices/colIndices/boxIndices available.
    // If your Sudoku has a different constructor, adjust here.
    final sudoku = Sudoku(List<int>.filled(81, 0));

    // If your CandidateMap has a different constructor, adjust here.
    final cm = CandidateMap(cands, true);

    return SudokuTestHarness._(sudoku, cm);
  }
}

/// Quick helpers to address indices.
int idx(int r, int c) => r * 9 + c;
