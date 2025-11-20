import 'package:auto_sudoku_solver/src/hint.dart';
import 'package:auto_sudoku_solver/src/strategy/strategy.dart';
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

        final hint = strat.findHint(h.s);
        expect(hint, isNotNull, reason: 'Should find pointing along the row');
        expect(hint!.strategy, StrategyType.pointing);
        expect(hint.unit, HintUnit.row);
        expect(hint.digits, [5]);
        // Eliminations include row 0, col 5 candidate 5
        expect(hint.eliminations[outsideR0], {5});
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
        final hint = strat.getHintFromClues(h.s, [c1, c2]);
        expect(hint, isNotNull, reason: 'Should derive pointing from clues');
        expect(hint!.strategy, StrategyType.pointing);
        expect(hint.unit, HintUnit.column);
        expect(hint.digits, [7]);
        expect(hint.eliminations[outsideCol], {7});
      },
    );
  });

  group('Locked Candidates – Claiming (Line → Box)', () {
    test(
      'findHint: Row→Box claiming eliminates inside the box outside the row',
      () {
        // 0-based indexing:
        // Put all 3s in row 4 within the center box (cols 3..5).
        // Then eliminate 3 from other cells in that box but NOT in row 4.

        final cands = List<Set<int>>.generate(81, (_) => <int>{});

        int idx(int r, int c) => r * 9 + c;

        final r = 4; // row 4 (0-based)
        final a = idx(r, 3); // r4c3 (center box)
        final b = idx(r, 4); // r4c4 (center box)
        cands[a] = {3, 8};
        cands[b] = {1, 3};

        // Make it explicit: no other 3s in row 4
        for (var c = 0; c < 9; c++) {
          if (c == 3 || c == 4) continue;
          cands[idx(r, c)] = {}; // ensure no candidate 3 elsewhere in the row
        }

        // A peer in the same box but a different row: should be eliminated
        final peer = idx(3, 5); // r3c5 (still center box)
        cands[peer] = {3, 9};

        // Ensure no other 3s exist in the same box outside row 4, so only one elimination
        // Also avoid creating competing claims by not repeating the same digit twice
        // in any remaining row within the box.
        // Row 3 (r=3), cols 3..5 except peer (r3c5): use distinct non-3 digits
        final r3c3 = idx(3, 3);
        final r3c4 = idx(3, 4);
        if (r3c3 != peer) cands[r3c3] = {4};
        if (r3c4 != peer) cands[r3c4] = {5};
        // r3c5 is `peer` and already set to {3,9}

        // Row 5 (r=5), cols 3..5: use distinct non-3 digits
        cands[idx(5, 3)] = {6};
        cands[idx(5, 4)] = {7};
        cands[idx(5, 5)] = {8};

        final h = SudokuTestHarness.make(cands);
        final strat = ClaimingStrategy();

        final hint = strat.findHint(h.s);
        expect(hint, isNotNull, reason: 'Should find claiming from row→box');
        expect(hint!.strategy, StrategyType.claiming);
        expect(hint.unit, HintUnit.row);
        expect(hint.digits, unorderedEquals([3]));

        // Exactly one elimination, and it is {peer: {3}}
        expect(hint.eliminations.length, 1);
        expect(hint.eliminations[peer], {3});

        // Base cells in the row used to claim are included
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

      final hint = strat.getHintFromClues(h.s, [x, y]);
      expect(
        hint,
        isNotNull,
        reason: 'Should derive claiming from column clues',
      );
      expect(hint!.strategy, StrategyType.claiming);
      expect(hint.unit, HintUnit.column);
      expect(hint.digits, [9]);
      expect(hint.eliminations[peer], {9});
    });
  });
}
