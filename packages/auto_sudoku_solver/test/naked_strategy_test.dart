import 'package:test/test.dart';
import 'package:auto_sudoku_solver/src/sudoku_tool.dart';
import 'package:auto_sudoku_solver/src/strategy/naked_strategy.dart';

import 'test_harness.dart';

void main() {
  group('Naked getHintFromClues (Pair/Triple/Quad)', () {
    test('Naked Triple in a row produces eliminations in that row', () {
      // Prepare candidates: all empty by default.
      final cands = List<Set<int>>.generate(81, (_) => <int>{});

      // Row 0: three bi/tri-value cells with union {1,2,3} form a naked triple.
      final a = idx(0, 0);
      final b = idx(0, 1);
      final c = idx(0, 2);

      cands[a] = {1, 2}; // subset of the triple
      cands[b] = {1, 3}; // subset of the triple
      cands[c] = {2, 3}; // subset of the triple

      // Other cells in row 0 that should get candidates {1,2,3} eliminated.
      final d = idx(0, 3);
      final e = idx(0, 7);
      cands[d] = {1, 3, 9}; // 1 and 3 should be eliminated
      cands[e] = {2}; // 2 should be eliminated

      final h = SudokuTestHarness.make(cands);

      final strat = NakedTripleStrategy();
      final hint = strat.getHintFromClues(h.s, [a, b, c]);

      expect(hint, isNotNull, reason: 'Should detect a Naked Triple');
      expect(hint!.strategy, StrategyType.nakedTriple);
      expect(hint.unit, anyOf(HintUnit.row, HintUnit.column, HintUnit.box));
      expect(hint.cells.toSet(), {a, b, c});
      expect(hint.digits, [1, 2, 3]);

      // Eliminations expected at d: remove 1 and 3; at e: remove 2.
      final elims = hint.eliminations; // Set<(index, digit)>
      expect(elims[d], {1, 3});
      expect(elims[e], {2});

      // Ensure we never eliminate from the triple's own cells.
      expect(elims.containsKey(a), isFalse);
      expect(elims.containsKey(b), isFalse);
      expect(elims.containsKey(c), isFalse);
    });

    test('Naked Pair in a column produces eliminations in that column', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});

      // Column 4: pair at r2c5 and r8c5 with digits {5,7}.
      final p1 = idx(1, 4); // r2 c5
      final p2 = idx(7, 4); // r8 c5
      cands[p1] = {5, 7};
      cands[p2] = {5, 7};

      // Other cells in column 5 that contain 5 or 7 should be eliminated.
      final x = idx(0, 4); // r1 c5
      final y = idx(5, 4); // r6 c5
      cands[x] = {1, 5};
      cands[y] = {7, 9};

      final h = SudokuTestHarness.make(cands);

      final strat = NakedPairStrategy();
      final hint = strat.getHintFromClues(h.s, [p1, p2]);

      expect(hint, isNotNull, reason: 'Should detect a Naked Pair');
      expect(hint!.strategy, StrategyType.nakedPair);
      expect(hint.cells.toSet(), {p1, p2});
      expect(hint.digits.toSet(), {5, 7});

      final elims = hint.eliminations;
      expect(elims[x], {5});
      expect(elims[y], {7});
      // Never eliminate from the pair cells.
      expect(elims.containsKey(p1), isFalse);
      expect(elims.containsKey(p2), isFalse);
    });

    test('Naked Quad in a box produces eliminations inside that box', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});

      // Box (rows 3..5, cols 6..8) => box index 5 (zero-based):
      // use four cells with union {2,4,6,9}
      final q1 = idx(3, 6); // r4c7
      final q2 = idx(3, 8); // r4c9
      final q3 = idx(4, 6); // r5c7
      final q4 = idx(5, 7); // r6c8

      cands[q1] = {2, 4};
      cands[q2] = {6, 9};
      cands[q3] = {2, 6};
      cands[q4] = {4, 9};

      // A peer inside the same box containing digits from the quad
      final peer = idx(4, 8); // r5c9 in the same box
      cands[peer] = {1, 2, 9};

      final h = SudokuTestHarness.make(cands);

      final strat = NakedQuadStrategy();
      final hint = strat.getHintFromClues(h.s, [q1, q2, q3, q4]);

      expect(hint, isNotNull, reason: 'Should detect a Naked Quad');
      expect(hint!.strategy, StrategyType.nakedQuad);
      expect(hint.cells.toSet(), {q1, q2, q3, q4});
      expect(hint.digits.toSet(), {2, 4, 6, 9});

      final elims = hint.eliminations;
      expect(elims[peer], {2, 9});
      // Never eliminate from the quad cells.
      expect(elims.containsKey(q1), isFalse);
      expect(elims.containsKey(q2), isFalse);
      expect(elims.containsKey(q3), isFalse);
      expect(elims.containsKey(q4), isFalse);
    });
  });

  group('Naked findHint (Pair/Triple/Quad)', () {
    test('findHint: Naked Triple in a row', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});

      // Row 4 (zero-based): indices r4c1, r4c2, r4c3 form a triple {1,2,3}
      final a = idx(4, 1);
      final b = idx(4, 2);
      final c = idx(4, 3);
      cands[a] = {1, 2};
      cands[b] = {1, 3};
      cands[c] = {2, 3};

      // Other cells in row 4 to be cleaned up
      final peer1 = idx(4, 5);
      final peer2 = idx(4, 7);
      cands[peer1] = {1, 4, 9};
      cands[peer2] = {2};

      final h = SudokuTestHarness.make(cands);

      final strat = NakedTripleStrategy();
      final hint = strat.findHint(h.s);

      expect(hint, isNotNull, reason: 'Should find a Naked Triple in the row');
      expect(hint!.strategy, StrategyType.nakedTriple);
      expect(hint.unit, HintUnit.row);
      expect(hint.digits, [1, 2, 3]);
      final cells = hint.cells.toSet();
      expect(cells.length, 3);
      expect(cells.containsAll({a, b, c}), isTrue);

      final elims = hint.eliminations;
      expect(elims[peer1], {1});
      expect(elims[peer2], {2});
      expect(cells.any((c) => elims.containsKey(c)), isFalse);
    });

    test('findHint: Naked Pair in a column', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});

      // Column 6 (zero-based col=5): pair at r1c6 and r8c6 -> digits {5,7}
      final p1 = idx(0, 5);
      final p2 = idx(7, 5);
      cands[p1] = {5, 7};
      cands[p2] = {5, 7};

      // Peers in the same column with removable candidates
      final x = idx(2, 5); // contains 5
      final y = idx(5, 5); // contains 7
      cands[x] = {5, 9};
      cands[y] = {1, 7};

      final h = SudokuTestHarness.make(cands);
      final strat = NakedPairStrategy();
      final hint = strat.findHint(h.s);

      expect(hint, isNotNull, reason: 'Should find a Naked Pair in the column');
      expect(hint!.strategy, StrategyType.nakedPair);
      expect(hint.unit, HintUnit.column);
      expect(hint.digits.toSet(), {5, 7});
      final cells = hint.cells.toSet();
      expect(cells.length, 2);
      expect(cells.containsAll({p1, p2}), isTrue);

      final elims = hint.eliminations;
      expect(elims[x], {5});
      expect(elims[y], {7});
      expect(cells.any((c) => elims.containsKey(c)), isFalse);
    });

    test('findHint: Naked Quad in a box', () {
      final cands = List<Set<int>>.generate(81, (_) => <int>{});

      // Box (rows 6..8, cols 0..2) => bottom-left box
      final q1 = idx(6, 0);
      final q2 = idx(6, 2);
      final q3 = idx(7, 1);
      final q4 = idx(8, 2);
      cands[q1] = {2, 4};
      cands[q2] = {6, 9};
      cands[q3] = {2, 6};
      cands[q4] = {4, 9};

      // Another cell in the same box that has digits from the quad
      final peer = idx(7, 0);
      cands[peer] = {1, 2, 9};

      final h = SudokuTestHarness.make(cands);
      final strat = NakedQuadStrategy();
      final hint = strat.findHint(h.s);

      expect(hint, isNotNull, reason: 'Should find a Naked Quad in the box');
      expect(hint!.strategy, StrategyType.nakedQuad);
      expect(hint.unit, HintUnit.box);
      expect(hint.digits.toSet(), {2, 4, 6, 9});
      final cells = hint.cells.toSet();
      expect(cells.length, 4);
      expect(cells.containsAll({q1, q2, q3, q4}), isTrue);

      final elims = hint.eliminations;
      expect(elims[peer], {2, 9});
      expect(cells.any((c) => elims.containsKey(c)), isFalse);
    });
  });
}
