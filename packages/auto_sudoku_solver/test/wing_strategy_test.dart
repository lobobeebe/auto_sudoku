import 'package:test/test.dart';

import 'package:auto_sudoku_solver/src/strategy/wing_strategy.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

import 'test_harness.dart';

void main() {
  group('Wing Strategies', () {
    test('X-Wing (row-based): eliminates in columns outside the two rows', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});

      const d = 6;
      // Row r1 has candidates in columns {2,7}
      final r1 = 1;
      final cA = 2;
      final cB = 7;
      cands[idx(r1, cA)] = {d};
      cands[idx(r1, cB)] = {d};

      // Row r2 has candidates in columns {2,6} (mismatch with r1)
      final r2 = 6;
      final cC = 6; // not equal to cB
      cands[idx(r2, cA)] = {d};
      cands[idx(r2, cC)] = {d};

      // Add some extra d-candidates elsewhere so a naive matcher might get confused
      cands[idx(0, cA)] = {d, 1};
      cands[idx(8, cB)] = {d, 9};
      cands[idx(3, cC)] = {d, 4};

      final h = SudokuTestHarness.make(cands);
      final strat = XWingStrategy();

      final hint = strat.findHint(h.s);
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

      var hint = strat.findHint(h.s);
      expect(hint, isNotNull);
      expect(hint!.strategy, StrategyType.xWing);
      expect(hint.digits, [7]);
      // Row-based X-Wing eliminates along columns, so unit can be column
      expect(hint.eliminations.length, 1);
      expect(hint.eliminations[idx(6, c0)], {7});

      hint = strat.getHintFromClues(h.s, [a, b, c, x]);
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

      final hint = strat.findHint(h.s);
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

      final hint = strat.findHint(h.s);
      expect(hint, isNotNull);
      expect(hint!.strategy, StrategyType.wWing);
      expect(hint.digits.toSet(), containsAll({4, 7}));
      expect(hint.cells.toSet(), containsAll({a, b, s1, s2}));
      expect(hint.eliminations[elimCell], contains(7));
    });

    test(
      'W-Wing (column strong link): two {4,7} + strong link on 4 eliminates 7',
      () {
        final cands = List<Set<int>>.generate(81, (_) => <int>{});
        int i(int r, int c) => idx(r, c);

        // Two bivalue cells with same pair {4,7}, not sharing unit
        final a = i(0, 3); // {4,7}
        final b = i(5, 8); // {4,7}
        cands[a] = {4, 7};
        cands[b] = {4, 7};

        // Strong link on digit 4 along column 1: exactly two candidates 4 at (0,1) and (5,1)
        final s1 = i(0, 1);
        final s2 = i(5, 1);
        cands[s1] = {4, 2};
        cands[s2] = {4, 9};

        // A common peer of a and b carrying digit 7 to eliminate: (0,8)
        final elimCell = i(0, 8);
        cands[elimCell] = {7, 1};

        final h = SudokuTestHarness.make(cands);
        final strat = WWingStrategy();

        final hint = strat.findHint(h.s);
        expect(hint, isNotNull);
        expect(hint!.strategy, StrategyType.wWing);
        expect(hint.digits.toSet(), containsAll({4, 7}));
        expect(hint.cells.toSet(), containsAll({a, b, s1, s2}));
        expect(hint.eliminations[elimCell], contains(7));
      },
    );

    test(
      'W-Wing getHintFromClues with explicit endpoints (column strong link)',
      () {
        final cands = List<Set<int>>.generate(81, (_) => <int>{});
        int i(int r, int c) => idx(r, c);

        // Two bivalue cells with same pair {4,7}
        final a = i(0, 3);
        final b = i(5, 8);
        cands[a] = {4, 7};
        cands[b] = {4, 7};

        // Strong link on digit 4 along column 1
        final s1 = i(0, 1);
        final s2 = i(5, 1);
        cands[s1] = {4, 2};
        cands[s2] = {4, 9};

        final elimCell = i(0, 8);
        cands[elimCell] = {7, 1};

        final h = SudokuTestHarness.make(cands);
        final strat = WWingStrategy();

        final hint = strat.getHintFromClues(h.s, [a, b, s1, s2]);
        expect(hint, isNotNull);
        expect(hint!.strategy, StrategyType.wWing);
        expect(hint.digits.toSet(), containsAll({4, 7}));
        expect(hint.cells.toSet(), containsAll({a, b, s1, s2}));
        expect(hint.eliminations[elimCell], contains(7));
      },
    );

    test(
      'W-Wing (box strong link): two {4,7} + box link on 4 eliminates 7',
      () {
        final cands = List<Set<int>>.generate(81, (_) => <int>{});
        int i(int r, int c) => idx(r, c);

        // Two bivalue cells with same pair {4,7}, not sharing unit
        final a = i(3, 0); // {4,7}
        final b = i(0, 5); // {4,7}
        cands[a] = {4, 7};
        cands[b] = {4, 7};

        // Strong link on digit 4 inside the middle box: (3,3) and (5,5)
        final s1 = i(3, 3);
        final s2 = i(5, 5);
        cands[s1] = {4, 1};
        cands[s2] = {4, 9};

        // Common peer of A and B carrying 7 to eliminate: (3,5)
        final elimCell = i(3, 5);
        cands[elimCell] = {7, 2};

        final h = SudokuTestHarness.make(cands);
        final strat = WWingStrategy();

        final hint = strat.findHint(h.s);
        expect(hint, isNotNull);
        expect(hint!.strategy, StrategyType.wWing);
        expect(hint.digits.toSet(), containsAll({4, 7}));
        expect(hint.cells.toSet(), containsAll({a, b, s1, s2}));
        expect(hint.eliminations[elimCell], contains(7));
      },
    );

    test(
      'W-Wing getHintFromClues with explicit endpoints (box strong link)',
      () {
        final cands = List<Set<int>>.generate(81, (_) => <int>{});
        int i(int r, int c) => idx(r, c);

        final a = i(3, 0); // {4,7}
        final b = i(0, 5); // {4,7}
        cands[a] = {4, 7};
        cands[b] = {4, 7};

        final s1 = i(3, 3);
        final s2 = i(5, 5);
        cands[s1] = {4, 1};
        cands[s2] = {4, 9};

        final elimCell = i(3, 5);
        cands[elimCell] = {7, 2};

        final h = SudokuTestHarness.make(cands);
        final strat = WWingStrategy();

        final hint = strat.getHintFromClues(h.s, [a, b, s1, s2]);
        expect(hint, isNotNull);
        expect(hint!.strategy, StrategyType.wWing);
        expect(hint.digits.toSet(), containsAll({4, 7}));
        expect(hint.cells.toSet(), containsAll({a, b, s1, s2}));
        expect(hint.unit, HintUnit.box);
        expect(hint.eliminations[elimCell], contains(7));
      },
    );

    test('W-Wing getHintFromClues with explicit endpoints (row strong link)', () {
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

      // A common peer of a and b carrying digit 7 to eliminate: (0,8)
      final elimCell = i(0, 8);
      cands[elimCell] = {7, 1};

      final h = SudokuTestHarness.make(cands);
      final strat = WWingStrategy();

      // Provide both bivalue cells and the two endpoints as clues
      final hint = strat.getHintFromClues(h.s, [a, b, s1, s2]);
      expect(hint, isNotNull, reason: 'Should detect W-Wing from clues');
      expect(hint!.strategy, StrategyType.wWing);
      expect(hint.digits.toSet(), containsAll({4, 7}));
      expect(hint.cells.toSet(), containsAll({a, b, s1, s2}));
      expect(hint.eliminations[elimCell], contains(7));
    });

    group('W-Wing failure cases', () {
      test(
        'getHintFromClues returns null when endpoints are not a strong link',
        () {
          final cands = List<Set<int>>.generate(81, (_) => <int>{});
          int i(int r, int c) => idx(r, c);

          // Bivalue pair {4,7}
          final a = i(0, 3);
          final b = i(5, 8);
          cands[a] = {4, 7};
          cands[b] = {4, 7};

          // Attempt a row link on digit 4 but break it by adding a third 4 in the row
          final s1 = i(2, 3);
          final s2 = i(2, 8);
          final extra = i(2, 0);
          cands[s1] = {4, 1};
          cands[s2] = {4, 9};
          cands[extra] = {4, 2}; // now row 2 has three 4s -> not a strong link

          final h = SudokuTestHarness.make(cands);
          final strat = WWingStrategy();

          final hint = strat.getHintFromClues(h.s, [a, b, s1, s2]);
          expect(hint, isNull);
        },
      );

      test(
        'getHintFromClues returns null when only pair is given and no strong link exists',
        () {
          final cands = List<Set<int>>.generate(81, (_) => <int>{});
          int i(int r, int c) => idx(r, c);

          final a = i(0, 3);
          final b = i(5, 8);
          cands[a] = {4, 7};
          cands[b] = {4, 7};

          // Ensure for both digits 4 and 7, no row/col/box has exactly two candidates
          // by sprinkling 3-of-a-kind for 4s and 7s on random rows/cols.
          cands[i(1, 0)] = {4};
          cands[i(1, 4)] = {4};
          cands[i(1, 8)] = {4};

          cands[i(7, 1)] = {7};
          cands[i(7, 3)] = {7};
          cands[i(7, 6)] = {7};

          final h = SudokuTestHarness.make(cands);
          final strat = WWingStrategy();

          final hint = strat.getHintFromClues(h.s, [a, b]);
          expect(hint, isNull);
        },
      );

      test(
        'getHintFromClues returns null when endpoints do not see both bivalue cells',
        () {
          final cands = List<Set<int>>.generate(81, (_) => <int>{});
          int i(int r, int c) => idx(r, c);

          final a = i(0, 0); // {4,7}
          final b = i(1, 1); // {4,7}
          cands[a] = {4, 7};
          cands[b] = {4, 7};

          // Strong link on 4 along row 8 (cells (8,2) and (8,7)) — these endpoints
          // are not peers of either a or b.
          final e1 = i(8, 2);
          final e2 = i(8, 7);
          cands[e1] = {4, 1};
          cands[e2] = {4, 9};

          final h = SudokuTestHarness.make(cands);
          final strat = WWingStrategy();

          final hint = strat.getHintFromClues(h.s, [a, b, e1, e2]);
          expect(hint, isNull);
        },
      );
    });

    group('XY-Wing failure cases', () {
      test('getHintFromClues returns null when pincers are identical', () {
        final cands = List<Set<int>>.generate(81, (_) => <int>{});
        int i(int r, int c) => idx(r, c);

        final pivot = i(4, 4);
        final p1 = i(4, 0);
        final p2 = i(0, 4);
        // Pivot not needed to be bivalue for this failure, but keep consistent
        cands[pivot] = {2, 3};
        // Identical pincers -> should fail
        cands[p1] = {2, 9};
        cands[p2] = {2, 9};

        final h = SudokuTestHarness.make(cands);
        final strat = XYWingStrategy();
        final hint = strat.getHintFromClues(h.s, [pivot, p1, p2]);
        expect(hint, isNull);
      });

      test(
        'getHintFromClues returns null when a pincer does not see pivot',
        () {
          final cands = List<Set<int>>.generate(81, (_) => <int>{});
          int i(int r, int c) => idx(r, c);

          final pivot = i(4, 4); // {2,3}
          final p1 = i(4, 0); // sees pivot via row
          final p2 = i(8, 8); // does not see pivot
          cands[pivot] = {2, 3};
          cands[p1] = {2, 9};
          cands[p2] = {3, 9};

          final h = SudokuTestHarness.make(cands);
          final strat = XYWingStrategy();
          final hint = strat.getHintFromClues(h.s, [pivot, p1, p2]);
          expect(hint, isNull);
        },
      );
    });

    group('X-Wing failure cases', () {
      test('getHintFromClues returns null for invalid number of indices', () {
        final cands = List<Set<int>>.generate(81, (_) => <int>{});
        final h = SudokuTestHarness.make(cands);
        final strat = XWingStrategy();
        // Too few
        expect(strat.getHintFromClues(h.s, []), isNull);
        expect(strat.getHintFromClues(h.s, [0]), isNull);
        expect(strat.getHintFromClues(h.s, [0, 1, 2]), isNull);
        // Too many
        expect(strat.getHintFromClues(h.s, [0, 1, 2, 3, 4]), isNull);
      });

      test(
        'getHintFromClues returns null when corners are not two rows/two cols',
        () {
          final cands = List<Set<int>>.generate(81, (_) => <int>{});
          int i(int r, int c) => idx(r, c);

          // Place four corners but all in the same row (invalid rectangle)
          final a = i(0, 0);
          final b = i(0, 2);
          final c = i(0, 4);
          final d = i(0, 6);
          cands[a] = {7};
          cands[b] = {7};
          cands[c] = {7};
          cands[d] = {7};

          final h = SudokuTestHarness.make(cands);
          final strat = XWingStrategy();
          final hint = strat.getHintFromClues(h.s, [a, b, c, d]);
          expect(hint, isNull);
        },
      );

      test('getHintFromClues returns null when corners lack a common digit', () {
        final cands = List<Set<int>>.generate(81, (_) => <int>{});
        int i(int r, int c) => idx(r, c);

        // Choose four corners (0,0), (0,4), (8,0), (8,4) but without a common candidate
        final a = i(0, 0);
        final b = i(0, 4);
        final c = i(8, 0);
        final d = i(8, 4);
        cands[a] = {4, 7};
        cands[b] = {5, 7};
        cands[c] = {4, 6};
        cands[d] = {5, 6};

        final h = SudokuTestHarness.make(cands);
        final strat = XWingStrategy();
        final hint = strat.getHintFromClues(h.s, [a, b, c, d]);
        expect(hint, isNull);
      });

      test(
        'getHintFromClues returns null when rows/cols have extra candidates (not exactly two)',
        () {
          final cands = List<Set<int>>.generate(81, (_) => <int>{});
          int i(int r, int c) => idx(r, c);

          // Intended rectangle corners with digit 5
          final a = i(1, 2);
          final b = i(1, 6);
          final c = i(6, 2);
          final d = i(6, 6);
          for (final t in [a, b, c, d]) {
            cands[t] = {5};
          }
          // Break row-based by adding an extra 5 in row 1 so that row 1 has 3 occurrences -> not exactly two
          cands[i(1, 4)] = {5};
          // Break column-based by adding an extra 5 in column 2 so that column 2 has 3 occurrences
          cands[i(3, 2)] = {5};

          final h = SudokuTestHarness.make(cands);
          final strat = XWingStrategy();
          final hint = strat.getHintFromClues(h.s, [a, b, c, d]);
          expect(hint, isNull);
        },
      );
    });

    group('WWing getHintFromClues input validation', () {
      test('returns null for fewer than two clues', () {
        final cands = List<Set<int>>.generate(81, (_) => <int>{});
        final h = SudokuTestHarness.make(cands);
        final strat = WWingStrategy();
        expect(strat.getHintFromClues(h.s, []), isNull);
        expect(strat.getHintFromClues(h.s, [0]), isNull);
      });

      test('returns null when bivalue pair sees each other (same unit)', () {
        final cands = List<Set<int>>.generate(81, (_) => <int>{});
        int i(int r, int c) => idx(r, c);

        // Two {4,7} in same row -> they see each other, invalid W-Wing base
        final a = i(0, 1);
        final b = i(0, 7);
        cands[a] = {4, 7};
        cands[b] = {4, 7};

        final h = SudokuTestHarness.make(cands);
        final strat = WWingStrategy();
        final hint = strat.getHintFromClues(h.s, [a, b]);
        expect(hint, isNull);
      });
    });

    group('XYWing getHintFromClues input validation', () {
      test('returns null for invalid number of clues', () {
        final cands = List<Set<int>>.generate(81, (_) => <int>{});
        final h = SudokuTestHarness.make(cands);
        final strat = XYWingStrategy();
        expect(strat.getHintFromClues(h.s, []), isNull);
        expect(strat.getHintFromClues(h.s, [0, 1]), isNull);
        expect(strat.getHintFromClues(h.s, [0, 1, 2, 3]), isNull);
      });
    });
  });
}
