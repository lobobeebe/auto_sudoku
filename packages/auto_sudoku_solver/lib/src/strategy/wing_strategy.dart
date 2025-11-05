import '../candidate_map.dart';
import '../difficulty.dart';
import '../hint.dart';
import '../sudoku.dart';
import 'strategy.dart';

/// Wing strategies: X-Wing, XY-Wing, W-Wing.
///
/// Conventions:
/// - Indices are 0..80 into Sudoku.cells.
/// - Hint.eliminations is a Map<int, Set<int>> (cell -> digits removed).
/// - Hint.placements (when used) is a Map<int, int> (cell -> digit).
/// - `cells` in the Hint usually list the key pattern cells (e.g., 4 corners of X-Wing,
///   pivot+pincers for XY-Wing, two bivalue cells + the two strong-link cells for W-Wing).

int _rowOf(int i) => i ~/ 9;
int _colOf(int i) => i % 9;
int _boxOf(int i) => (_rowOf(i) ~/ 3) * 3 + (_colOf(i) ~/ 3);

Iterable<int> _rowCells(int r) sync* {
  for (var c = 0; c < 9; c++) {
    yield r * 9 + c;
  }
}

Iterable<int> _colCells(int c) sync* {
  for (var r = 0; r < 9; r++) {
    yield r * 9 + c;
  }
}

Iterable<int> _boxCells(int b) sync* {
  final br = (b ~/ 3) * 3;
  final bc = (b % 3) * 3;
  for (var r = br; r < br + 3; r++) {
    for (var c = bc; c < bc + 3; c++) {
      yield r * 9 + c;
    }
  }
}

Set<int> _peers(Sudoku s, int i) {
  final r = _rowOf(i);
  final c = _colOf(i);
  final b = _boxOf(i);
  final out = <int>{};
  out.addAll(_rowCells(r));
  out.addAll(_colCells(c));
  out.addAll(_boxCells(b));
  out.remove(i);
  return out;
}

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
  Hint? findHint(Sudoku s, CandidateMap cand) {
    // Try row-based X-Wing (lock columns), then column-based (lock rows).
    for (var d = 1; d <= 9; d++) {
      final hRow = _xWingRows(s, cand, d);
      if (hRow != null) return hRow;
      final hCol = _xWingCols(s, cand, d);
      if (hCol != null) return hCol;
    }
    return null;
  }

  Hint? _xWingRows(Sudoku s, CandidateMap cand, int d) {
    final rowsWith2 =
        <int, List<int>>{}; // r -> columns where d appears (len==2)
    for (var r = 0; r < 9; r++) {
      final cols = <int>[];
      for (final idx in s.rowIndices(r)) {
        if (s.cells[idx] == 0 && cand[idx].contains(d)) cols.add(_colOf(idx));
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
            if (s.cells[iA] == 0 && cand[iA].contains(d))
              _elimMapAdd(elim, iA, d);
            if (s.cells[iB] == 0 && cand[iB].contains(d))
              _elimMapAdd(elim, iB, d);
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

  Hint? _xWingCols(Sudoku s, CandidateMap cand, int d) {
    final colsWith2 = <int, List<int>>{}; // c -> rows where d appears (len==2)
    for (var c = 0; c < 9; c++) {
      final rows = <int>[];
      for (final idx in s.colIndices(c)) {
        if (s.cells[idx] == 0 && cand[idx].contains(d)) rows.add(_rowOf(idx));
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
            if (s.cells[iA] == 0 && cand[iA].contains(d))
              _elimMapAdd(elim, iA, d);
            if (s.cells[iB] == 0 && cand[iB].contains(d))
              _elimMapAdd(elim, iB, d);
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
  Hint? getHintFromClues(Sudoku s, CandidateMap cand, List<int> indices) {
    if (indices.length != 4) return null;

    // Derive the two rows and two cols implied by the four corners.
    final rows = indices.map((i) => i ~/ 9).toSet().toList();
    final cols = indices.map((i) => i % 9).toSet().toList();
    if (rows.length != 2 || cols.length != 2) return null;

    // Consider only digits present in all four corners.
    Set<int> common = cand[indices[0]].toSet();
    for (final i in indices.skip(1)) {
      common = common.intersection(cand[i]);
    }
    if (common.isEmpty) return null;

    // Helper validators for the X-Wing constraint.
    bool _rowsHaveExactlyTheseTwoColsForDigit(int d) {
      for (final r in rows) {
        final colsWithD = <int>[];
        for (final c in Iterable<int>.generate(9)) {
          final idx = r * 9 + c;
          if (s.cells[idx] == 0 && cand[idx].contains(d)) colsWithD.add(c);
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

    bool _colsHaveExactlyTheseTwoRowsForDigit(int d) {
      for (final c in cols) {
        final rowsWithD = <int>[];
        for (final r in Iterable<int>.generate(9)) {
          final idx = r * 9 + c;
          if (s.cells[idx] == 0 && cand[idx].contains(d)) rowsWithD.add(r);
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
      if (_rowsHaveExactlyTheseTwoColsForDigit(d)) {
        final elim = <int, Set<int>>{};
        for (var r = 0; r < 9; r++) {
          if (r == rows[0] || r == rows[1]) continue;
          for (final c in cols) {
            final idx = r * 9 + c;
            if (s.cells[idx] == 0 && cand[idx].contains(d)) {
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
      if (_colsHaveExactlyTheseTwoRowsForDigit(d)) {
        final elim = <int, Set<int>>{};
        for (var c = 0; c < 9; c++) {
          if (c == cols[0] || c == cols[1]) continue;
          for (final r in rows) {
            final idx = r * 9 + c;
            if (s.cells[idx] == 0 && cand[idx].contains(d)) {
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
  Hint? findHint(Sudoku s, CandidateMap cand) {
    // For each pivot (bivalue), look for two pincers (bivalue) that see the pivot
    // with patterns {a,b} (pivot), {a,c} and {b,c}. Eliminate c from cells that
    // see both pincers.
    final bivals = <int>[];
    for (var i = 0; i < 81; i++) {
      if (s.cells[i] != 0) continue;
      if (cand[i].length == 2) bivals.add(i);
    }

    for (final pivot in bivals) {
      final pv = cand[pivot].toList()..sort();
      final a = pv[0], b = pv[1];
      final pivotPeers = _peers(s, pivot);

      // Map c -> pincer list for {a,c} and {b,c}
      final pincersA = <int, List<int>>{}; // c -> indices
      final pincersB = <int, List<int>>{};

      for (final q in pivotPeers) {
        if (s.cells[q] != 0) continue;
        final qs = cand[q];
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
            final peersBoth = _peers(s, p1).intersection(_peers(s, p2));
            for (final idx in peersBoth) {
              if (s.cells[idx] == 0 && cand[idx].contains(c)) {
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
  Hint? getHintFromClues(Sudoku s, CandidateMap cand, List<int> indices) {
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
      if (s.cells[pivot] != 0 || s.cells[p1] != 0 || s.cells[p2] != 0) {
        continue;
      }

      // Must be bivalue
      final pv = cand[pivot];
      final s1 = cand[p1];
      final s2 = cand[p2];
      if (pv.length != 2 || s1.length != 2 || s2.length != 2) {
        continue;
      }

      // Pincers must see the pivot
      final pivotPeers = _peers(s, pivot);
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
      final peersBoth = _peers(s, p1).intersection(_peers(s, p2));
      final elim = <int, Set<int>>{};
      for (final idx in peersBoth) {
        if (s.cells[idx] == 0 && cand[idx].contains(c)) {
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
  Hint? findHint(Sudoku s, CandidateMap cand) {
    // Collect all bivalue cells
    final bivals = <int>[];
    for (var i = 0; i < 81; i++) {
      if (s.cells[i] == 0 && cand[i].length == 2) bivals.add(i);
    }

    // Consider each unordered pair of bivalue cells with same pair {x,y}
    for (var aIdx = 0; aIdx < bivals.length; aIdx++) {
      for (var bIdx = aIdx + 1; bIdx < bivals.length; bIdx++) {
        final a = bivals[aIdx];
        final b = bivals[bIdx];
        final sA = cand[a];
        final sB = cand[b];
        if (sA.length != 2 || sB.length != 2) continue;
        if (sA.length != sB.length || !sA.containsAll(sB)) continue;
        final pair = sA.toList()..sort();
        final x = pair[0], y = pair[1];

        // Try strong link on x along a row
        final rowStrong = _findStrongLinkOnLine(s, cand, x, byRow: true);
        for (final line in rowStrong) {
          // need one endpoint to see a and other to see b
          final end1 = line[0], end2 = line[1];
          final seesA =
              _peers(s, a).contains(end1) || _peers(s, a).contains(end2);
          final seesB =
              _peers(s, b).contains(end1) || _peers(s, b).contains(end2);
          if (!seesA || !seesB) continue;
          final elim = _wWingElims(s, cand, a, b, y);
          if (elim.isNotEmpty) {
            return Hint(
              StrategyType.wWing,
              eliminations: elim,
              cells: [a, b, end1, end2],
              digits: [x, y]..sort(),
              unit: HintUnit.row,
            );
          }
        }
        // Try strong link on x along a column
        final colStrong = _findStrongLinkOnLine(s, cand, x, byRow: false);
        for (final line in colStrong) {
          final end1 = line[0], end2 = line[1];
          final seesA =
              _peers(s, a).contains(end1) || _peers(s, a).contains(end2);
          final seesB =
              _peers(s, b).contains(end1) || _peers(s, b).contains(end2);
          if (!seesA || !seesB) continue;
          final elim = _wWingElims(s, cand, a, b, y);
          if (elim.isNotEmpty) {
            return Hint(
              StrategyType.wWing,
              eliminations: elim,
              cells: [a, b, end1, end2],
              digits: [x, y]..sort(),
              unit: HintUnit.column,
            );
          }
        }
      }
    }
    return null;
  }

  /// Returns list of strong-links for digit d on each row/column.
  /// Each entry is a List<int> of length 2 containing the two cell indices.
  List<List<int>> _findStrongLinkOnLine(
    Sudoku s,
    CandidateMap cand,
    int d, {
    required bool byRow,
  }) {
    final result = <List<int>>[];
    if (byRow) {
      for (var r = 0; r < 9; r++) {
        final cells = <int>[];
        for (final i in s.rowIndices(r)) {
          if (s.cells[i] == 0 && cand[i].contains(d)) cells.add(i);
        }
        if (cells.length == 2) result.add(cells);
      }
    } else {
      for (var c = 0; c < 9; c++) {
        final cells = <int>[];
        for (final i in s.colIndices(c)) {
          if (s.cells[i] == 0 && cand[i].contains(d)) cells.add(i);
        }
        if (cells.length == 2) result.add(cells);
      }
    }
    return result;
  }

  Map<int, Set<int>> _wWingElims(
    Sudoku s,
    CandidateMap cand,
    int a,
    int b,
    int eliminateDigit,
  ) {
    final elim = <int, Set<int>>{};
    final common = _peers(s, a).intersection(_peers(s, b));
    for (final idx in common) {
      if (s.cells[idx] == 0 && cand[idx].contains(eliminateDigit)) {
        _elimMapAdd(elim, idx, eliminateDigit);
      }
    }
    return elim;
  }

  @override
  Hint? getHintFromClues(Sudoku s, CandidateMap cand, List<int> indices) {
    if (indices.length < 2) return null;
    // Expect at least two bivalue cells with same pair and optionally two link cells.
    final a = indices[0];
    final b = indices[1];
    if (s.cells[a] != 0 || s.cells[b] != 0) return null;
    if (cand[a].length != 2 || cand[b].length != 2) return null;
    if (!cand[a].containsAll(cand[b])) return null;
    final pair = cand[a].toList()..sort();
    final x = pair[0], y = pair[1];

    // If provided with four clues, treat indices[2], indices[3] as the strong-link endpoints.
    // Otherwise, try to discover a link.
    Map<int, Set<int>> elim = {};
    if (indices.length >= 4) {
      elim = _wWingElims(s, cand, a, b, y);
      if (elim.isEmpty) return null;
      return Hint(
        StrategyType.wWing,
        eliminations: elim,
        cells: indices.take(4).toList(),
        digits: [x, y],
        unit: null,
      );
    }

    // Try to find any strong link on x along a row or column that connects peers of a and b.
    for (final line in _findStrongLinkOnLine(s, cand, x, byRow: true)) {
      final seesA =
          _peers(s, a).contains(line[0]) || _peers(s, a).contains(line[1]);
      final seesB =
          _peers(s, b).contains(line[0]) || _peers(s, b).contains(line[1]);
      if (!seesA || !seesB) continue;
      elim = _wWingElims(s, cand, a, b, y);
      if (elim.isNotEmpty)
        return Hint(
          StrategyType.wWing,
          eliminations: elim,
          cells: [a, b, ...line],
          digits: [x, y],
          unit: HintUnit.row,
        );
    }
    for (final line in _findStrongLinkOnLine(s, cand, x, byRow: false)) {
      final seesA =
          _peers(s, a).contains(line[0]) || _peers(s, a).contains(line[1]);
      final seesB =
          _peers(s, b).contains(line[0]) || _peers(s, b).contains(line[1]);
      if (!seesA || !seesB) continue;
      elim = _wWingElims(s, cand, a, b, y);
      if (elim.isNotEmpty)
        return Hint(
          StrategyType.wWing,
          eliminations: elim,
          cells: [a, b, ...line],
          digits: [x, y],
          unit: HintUnit.column,
        );
    }
    return null;
  }
}
