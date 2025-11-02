import 'package:auto_sudoku_solver/auto_sudoku_solver.dart' as solver;
import 'package:auto_sudoku_solver/src/solver_settings.dart';

int cell(int r, int c) => r * 9 + c;

solver.Sudoku sudokuWithNotes(Map<(int, int), Set<int>> entries) {
  final notes = List.generate(81, (_) => <int>{});
  for (final entry in entries.entries) {
    final (row, col) = entry.key;
    notes[cell(row, col)] = {...entry.value};
  }
  return solver.Sudoku(List.filled(81, 0), notes: notes);
}

void main() {
  final hint = solver.Solver().nextHint(
    sudokuWithNotes({
      (0, 1): {5, 7},
      (0, 4): {5, 8},
      (3, 1): {5, 2},
      (3, 7): {5, 3},
      (6, 4): {5, 4},
      (6, 7): {5, 6},
      (1, 1): {5, 9},
      (2, 4): {5, 1},
      (4, 7): {5, 2},
    }),
    settings: SolverSettings(
      allowHiddenSingles: false,
      allowPairs: false,
      allowTriples: false,
      allowQuads: false,
      allowHiddenSubsets: false,
      allowLocked: false,
      allowXWing: false,
      allowXYWing: false,
      allowColoring: false,
      allowSwordfish: true,
      allowSkyscraper: false,
      allowTwoStringKite: false,
      allowTurbotFish: false,
      allowXYZWing: false,
      allowWWing: false,
      allowUR: false,
      allowBUG: false,
      allowRemotePairs: false,
      allowXYChain: false,
      allowALS: false,
      allowALSXYWing: false,
      allowAIC: false,
    ),
  );
  print(hint?.technique);
  print(hint?.digits);
  print(hint?.cells);
  print(hint?.eliminations);
}
