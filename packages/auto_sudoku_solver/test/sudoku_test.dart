import 'package:test/test.dart';

import 'package:auto_sudoku_solver/src/sudoku.dart';
import 'package:auto_sudoku_solver/src/hint.dart';
import 'package:auto_sudoku_solver/src/strategy/strategy.dart';

int idx(int r, int c) => r * 9 + c;

void main() {
  group('Sudoku core helpers', () {
    test('isValidIndex bounds', () {
      expect(Sudoku.isValidIndex(-1), isFalse);
      expect(Sudoku.isValidIndex(0), isTrue);
      expect(Sudoku.isValidIndex(80), isTrue);
      expect(Sudoku.isValidIndex(81), isFalse);
    });

    test('row/col/box mapping', () {
      final i = idx(4, 7); // r=4,c=7
      final s = Sudoku(List.filled(81, 0));
      expect(s.rowOf(i), 4);
      expect(s.colOf(i), 7);
      expect(s.boxOf(i), 5); // (4~/3)*3 + (7~/3) = 5
    });

    test('peersOf count and excludes self', () {
      final s = Sudoku(List.filled(81, 0));
      final i = idx(4, 4);
      final peers = s.peersOf(i);
      expect(peers.contains(i), isFalse);
      // Standard Sudoku has 20 unique peers per cell
      expect(peers.length, 20);
    });
  });

  group('Notes and mutations', () {
    test('notesSet and setNote toggle', () {
      final notes = List<Set<int>>.generate(81, (_) => <int>{});
      notes[10] = {1, 3, 5};
      final s = Sudoku(List.filled(81, 0), notes: notes);
      expect(s.notesSet(10), {1, 3, 5});

      // Remove a note
      expect(s.setNote(10, 3, false), isTrue);
      expect(s.notesSet(10), {1, 5});

      // Add a note
      expect(s.setNote(10, 9, true), isTrue);
      expect(s.notesSet(10), {1, 5, 9});
    });

    test('applyHint places value, clears notes, and removes from peers', () {
      final A = idx(0, 0);
      final B = idx(0, 5); // peer in same row

      final notes = List<Set<int>>.generate(81, (_) => <int>{});
      notes[A] = {5, 7};
      notes[B] = {1, 5, 9};
      final s = Sudoku(List.filled(81, 0), notes: notes);

      final hint = Hint(
        StrategyType.nakedSingle,
        placements: {A: 5},
        eliminations: {B: {1}},
      );

      final changed = s.applyHint(hint);
      expect(changed.isNotEmpty, isTrue);
      expect(s.valueAt(A), 5);
      expect(s.notesMaskAt(A), 0);
      // 5 removed from B due to peer elimination; 1 removed due to explicit elimination
      expect(s.hasNote(B, 5), isFalse);
      expect(s.hasNote(B, 1), isFalse);
    });

    test('removeFromPeers clears candidate across all peers', () {
      final s = Sudoku(List.filled(81, 0)); // auto-compute notes for empty grid
      final i = idx(4, 4);
      final peers = s.peersOf(i);

      // Ensure candidate 7 is present initially for all empties
      for (final p in peers) {
        expect(s.hasNote(p, 7), isTrue);
      }

      final mutated = s.removeFromPeers(i, 7);
      expect(mutated.toSet(), peers);
      for (final p in peers) {
        expect(s.hasNote(p, 7), isFalse);
      }

      // idempotent on second call
      final mutatedAgain = s.removeFromPeers(i, 7);
      expect(mutatedAgain, isEmpty);
    });
  });

  group('Placement validity and solved state', () {
    test('isValidPlacement respects row/col/box', () {
      final s = Sudoku(List.filled(81, 0));
      // Place a 5 at (0,0)
      s.setValue(idx(0, 0), 5);

      expect(s.isValidPlacement(idx(0, 1), 5), isFalse, reason: 'same row');
      expect(s.isValidPlacement(idx(1, 0), 5), isFalse, reason: 'same col');
      expect(s.isValidPlacement(idx(1, 1), 5), isFalse, reason: 'same box');
      expect(s.isValidPlacement(idx(4, 4), 5), isTrue, reason: 'non-peer cell');
    });

    test('isSolved and isGridSolved', () {
      // Known valid solved grid (row-major)
      final solved = <int>[
        2, 5, 9, 1, 7, 8, 4, 6, 3,
        1, 7, 6, 3, 9, 4, 8, 5, 2,
        4, 8, 3, 2, 5, 6, 9, 7, 1,
        3, 9, 7, 5, 4, 1, 2, 8, 6,
        8, 4, 1, 6, 2, 7, 5, 3, 9,
        5, 6, 2, 9, 8, 3, 7, 1, 4,
        7, 3, 4, 8, 1, 2, 6, 9, 5,
        9, 1, 8, 4, 6, 5, 3, 2, 7,
        6, 2, 5, 7, 3, 9, 1, 4, 8,
      ];
      final s = Sudoku(List.from(solved));
      expect(s.isSolved, isTrue);
      expect(Sudoku.isGridSolved(solved), isTrue);

      s.resetValue(idx(0, 0));
      expect(s.isSolved, isFalse);
      expect(Sudoku.isGridSolved(s.grid), isFalse);
    });
  });
}

