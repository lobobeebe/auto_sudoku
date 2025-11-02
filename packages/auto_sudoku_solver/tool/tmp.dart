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
      (0, 1): {8, 1},
      (2, 1): {8, 2},
      (0, 5): {8, 3},
      (5, 5): {8, 4},
      (2, 5): {8, 5},
      (5, 1): {8, 6},
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
      allowSwordfish: false,
      allowSkyscraper: true,
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
