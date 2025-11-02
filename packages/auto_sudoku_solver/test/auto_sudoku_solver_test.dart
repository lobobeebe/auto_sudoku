import 'package:auto_sudoku_solver/auto_sudoku_solver.dart' as solver;
import 'package:auto_sudoku_solver/src/solver_settings.dart';
import 'package:test/test.dart';

void main() {
  group('Solver.nextHint', () {
    test('naked single', () {
      final hint = _nextHint({
        (0, 0): {5},
        (0, 1): {1, 2},
      });

      expect(hint.technique, solver.StrategyUsed.nakedSingle);
      expect(hint.placements, contains((_cell(0, 0), 5)));
      expect(hint.unit, isNull);
    });

    test('hidden single (row)', () {
      final hint = _nextHint({
        (0, 0): {4, 7},
        (0, 1): {7, 8},
        (0, 2): {7, 8},
        (1, 0): {6, 9},
      });

      expect(hint.technique, solver.StrategyUsed.hiddenSingle);
      expect(hint.placements, contains((_cell(0, 0), 4)));
      expect(hint.unit, solver.HintUnit.row);
    });

    test('pointing (row)', () {
      final hint = _nextHint(
        {
          (0, 0): {5, 7},
          (0, 1): {5, 8},
          (1, 0): {7, 8},
          (1, 1): {7, 8},
          (0, 3): {5, 9},
        },
        settings: SolverSettings(
          allowHiddenSingles: false,
          allowPairs: false,
          allowTriples: false,
          allowQuads: false,
          allowHiddenSubsets: false,
        ),
      );

      expect(hint.technique, solver.StrategyUsed.pointing);
      expect(hint.unit, solver.HintUnit.row);
      expect(hint.eliminations, contains((_cell(0, 3), 5)));
    });

    test('claiming (row)', () {
      final hint = _nextHint(
        {
          (1, 3): {4, 6},
          (1, 4): {4, 7},
          (2, 4): {4, 8},
          (2, 5): {1, 2},
        },
        settings: SolverSettings(
          allowHiddenSingles: false,
          allowPairs: false,
          allowTriples: false,
          allowQuads: false,
          allowHiddenSubsets: false,
        ),
      );

      expect(hint.technique, solver.StrategyUsed.claiming);
      expect(hint.unit, solver.HintUnit.row);
      expect(hint.eliminations, contains((_cell(2, 4), 4)));
    });

    test('naked pair (row)', () {
      final hint = _nextHint({
        (2, 0): {1, 2},
        (2, 1): {1, 2},
        (2, 4): {1, 3},
        (3, 3): {4, 5},
      }, settings: SolverSettings(allowHiddenSingles: false));

      expect(hint.technique, solver.StrategyUsed.nakedPair);
      expect(hint.unit, solver.HintUnit.row);
      expect(hint.eliminations, contains((_cell(2, 4), 1)));
    });

    test('naked pair (col)', () {
      final hint = _nextHint({
        (0, 3): {8, 9},
        (2, 3): {4, 5},
        (3, 3): {4, 5, 3, 9},
        (6, 3): {3, 8, 9},
        (8, 3): {4, 5},
        (8, 4): {1, 3}, // Irrelavent - Added for noise
      }, settings: SolverSettings(allowHiddenSingles: false));

      expect(hint.technique, solver.StrategyUsed.nakedPair);
      expect(hint.unit, solver.HintUnit.column);
      expect(
        hint.eliminations,
        containsAll([
          (_cell(3, 3), 4),
          (_cell(3, 3), 5),
        ]),
      );
    });

    test('hidden pair (row)', () {
      final hint = _nextHint(
        {
          (3, 0): {4, 5, 7},
          (3, 1): {4, 5, 8},
          (3, 2): {6, 7, 8},
          (3, 5): {1, 2},
        },
        settings: SolverSettings(
          allowHiddenSingles: false,
          allowPairs: true,
          allowHiddenSubsets: true,
        ),
      );

      expect(hint.technique, solver.StrategyUsed.hiddenPair);
      expect(hint.unit, solver.HintUnit.row);
      expect(
        hint.eliminations,
        containsAll([(_cell(3, 0), 7), (_cell(3, 1), 8)]),
      );
    });

    test('naked triple (row)', () {
      final hint = _nextHint(
        {
          (4, 0): {1, 2, 3},
          (4, 1): {1, 2, 3},
          (4, 2): {1, 2, 3},
          (4, 5): {1, 4},
        },
        settings: SolverSettings(
          allowHiddenSingles: false,
          allowPairs: false,
          allowTriples: true,
        ),
      );

      expect(hint.technique, solver.StrategyUsed.nakedTriple);
      expect(hint.unit, solver.HintUnit.row);
      expect(hint.eliminations, contains((_cell(4, 5), 1)));
    });

    test('hidden triple (row)', () {
      final hint = _nextHint(
        {
          (5, 0): {4, 5, 6, 7},
          (5, 1): {4, 5, 6, 8},
          (5, 2): {4, 5, 6, 9},
          (5, 4): {1, 2},
        },
        settings: SolverSettings(
          allowHiddenSingles: false,
          allowPairs: true,
          allowTriples: true,
          allowHiddenSubsets: true,
          allowQuads: false,
        ),
      );

      expect(hint.technique, solver.StrategyUsed.hiddenTriple);
      expect(hint.unit, solver.HintUnit.row);
      expect(
        hint.eliminations,
        containsAll([(_cell(5, 0), 7), (_cell(5, 1), 8), (_cell(5, 2), 9)]),
      );
    });

    test('naked quad (row)', () {
      final hint = _nextHint(
        {
          (6, 0): {1, 2, 3, 4},
          (6, 1): {1, 2, 3, 4},
          (6, 2): {1, 2, 3, 4},
          (6, 3): {1, 2, 3, 4},
          (6, 5): {1, 5},
        },
        settings: SolverSettings(
          allowHiddenSingles: false,
          allowPairs: false,
          allowTriples: false,
          allowQuads: true,
        ),
      );

      expect(hint.technique, solver.StrategyUsed.nakedQuad);
      expect(hint.unit, solver.HintUnit.row);
      expect(hint.eliminations, contains((_cell(6, 5), 1)));
    });

    test('skips naked quad when only three cells cover four digits (row)', () {
      final sudoku = _sudokuWithNotes({
        (1, 0): {5, 9},
        (1, 3): {2, 5, 8},
        (1, 5): {2, 5, 8},
        (1, 6): {4, 9},
        (1, 8): {4, 5, 8, 9},
      });
      final hint = solver.Solver().nextHint(
        sudoku,
        settings: SolverSettings.off(allowQuads: true),
      );

      expect(
        hint,
        isNull,
        reason: hint != null ? 'Hint is ${hint.technique.name}' : null,
      );
    });

    test('hidden quad (row)', () {
      final hint = _nextHint(
        {
          (7, 0): {5, 6, 7, 8, 1},
          (7, 1): {5, 6, 7, 8, 2},
          (7, 2): {5, 6, 7, 8, 3},
          (7, 3): {5, 6, 7, 8, 4},
          (7, 5): {1, 2},
        },
        settings: SolverSettings(
          allowHiddenSingles: false,
          allowPairs: false,
          allowTriples: false,
          allowQuads: true,
          allowHiddenSubsets: true,
          allowXWing: false,
        ),
      );

      expect(hint.technique, solver.StrategyUsed.hiddenQuad);
      expect(hint.unit, solver.HintUnit.row);
      expect(
        hint.eliminations,
        containsAll([
          (_cell(7, 0), 1),
          (_cell(7, 1), 2),
          (_cell(7, 2), 3),
          (_cell(7, 3), 4),
        ]),
      );
    });

    test('X-Wing (rows)', () {
      final hint = _nextHint(
        {
          (0, 1): {5, 7},
          (0, 4): {5, 8},
          (2, 1): {5, 6},
          (2, 4): {5, 9},
          (4, 1): {5, 1},
          (5, 4): {5, 2},
        },
        settings: SolverSettings(
          allowHiddenSingles: false,
          allowLocked: false,
          allowPairs: false,
          allowTriples: false,
          allowQuads: false,
          allowHiddenSubsets: false,
        ),
      );

      expect(hint.technique, solver.StrategyUsed.xWing);
      expect(hint.digits, equals([5]));
      expect(
        hint.eliminations,
        containsAll([(_cell(4, 1), 5), (_cell(5, 4), 5)]),
      );
    });

    test('XY-Wing', () {
      final hint = _nextHint(
        {
          (0, 0): {1, 2},
          (0, 1): {1, 3},
          (1, 0): {2, 3},
          (1, 1): {3, 4},
        },
        settings: SolverSettings(
          allowHiddenSingles: false,
          allowPairs: false,
          allowTriples: false,
          allowQuads: false,
          allowHiddenSubsets: false,
          allowLocked: false,
          allowXWing: false,
        ),
      );

      expect(hint.technique, solver.StrategyUsed.xyWing);
      expect(hint.eliminations, contains((_cell(1, 1), 3)));
    });

    test('Coloring', () {
      final hint = _nextHint(
        {
          (0, 0): {5, 7},
          (0, 3): {5, 8},
          (2, 0): {5, 1},
          (2, 3): {5, 2},
          (0, 6): {3, 5, 9},
          (1, 1): {5, 9},
          (1, 4): {5, 6},
        },
        settings: SolverSettings(
          allowHiddenSingles: false,
          allowPairs: false,
          allowTriples: false,
          allowQuads: false,
          allowHiddenSubsets: false,
          allowLocked: false,
          allowXWing: false,
          allowXYWing: false,
          allowColoring: true,
          allowSwordfish: false,
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

      expect(hint.technique, solver.StrategyUsed.coloring);
      expect(hint.digits, equals([5]));
      expect(
        hint.eliminations,
        containsAll([(_cell(0, 6), 5), (_cell(1, 1), 5), (_cell(1, 4), 5)]),
      );
    });

    test('Swordfish (rows)', () {
      final hint = _nextHint(
        {
          (0, 1): {5, 7},
          (0, 4): {5, 8},
          (3, 1): {5, 2},
          (3, 7): {5, 3},
          (6, 4): {5, 4},
          (6, 7): {5, 6},
          (1, 1): {5, 9},
          (2, 4): {5, 1},
          (4, 7): {5, 2},
        },
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

      expect(hint.technique, solver.StrategyUsed.swordfish);
      expect(hint.digits, equals([5]));
      expect(
        hint.eliminations,
        containsAll([(_cell(1, 1), 5), (_cell(2, 4), 5), (_cell(4, 7), 5)]),
      );
    });
  });
}

solver.Hint _nextHint(
  Map<(int, int), Set<int>> notes, {
  SolverSettings? settings,
}) {
  final sudoku = _sudokuWithNotes(notes);
  final hint = solver.Solver().nextHint(sudoku, settings: settings);
  if (hint == null) {
    throw StateError('Expected a hint but received null');
  }
  return hint;
}

solver.Sudoku _sudokuWithNotes(Map<(int, int), Set<int>> entries) {
  final noteList = List.generate(81, (_) => <int>{});
  for (final entry in entries.entries) {
    final (row, col) = entry.key;
    noteList[_cell(row, col)] = {...entry.value};
  }
  return solver.Sudoku(List.filled(81, 0), notes: noteList);
}

int _cell(int row, int col) => row * 9 + col;
