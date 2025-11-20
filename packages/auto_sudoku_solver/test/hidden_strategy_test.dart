import 'package:auto_sudoku_solver/src/hint.dart';
import 'package:auto_sudoku_solver/src/strategy/strategy.dart';
import 'package:test/test.dart';

import 'package:auto_sudoku_solver/src/strategy/hidden_strategy.dart';

import 'test_harness.dart';

void main() {
  group('Hidden Strategies - getHintFromClues & findHint', () {
    test('Hidden Single: unique in a row yields a placement', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});
      // In row 0, digit 5 appears only at c3.
      final cell = idx(0, 3);
      cands[cell] = {5, 1, 3};
      // Other empties in the same row have other candidates but not 5.
      cands[idx(0, 0)] = {1, 2};
      cands[idx(0, 1)] = {1, 2, 3};

      final h = SudokuTestHarness.make(cands);
      final strat = HiddenSingleStrategy();

      final hint = strat.findHint(h.s);
      expect(hint, isNotNull);
      expect(hint!.strategy, StrategyType.hiddenSingle);
      expect(hint.placements, isNotNull);
      expect(hint.placements[cell], 5);

      final hintFromClues = strat.getHintFromClues(h.s, [cell]);
      expect(hintFromClues, isNotNull);
      expect(hintFromClues!.placements[cell], 5);
    });

    test('Hidden Pair in a row: eliminations inside the pair cells', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});

      // Row 2: hidden pair digits {3,7} appear only at c1 and c6 in this row.
      final a = idx(2, 1);
      final b = idx(2, 6);
      // Include extra candidates to prove eliminations occur inside the pair cells.
      cands[a] = {3, 7, 9};
      cands[b] = {1, 3, 7};

      // All other cells in the row must NOT contain 3 or 7, otherwise not a hidden pair.
      for (var c = 0; c < 9; c++) {
        final i = idx(2, c);
        if (i == a || i == b) continue;
        cands[i] = {1, 2, 4, 5, 6, 8, 9};
      }

      final h = SudokuTestHarness.make(cands);
      final strat = HiddenPairStrategy();

      final hint = strat.findHint(h.s);
      expect(hint, isNotNull, reason: 'Should find a Hidden Pair in the row');
      expect(hint!.strategy, StrategyType.hiddenPair);
      expect(hint.unit, HintUnit.row);
      expect(hint.cells.toSet(), {a, b});
      expect(hint.digits.toSet(), {3, 7});

      // Eliminations are within the pair cells: remove non {3,7}
      final elim = hint.eliminations;
      expect(elim.length, 2);
      expect(elim[a], {9});
      expect(elim[b], {1});

      // getHintFromClues path mirrors the same outcome
      final fromClues = strat.getHintFromClues(h.s, [a, b]);
      expect(fromClues, isNotNull);
      expect(fromClues!.digits.toSet(), {3, 7});
    });

    test('Hidden Triple in a column: eliminations inside the three cells', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});

      // Column 5: digits {1,4,6} appear only at r1, r4, r8 in this column.
      final a = idx(0, 5); // r1 c6
      final b = idx(3, 5); // r4 c6
      final c = idx(7, 5); // r8 c6

      cands[a] = {1, 4, 9};
      cands[b] = {1, 6};
      cands[c] = {4, 6, 8};

      // Other cells in column 6 do not contain 1/4/6
      for (var r = 0; r < 9; r++) {
        final i = idx(r, 5);
        if (i == a || i == b || i == c) continue;
        cands[i] = {2, 3, 5, 7, 8, 9};
      }

      final h = SudokuTestHarness.make(cands);
      final strat = HiddenTripleStrategy();

      final hint = strat.findHint(h.s);
      expect(hint, isNotNull);
      expect(hint!.strategy, StrategyType.hiddenTriple);
      expect(hint.unit, HintUnit.column);
      expect(hint.cells.toSet(), {a, b, c});
      expect(hint.digits.toSet(), {1, 4, 6});

      final elim = hint.eliminations;
      // Eliminations are candidates in those cells not among {1,4,6}
      expect(elim[a], {9});
      expect(elim[c], {8});

      final fromClues = strat.getHintFromClues(h.s, [a, b, c]);
      expect(fromClues, isNotNull);
      expect(fromClues!.digits.toSet(), {1, 4, 6});
    });

    test('Hidden Quad in a box: eliminations inside the four cells', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});

      // Box (rows 3..5, cols 3..5) center box; digits {2,4,6,9} only in these four cells
      final a = idx(3, 3); // r4c4
      final b = idx(4, 3); // r5c4
      final c = idx(4, 5); // r5c6
      final d = idx(5, 4); // r6c5

      cands[a] = {2, 4, 8};
      cands[b] = {2, 6};
      cands[c] = {4, 9};
      cands[d] = {6, 9, 1};

      // Ensure other cells in the same box do NOT contain 2/4/6/9
      for (var r = 3; r <= 5; r++) {
        for (var col = 3; col <= 5; col++) {
          final i = idx(r, col);
          if ({a, b, c, d}.contains(i)) continue;
          cands[i] = {1, 3, 5, 7, 8};
        }
      }

      final h = SudokuTestHarness.make(cands);
      final strat = HiddenQuadStrategy();

      final hint = strat.findHint(h.s);
      expect(hint, isNotNull);
      expect(hint!.strategy, StrategyType.hiddenQuad);
      expect(hint.unit, HintUnit.box);
      expect(hint.cells.toSet(), {a, b, c, d});
      expect(hint.digits.toSet(), {2, 4, 6, 9});

      final elim = hint.eliminations;
      expect(elim[a], {8});
      expect(elim[d], {1});

      final fromClues = strat.getHintFromClues(h.s, [a, b, c, d]);
      expect(fromClues, isNotNull);
      expect(fromClues!.digits.toSet(), {2, 4, 6, 9});
    });
  });
}
