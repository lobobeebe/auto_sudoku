import '../difficulty.dart';
import '../hint.dart';
import '../sudoku.dart';
import 'strategy.dart';

/// Wing strategies: X-Wing, XY-Wing, W-Wing.
///
/// Conventions:
/// - Indices are 0..80 into Sudoku.cells.
/// - Hint.eliminations is a Map int -> Set (cell -> digits removed).
/// - Hint.placements (when used) is a Map int -> int (cell -> digit).
/// - `cells` in the Hint usually list the key pattern cells (e.g., 4 corners of X-Wing,
///   pivot+pincers for XY-Wing, two bivalue cells + the two strong-link cells for W-Wing).

Map<int, Set<int>> _elimMapAdd(Map<int, Set<int>> m, int idx, int d) {
  m.putIfAbsent(idx, () => <int>{});
  m[idx]!.add(d);
  return m;
}

// ---------------------------------------------------------------------------
// X-Wing
// ---------------------------------------------------------------------------
class XWingStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.xWing;

  @override
  Difficulty get difficulty => Difficulty.medium;

  @override
  Hint? findHint(Sudoku s) {
    // Try row-based X-Wing (lock columns), then column-based (lock rows).
    for (var d = 1; d <= 9; d++) {
      final hRow = _xWingRows(s, d);
      if (hRow != null) return hRow;
      final hCol = _xWingCols(s, d);
      if (hCol != null) return hCol;
    }
    return null;
  }

  Hint? _xWingRows(Sudoku s, int d) {
    final rowsWith2 =
        <int, List<int>>{}; // r -> columns where d appears (len==2)
    for (var r = 0; r < 9; r++) {
      final cols = <int>[];
      for (final idx in s.rowIndices(r)) {
        if (s.isEmpty(idx) && s.hasNote(idx, d)) {
          cols.add(s.colOf(idx));
        }
      }
      if (cols.length == 2) {
        cols.sort();
        rowsWith2[r] = cols;
      }
    }
    final rows = rowsWith2.keys.toList();
    for (var i = 0; i < rows.length; i++) {
      for (var j = i + 1; j < rows.length; j++) {
        final r1 = rows[i], r2 = rows[j];
        final cpair1 = rowsWith2[r1]!;
        final cpair2 = rowsWith2[r2]!;
        if (cpair1[0] == cpair2[0] && cpair1[1] == cpair2[1]) {
          final cA = cpair1[0], cB = cpair1[1];
          // Eliminate d from other rows in these two columns
          final elim = <int, Set<int>>{};
          for (var r = 0; r < 9; r++) {
            if (r == r1 || r == r2) continue;
            final iA = r * 9 + cA;
            final iB = r * 9 + cB;
            if (s.isEmpty(iA) && s.hasNote(iA, d)) {
              _elimMapAdd(elim, iA, d);
            }
            if (s.isEmpty(iB) && s.hasNote(iB, d)) {
              _elimMapAdd(elim, iB, d);
            }
          }
          if (elim.isNotEmpty) {
            final corners = <int>{
              r1 * 9 + cA,
              r1 * 9 + cB,
              r2 * 9 + cA,
              r2 * 9 + cB,
            };
            return Hint(
              StrategyType.xWing,
              eliminations: elim,
              cells: corners.toList(),
              digits: [d],
              unit: HintUnit.column, // eliminations happen along columns
            );
          }
        }
      }
    }
    return null;
  }

  Hint? _xWingCols(Sudoku s, int d) {
    final colsWith2 = <int, List<int>>{}; // c -> rows where d appears (len==2)
    for (var c = 0; c < 9; c++) {
      final rows = <int>[];
      for (final idx in s.colIndices(c)) {
        if (s.isEmpty(idx) && s.hasNote(idx, d)) {
          rows.add(s.rowOf(idx));
        }
      }
      if (rows.length == 2) {
        rows.sort();
        colsWith2[c] = rows;
      }
    }
    final cols = colsWith2.keys.toList();
    for (var i = 0; i < cols.length; i++) {
      for (var j = i + 1; j < cols.length; j++) {
        final c1 = cols[i], c2 = cols[j];
        final rpair1 = colsWith2[c1]!;
        final rpair2 = colsWith2[c2]!;
        if (rpair1[0] == rpair2[0] && rpair1[1] == rpair2[1]) {
          final rA = rpair1[0], rB = rpair1[1];
          // Eliminate d from other columns in these two rows
          final elim = <int, Set<int>>{};
          for (var c = 0; c < 9; c++) {
            if (c == c1 || c == c2) continue;
            final iA = rA * 9 + c;
            final iB = rB * 9 + c;
            if (s.isEmpty(iA) && s.hasNote(iA, d)) {
              _elimMapAdd(elim, iA, d);
            }
            if (s.isEmpty(iB) && s.hasNote(iB, d)) {
              _elimMapAdd(elim, iB, d);
            }
          }
          if (elim.isNotEmpty) {
            final corners = <int>{
              rA * 9 + c1,
              rA * 9 + c2,
              rB * 9 + c1,
              rB * 9 + c2,
            };
            return Hint(
              StrategyType.xWing,
              eliminations: elim,
              cells: corners.toList(),
              digits: [d],
              unit: HintUnit.row, // eliminations happen along rows
            );
          }
        }
      }
    }
    return null;
  }

  @override
  Hint? getHintFromClues(Sudoku s, List<int> indices) {
    if (indices.length != 4) return null;

    // Derive the two rows and two cols implied by the four corners.
    final rows = indices.map((i) => i ~/ 9).toSet().toList();
    final cols = indices.map((i) => i % 9).toSet().toList();
    if (rows.length != 2 || cols.length != 2) return null;

    // Consider only digits present in all four corners.
    Set<int> common = s.notesSet(indices[0]);
    for (final i in indices.skip(1)) {
      common = common.intersection(s.notesSet(i));
    }
    if (common.isEmpty) return null;

    // Helper validators for the X-Wing constraint.
    bool rowsHaveExactlyTheseTwoColsForDigit(int d) {
      for (final r in rows) {
        final colsWithD = <int>[];
        for (final c in Iterable<int>.generate(9)) {
          final idx = r * 9 + c;
          if (s.isEmpty(idx) && s.hasNote(idx, d)) colsWithD.add(c);
        }
        colsWithD.sort();
        final wanted = [...cols]..sort();
        if (colsWithD.length != 2 ||
            colsWithD[0] != wanted[0] ||
            colsWithD[1] != wanted[1]) {
          return false;
        }
      }
      return true;
    }

    bool colsHaveExactlyTheseTwoRowsForDigit(int d) {
      for (final c in cols) {
        final rowsWithD = <int>[];
        for (final r in Iterable<int>.generate(9)) {
          final idx = r * 9 + c;
          if (s.isEmpty(idx) && s.hasNote(idx, d)) rowsWithD.add(r);
        }
        rowsWithD.sort();
        final wanted = [...rows]..sort();
        if (rowsWithD.length != 2 ||
            rowsWithD[0] != wanted[0] ||
            rowsWithD[1] != wanted[1]) {
          return false;
        }
      }
      return true;
    }

    // Try each common digit; prefer whichever yields valid eliminations.
    for (final d in common.toList()..sort()) {
      // Row-based X-Wing (lock columns)
      if (rowsHaveExactlyTheseTwoColsForDigit(d)) {
        final elim = <int, Set<int>>{};
        for (var r = 0; r < 9; r++) {
          if (r == rows[0] || r == rows[1]) continue;
          for (final c in cols) {
            final idx = r * 9 + c;
            if (s.isEmpty(idx) && s.hasNote(idx, d)) {
              (elim[idx] ??= <int>{}).add(d);
            }
          }
        }
        if (elim.isNotEmpty) {
          final corners = <int>{
            rows[0] * 9 + cols[0],
            rows[0] * 9 + cols[1],
            rows[1] * 9 + cols[0],
            rows[1] * 9 + cols[1],
          };
          return Hint(
            StrategyType.xWing,
            eliminations: elim,
            cells: corners.toList(),
            digits: [d],
            unit: HintUnit.column,
          );
        }
      }

      // Column-based X-Wing (lock rows)
      if (colsHaveExactlyTheseTwoRowsForDigit(d)) {
        final elim = <int, Set<int>>{};
        for (var c = 0; c < 9; c++) {
          if (c == cols[0] || c == cols[1]) continue;
          for (final r in rows) {
            final idx = r * 9 + c;
            if (s.isEmpty(idx) && s.hasNote(idx, d)) {
              (elim[idx] ??= <int>{}).add(d);
            }
          }
        }
        if (elim.isNotEmpty) {
          final corners = <int>{
            rows[0] * 9 + cols[0],
            rows[0] * 9 + cols[1],
            rows[1] * 9 + cols[0],
            rows[1] * 9 + cols[1],
          };
          return Hint(
            StrategyType.xWing,
            eliminations: elim,
            cells: corners.toList(),
            digits: [d],
            unit: HintUnit.row,
          );
        }
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// XY-Wing
// ---------------------------------------------------------------------------
class XYWingStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.xyWing;

  @override
  Difficulty get difficulty => Difficulty.medium;

  @override
  Hint? findHint(Sudoku s) {
    // For each pivot (bivalue), look for two pincers (bivalue) that see the pivot
    // with patterns {a,b} (pivot), {a,c} and {b,c}. Eliminate c from cells that
    // see both pincers.
    final bivals = s.bivalIndices();

    for (final pivot in bivals) {
      final pv = s.notesSet(pivot).toList()..sort();
      final a = pv[0], b = pv[1];
      final pivotPeers = s.peersOf(pivot);

      // Map c -> pincer list for {a,c} and {b,c}
      final pincersA = <int, List<int>>{}; // c -> indices
      final pincersB = <int, List<int>>{};

      for (final q in pivotPeers) {
        if (!s.isEmpty(q)) continue;
        final qs = s.notesSet(q);
        if (qs.length == 2) {
          if (qs.contains(a)) {
            final c = (qs.firstWhere((d) => d != a));
            (pincersA[c] ??= <int>[]).add(q);
          }
          if (qs.contains(b)) {
            final c = (qs.firstWhere((d) => d != b));
            (pincersB[c] ??= <int>[]).add(q);
          }
        }
      }

      for (var c = 1; c <= 9; c++) {
        final listA = pincersA[c];
        final listB = pincersB[c];
        if (listA == null || listB == null) continue;
        for (final p1 in listA) {
          for (final p2 in listB) {
            if (p1 == p2) continue; // need two distinct pincers
            // Cells that see both p1 and p2 get c eliminated.
            final elim = <int, Set<int>>{};
            final peersBoth = s.peersOf(p1).intersection(s.peersOf(p2));
            for (final idx in peersBoth) {
              if (s.isEmpty(idx) && s.hasNote(idx, c)) {
                _elimMapAdd(elim, idx, c);
              }
            }
            if (elim.isNotEmpty) {
              return Hint(
                StrategyType.xyWing,
                eliminations: elim,
                cells: [pivot, p1, p2],
                digits: [a, b, c]..sort(),
                unit: null,
              );
            }
          }
        }
      }
    }
    return null;
  }

  @override
  Hint? getHintFromClues(Sudoku s, List<int> indices) {
    if (indices.length != 3) return null;

    // All permutations of 3 items
    const perms = [
      [0, 1, 2],
      [0, 2, 1],
      [1, 0, 2],
      [1, 2, 0],
      [2, 0, 1],
      [2, 1, 0],
    ];

    for (final p in perms) {
      final pivot = indices[p[0]];
      final p1 = indices[p[1]];
      final p2 = indices[p[2]];

      // Must be unsolved
      if (!s.isEmpty(pivot) || !s.isEmpty(p1) || !s.isEmpty(p2)) {
        continue;
      }

      // Must be bivalue
      final pv = s.notesSet(pivot);
      final s1 = s.notesSet(p1);
      final s2 = s.notesSet(p2);
      if (pv.length != 2 || s1.length != 2 || s2.length != 2) {
        continue;
      }

      // Pincers must see the pivot
      final pivotPeers = s.peersOf(pivot);
      if (!pivotPeers.contains(p1) || !pivotPeers.contains(p2)) {
        continue;
      }

      // pincers must not be the same candidate set
      final pincersIdentical =
          (s1.length == s2.length) && s1.containsAll(s2) && s2.containsAll(s1);
      if (pincersIdentical) {
        continue;
      }

      // pivot = {a,b}
      final pvList = pv.toList()..sort();
      final a = pvList[0], b = pvList[1];

      // Each pincer must share exactly one value with the pivot
      final inter1 = s1.intersection(pv);
      final inter2 = s2.intersection(pv);
      if (inter1.length != 1 || inter2.length != 1) {
        continue;
      }

      // The "other" value in each pincer must match and be != a,b
      final c1 = (s1.difference(pv)).toList();
      final c2 = (s2.difference(pv)).toList();
      if (c1.length != 1 || c2.length != 1) continue;
      final c = c1.first;
      if (c != c2.first || c == a || c == b) continue;

      // Eliminate c from cells that see BOTH pincers
      final peersBoth = s.peersOf(p1).intersection(s.peersOf(p2));
      final elim = <int, Set<int>>{};
      for (final idx in peersBoth) {
        if (s.isEmpty(idx) && s.hasNote(idx, c)) {
          _elimMapAdd(elim, idx, c);
        }
      }
      if (elim.isEmpty) continue;

      // Build the hint
      final digs = [a, b, c]..sort();
      return Hint(
        StrategyType.xyWing,
        eliminations: elim,
        cells: [pivot, p1, p2],
        digits: digs,
        unit: null,
      );
    }

    return null;
  }
}

// ---------------------------------------------------------------------------
// W-Wing (two identical bivalue cells {x,y} + strong link on x along a line)
// ---------------------------------------------------------------------------
class WWingStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.wWing;

  @override
  Difficulty get difficulty => Difficulty.hard;

  @override
  Hint? findHint(Sudoku s) {
    // Collect all bivalue cells
    final bivals = s.bivalIndices();

    // Fast peer lookups (avoid recomputing)
    List<Set<int>> peerCache = List.generate(81, (i) => s.peersOf(i));

    bool sees(int u, int v) => peerCache[u].contains(v);
    bool sameHouse(int u, int v) =>
        sees(u, v); // they "see" if share row/col/box

    // Utility to try a family of strong links (row/col/box)
    Iterable<List<int>> strongLinksForDigit(int d) sync* {
      // rows
      for (final link in _findStrongLinkOnLine(s, d, byRow: true)) {
        yield link;
      }
      // cols
      for (final link in _findStrongLinkOnLine(s, d, byRow: false)) {
        yield link;
      }
      // boxes (you'll need to implement this to return [end1,end2] pairs)
      for (final link in _findStrongLinkInBoxes(s, d)) {
        yield link;
      }
    }

    for (var i = 0; i < bivals.length; i++) {
      for (var j = i + 1; j < bivals.length; j++) {
        final a = bivals[i], b = bivals[j];
        final sA = s.notesSet(a), sB = s.notesSet(b);
        if (sA.length != 2 || sB.length != 2) continue;
        if (!sA.containsAll(sB)) continue;

        // W-Wing requires A and B do NOT see each other
        if (sameHouse(a, b)) continue;

        final pair = sA.toList()..sort();
        final x = pair[0], y = pair[1];

        // Try both possibilities: strong link on x (eliminate y) and on y (eliminate x)
        for (final linkDigit in [x, y]) {
          final elimDigit = (linkDigit == x) ? y : x;

          for (final link in strongLinksForDigit(linkDigit)) {
            final end1 = link[0], end2 = link[1];

            // Endpoints must be distinct from A/B
            if (end1 == a || end2 == a || end1 == b || end2 == b) continue;

            // Each bivalue must align with a different endpoint of the conjugate pair
            final aEnd1 = sees(a, end1), aEnd2 = sees(a, end2);
            final bEnd1 = sees(b, end1), bEnd2 = sees(b, end2);

            final crosses =
                (aEnd1 && bEnd2) || (aEnd2 && bEnd1); // <-- critical correction
            if (!crosses) continue;

            // Compute eliminations: cells that see BOTH A and B and contain elimDigit
            final elim = _wWingElims(s, a, b, elimDigit);
            if (elim.isEmpty) continue;

            return Hint(
              StrategyType.wWing,
              eliminations: elim,
              cells: [a, b, end1, end2],
              digits: [x, y]..sort(),
            );
          }
        }
      }
    }
    return null;
  }

  /// Returns all conjugate (strong) links for digit `d` inside 3×3 boxes.
  /// Each entry is a pair [end1, end2] of cell indices in the same box.
  List<List<int>> _findStrongLinkInBoxes(Sudoku s, int d) {
    final links = <List<int>>[];

    for (var box = 0; box < 9; box++) {
      final startRow = (box ~/ 3) * 3;
      final startCol = (box % 3) * 3;

      // Collect all indices in this box where `d` is a candidate
      final locs = <int>[];
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          final row = startRow + r;
          final col = startCol + c;
          final idx = row * 9 + col;

          if (s.isEmpty(idx) && s.hasNote(idx, d)) {
            locs.add(idx);
          }
        }
      }

      // Strong link exists iff exactly two candidate locations in the box
      if (locs.length == 2) {
        links.add([locs[0], locs[1]]);
      }
    }

    return links;
  }

  /// Returns list of strong-links for digit d on each row/column.
  /// Each entry is a List int of length 2 containing the two cell indices.
  List<List<int>> _findStrongLinkOnLine(
    Sudoku s,
    int d, {
    required bool byRow,
  }) {
    final result = <List<int>>[];
    if (byRow) {
      for (var r = 0; r < 9; r++) {
        final cells = <int>[];
        for (final i in s.rowIndices(r)) {
          if (s.isEmpty(i) && s.hasNote(i, d)) cells.add(i);
        }
        if (cells.length == 2) result.add(cells);
      }
    } else {
      for (var c = 0; c < 9; c++) {
        final cells = <int>[];
        for (final i in s.colIndices(c)) {
          if (s.isEmpty(i) && s.hasNote(i, d)) cells.add(i);
        }
        if (cells.length == 2) result.add(cells);
      }
    }
    return result;
  }

  Map<int, Set<int>> _wWingElims(Sudoku s, int a, int b, int eliminateDigit) {
    final elim = <int, Set<int>>{};
    final common = s.peersOf(a).intersection(s.peersOf(b));
    for (final idx in common) {
      if (s.isEmpty(idx) && s.hasNote(idx, eliminateDigit)) {
        _elimMapAdd(elim, idx, eliminateDigit);
      }
    }
    return elim;
  }

  @override
  Hint? getHintFromClues(Sudoku s, List<int> indices) {
    // REQUIREMENT: callers must supply two bivalue {x,y} cells *and* two endpoint cells that form a strong link on x or y.
    if (indices.length < 4) return null;

    // Keep only unsolved cells from clues.
    final clues = indices.where((i) => s.isEmpty(i)).toList();
    if (clues.length < 4) return null;

    // Find any pair among clues that are identical bivalue sets {x,y}.
    int? a, b; // the two bivalue cells
    Set<int>? pairSet;
    for (var i = 0; i < clues.length; i++) {
      final ci = clues[i];
      final si = s.notesSet(ci);
      if (si.length != 2) continue;
      for (var j = i + 1; j < clues.length; j++) {
        final cj = clues[j];
        final sj = s.notesSet(cj);
        if (sj.length != 2) continue;
        if (si.length == sj.length &&
            si.containsAll(sj) &&
            sj.containsAll(si)) {
          a = ci;
          b = cj;
          pairSet = si;
          break;
        }
      }
      if (a != null) break;
    }
    if (a == null || b == null || pairSet == null) return null;

    final pair = pairSet.toList()..sort();
    int x = pair[0];
    int y = pair[1];

    // Helper to validate two endpoints form a strong link on digit d.
    bool isStrongLink(int e1, int e2, int d) {
      if (e1 == e2) return false; // Must not be same index
      if (!s.isEmpty(e1) || !s.isEmpty(e2)) return false; // Both must be empty
      if (!s.hasNote(e1, d) || !s.hasNote(e2, d)) {
        return false; // Both cells must have d
      }
      final r1 = s.rowOf(e1), c1 = s.colOf(e1);
      final r2 = s.rowOf(e2), c2 = s.colOf(e2);
      if (r1 == r2) {
        // same row: d must appear exactly twice in that row
        var cnt = 0;
        int last1 = -1, last2 = -1;
        for (final i in s.rowIndices(r1)) {
          if (s.isEmpty(i) && s.hasNote(i, d)) {
            cnt++;
            if (last1 == -1) {
              last1 = i;
            } else {
              last2 = i;
            }
          }
        }
        if (cnt == 2 &&
            ((last1 == e1 && last2 == e2) || (last1 == e2 && last2 == e1))) {
          return true;
        }
      } else if (c1 == c2) {
        // same column: d must appear exactly twice in that column
        var cnt = 0;
        int last1 = -1, last2 = -1;
        for (final i in s.colIndices(c1)) {
          if (s.isEmpty(i) && s.hasNote(i, d)) {
            cnt++;
            if (last1 == -1) {
              last1 = i;
            } else {
              last2 = i;
            }
          }
        }
        if (cnt == 2 &&
            ((last1 == e1 && last2 == e2) || (last1 == e2 && last2 == e1))) {
          return true;
        }
      } else if (s.boxOf(e1) == s.boxOf(e2)) {
        // same box: d must appear exactly twice in that box
        var cnt = 0;
        int last1 = -1, last2 = -1;
        final box = s.boxOf(e1);
        for (final i in s.boxIndices(box)) {
          if (s.isEmpty(i) && s.hasNote(i, d)) {
            cnt++;
            if (last1 == -1) {
              last1 = i;
            } else {
              last2 = i;
            }
          }
        }
        if (cnt == 2 &&
            ((last1 == e1 && last2 == e2) || (last1 == e2 && last2 == e1))) {
          return true;
        }
      }
      return false;
    }

    // Compute eliminations for a,b given the elimination digit.
    Map<int, Set<int>> elimFor(int eliminateDigit) =>
        _wWingElims(s, a!, b!, eliminateDigit);

    // Remaining indices are potential endpoints (0..n). Try to validate if we have at least two.
    final remaining = clues.where((i) => i != a && i != b).toList();
    if (remaining.length >= 2) {
      // Try all pairs of remaining as strong link on x or y.
      for (var i = 0; i < remaining.length; i++) {
        for (var j = i + 1; j < remaining.length; j++) {
          final e1 = remaining[i], e2 = remaining[j];
          // Check strong link on x -> eliminate y
          if (isStrongLink(e1, e2, x)) {
            final aEnd1 = s.peersOf(a).contains(e1);
            final aEnd2 = s.peersOf(a).contains(e2);
            final bEnd1 = s.peersOf(b).contains(e1);
            final bEnd2 = s.peersOf(b).contains(e2);
            final crosses = (aEnd1 && bEnd2) || (aEnd2 && bEnd1);
            if (crosses) {
              final elim = elimFor(y);
              if (elim.isNotEmpty) {
                final unit = (s.rowOf(e1) == s.rowOf(e2))
                    ? HintUnit.row
                    : (s.colOf(e1) == s.colOf(e2))
                    ? HintUnit.column
                    : HintUnit.box;
                return Hint(
                  StrategyType.wWing,
                  eliminations: elim,
                  cells: [a, b, e1, e2],
                  digits: [x, y]..sort(),
                  unit: unit,
                );
              }
            }
          }
          // Or strong link on y -> eliminate x
          if (isStrongLink(e1, e2, y)) {
            final aEnd1 = s.peersOf(a).contains(e1);
            final aEnd2 = s.peersOf(a).contains(e2);
            final bEnd1 = s.peersOf(b).contains(e1);
            final bEnd2 = s.peersOf(b).contains(e2);
            final crosses = (aEnd1 && bEnd2) || (aEnd2 && bEnd1);
            if (crosses) {
              final elim = elimFor(x);
              if (elim.isNotEmpty) {
                final unit = (s.rowOf(e1) == s.rowOf(e2))
                    ? HintUnit.row
                    : (s.colOf(e1) == s.colOf(e2))
                    ? HintUnit.column
                    : HintUnit.box;
                return Hint(
                  StrategyType.wWing,
                  eliminations: elim,
                  cells: [a, b, e1, e2],
                  digits: [x, y]..sort(),
                  unit: unit,
                );
              }
            }
          }
        }
      }
      // Endpoints required: do not auto-discover.
      return null;
    }

    return null;
  }
}
