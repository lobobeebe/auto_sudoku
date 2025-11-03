import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:test/test.dart';

import 'package:auto_sudoku_solver/src/strategy/locked_strategy.dart';

import 'test_harness.dart';

void main() {
  group('Locked Candidates – Pointing (Box → Line)', () {
    test(
      'findHint: Box→Row pointing eliminates along the row outside the box',
      () {
        // Set up a case where in box (top-left, rows 0..2, cols 0..2)
        // digit d=5 appears only in row 0 (e.g., at r0c0 and r0c1),
        // so we can eliminate 5 from row 0 outside the box.
        final cands = List<Set<int>>.generate(81, (_) => <int>{});

        final a = idx(0, 0); // in box b0, row 0
        final b = idx(0, 1); // in box b0, row 0
        cands[a] = {5, 7};
        cands[b] = {5};

        // Another cell in same row (row 0) but OUTSIDE the box
        final outsideR0 = idx(0, 5);
        cands[outsideR0] = {1, 5, 9};

        final h = SudokuTestHarness.make(cands);
        final strat = PointingStrategy();

        final hint = strat.findHint(h.s, h.cand);
        expect(hint, isNotNull, reason: 'Should find pointing along the row');
        expect(hint!.strategy, StrategyType.pointing);
        expect(hint.unit, HintUnit.row);
        expect(hint.digits, [5]);
        // Eliminations include row 0, col 5 candidate 5
        expect(hint.eliminations.toSet().contains((outsideR0, 5)), isTrue);
        // Cells list are the in-box candidates for d
        expect(hint.cells.toSet().containsAll({a, b}), isTrue);
      },
    );

    test(
      'getHintFromClues: Box→Column pointing eliminates along the column',
      () {
        final cands = List<Set<int>>.generate(81, (_) => <int>{});

        // Create a pointing situation for digit 7 in box (rows 3..5, cols 3..5)
        // constrained to a single column (col 4).
        final c1 = idx(3, 4); // in the box, column 4
        final c2 = idx(4, 4); // in the box, column 4
        cands[c1] = {7, 2};
        cands[c2] = {7};

        // A candidate 7 in the same column but OUTSIDE the box, to be eliminated
        final outsideCol = idx(8, 4);
        cands[outsideCol] = {7, 9};

        final h = SudokuTestHarness.make(cands);
        final strat = PointingStrategy();

        // Provide the two in-box column clue cells.
        final hint = strat.getHintFromClues(h.s, h.cand, [c1, c2]);
        expect(hint, isNotNull, reason: 'Should derive pointing from clues');
        expect(hint!.strategy, StrategyType.pointing);
        expect(hint.unit, HintUnit.column);
        expect(hint.digits, [7]);
        expect(hint.eliminations.toSet().contains((outsideCol, 7)), isTrue);
      },
    );
  });

  group('Locked Candidates – Claiming (Line → Box)', () {
    test(
      'findHint: Row→Box claiming eliminates inside the box outside the row',
      () {
        // Row 4 has all candidates for digit d=3 located within a single box (cols 3..5).
        // Therefore, eliminate 3 from other cells in that same box not in row 4.
        final cands = List<Set<int>>.generate(81, (_) => <int>{});

        final r = 4;
        final a = idx(r, 3); // inside the target box (center box)
        final b = idx(r, 4); // inside the same box
        cands[a] = {3, 8};
        cands[b] = {1, 3};

        // A peer inside the same box but DIFFERENT row: should eliminate 3
        final peer = idx(3, 5); // row 3, col 5 (same box as a/b)
        cands[peer] = {3, 9};

        final h = SudokuTestHarness.make(cands);
        final strat = ClaimingStrategy();

        final hint = strat.findHint(h.s, h.cand);
        expect(hint, isNotNull, reason: 'Should find claiming from row→box');
        expect(hint!.strategy, StrategyType.claiming);
        expect(hint.unit, HintUnit.row);
        expect(hint.digits, [3]);
        // eliminations include peer cell removing 3
        expect(hint.eliminations.toSet().contains((peer, 3)), isTrue);
        expect(hint.cells.toSet().containsAll({a, b}), isTrue);
      },
    );

    test('getHintFromClues: Column→Box claiming eliminates inside the box', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});

      // Column 7 has all digit 9 candidates confined to a single box (rows 6..8),
      // so eliminate 9 from other cells in that box not in this column.
      final col = 7;
      final x = idx(6, col);
      final y = idx(8, col);
      cands[x] = {9, 1};
      cands[y] = {2, 9};

      // A peer in the same box but different column: should eliminate 9
      final peer = idx(7, 6); // same bottom-right box
      cands[peer] = {4, 9};

      final h = SudokuTestHarness.make(cands);
      final strat = ClaimingStrategy();

      final hint = strat.getHintFromClues(h.s, h.cand, [x, y]);
      expect(
        hint,
        isNotNull,
        reason: 'Should derive claiming from column clues',
      );
      expect(hint!.strategy, StrategyType.claiming);
      expect(hint.unit, HintUnit.column);
      expect(hint.digits, [9]);
      expect(hint.eliminations.toSet().contains((peer, 9)), isTrue);
    });
  });
}
