import 'package:test/test.dart';

import 'package:auto_sudoku_solver/src/strategy/wing_strategy.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

import 'test_harness.dart';

void main() {
  group('Wing Strategies', () {
    test('X-Wing (row-based): eliminates in columns outside the two rows', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});
      int i(int r, int c) => idx(r, c);

      const d = 6;
      // Row r1 has candidates in columns {2,7}
      final r1 = 1;
      final cA = 2;
      final cB = 7;
      cands[i(r1, cA)] = {d};
      cands[i(r1, cB)] = {d};

      // Row r2 has candidates in columns {2,6} (mismatch with r1)
      final r2 = 6;
      final cC = 6; // not equal to cB
      cands[i(r2, cA)] = {d};
      cands[i(r2, cC)] = {d};

      // Add some extra d-candidates elsewhere so a naive matcher might get confused
      cands[i(0, cA)] = {d, 1};
      cands[i(8, cB)] = {d, 9};
      cands[i(3, cC)] = {d, 4};

      final h = SudokuTestHarness.make(cands);
      final strat = XWingStrategy();

      final hint = strat.findHint(h.s, h.cand);
      expect(
        hint,
        isNull,
        reason: 'Should not detect X-Wing when column pairs differ',
      );
    });

    test('X-Wing', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});

      // Choose rows r1=1, r2=6 and columns cA=2, cB=7 for the four corners
      final r0 = 0, r8 = 8, c0 = 0, c4 = 4;
      final a = idx(r0, c0);
      final b = idx(r0, c4);
      final c = idx(r8, c0);
      final x = idx(r8, c4);

      // Place the four corners with candidate d (ensure these rows have d only in cA/cB)

      cands[c] = {4, 5, 6, 7};
      cands[x] = {4, 6, 7};

      // Place some noise
      cands[idx(r0, c0)] = {4, 7}; // A
      cands[idx(3, c0)] = {5, 6, 8};
      cands[idx(4, c0)] = {4, 6, 8};
      cands[idx(6, c0)] = {6, 7};

      cands[idx(r0, c4)] = {4, 7}; // B
      cands[idx(3, c4)] = {2, 3, 8};
      cands[idx(4, c4)] = {2, 3, 8};
      cands[idx(5, c4)] = {2, 8};
      cands[idx(7, c4)] = {4, 6};

      cands[idx(r0, 7)] = {5, 9};
      cands[idx(r0, 8)] = {5, 9};

      cands[idx(r8, 1)] = {3, 4, 6};
      cands[idx(r8, 3)] = {3, 4, 5};
      cands[idx(r8, 8)] = {3, 6};

      final h = SudokuTestHarness.make(cands);
      final strat = XWingStrategy();

      var hint = strat.findHint(h.s, h.cand);
      expect(hint, isNotNull);
      expect(hint!.strategy, StrategyType.xWing);
      expect(hint.digits, [7]);
      // Row-based X-Wing eliminates along columns, so unit can be column
      expect(hint.eliminations.length, 1);
      expect(hint.eliminations[idx(6, c0)], {7});

      hint = strat.getHintFromClues(h.s, h.cand, [a, b, c, x]);
      expect(hint, isNotNull);
      expect(hint!.strategy, StrategyType.xWing);
      expect(hint.digits, [7]);
      // Row-based X-Wing eliminates along columns, so unit can be column
      expect(hint.eliminations.length, 1);
      expect(hint.eliminations[idx(6, c0)], {7});
    });

    test('XY-Wing: pivot {2,3} with pincers {2,9} and {3,9} eliminates 9', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});
      int i(int r, int c) => idx(r, c);

      // Pivot at (4,4): {2,3}
      final pivot = i(4, 4);
      cands[pivot] = {2, 3};

      // Pincer1 at (4,0): {2,9} (sees pivot via row)
      final p1 = i(4, 0);
      cands[p1] = {2, 9};

      // Pincer2 at (0,4): {3,9} (sees pivot via column)
      final p2 = i(0, 4);
      cands[p2] = {3, 9};

      // A cell that sees BOTH pincers: (0,0) (row 0 with p2, col 0 with p1)
      final elimCell = i(0, 0);
      cands[elimCell] = {9, 1};

      final h = SudokuTestHarness.make(cands);
      final strat = XYWingStrategy();

      final hint = strat.findHint(h.s, h.cand);
      expect(hint, isNotNull);
      expect(hint!.strategy, StrategyType.xyWing);
      expect(hint.cells.toSet(), containsAll({pivot, p1, p2}));
      expect(hint.digits.toSet(), containsAll({2, 3, 9}));
      expect(hint.eliminations[elimCell], contains(9));
    });

    test('W-Wing (row strong link): two {4,7} + strong link on 4 eliminates 7', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});
      int i(int r, int c) => idx(r, c);

      // Two bivalue cells with same pair {4,7}, not sharing unit
      final a = i(0, 3); // {4,7}
      final b = i(5, 8); // {4,7}
      cands[a] = {4, 7};
      cands[b] = {4, 7};

      // Strong link on digit 4 along row 2: exactly two candidates 4 at (2,3) and (2,8)
      final s1 = i(2, 3);
      final s2 = i(2, 8);
      cands[s1] = {4, 1};
      cands[s2] = {4, 9};

      // A common peer of a and b carrying digit 7 to eliminate: (0,8) (row of a, column of b)
      final elimCell = i(0, 8);
      cands[elimCell] = {7, 1};

      final h = SudokuTestHarness.make(cands);
      final strat = WWingStrategy();

      final hint = strat.findHint(h.s, h.cand);
      expect(hint, isNotNull);
      expect(hint!.strategy, StrategyType.wWing);
      expect(hint.digits.toSet(), containsAll({4, 7}));
      expect(hint.cells.toSet(), containsAll({a, b, s1, s2}));
      expect(hint.eliminations[elimCell], contains(7));
    });
  });
}
