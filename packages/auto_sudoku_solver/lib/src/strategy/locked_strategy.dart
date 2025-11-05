import '../candidate_map.dart';
import '../difficulty.dart';
import '../hint.dart';
import '../sudoku.dart';
import 'strategy.dart';

/// Locked Candidates strategies
/// ----------------------------
///
/// Pointing (Box → Line):
///   If, in a 3×3 box, all candidates of a digit lie in a single row
///   or a single column, eliminate that digit from the rest of that
///   row/column outside the box.
///
/// Claiming (Line → Box):
///   If, in a row or column, all candidates of a digit lie in a single
///   3×3 box, eliminate that digit from the rest of that box outside the line.
///
/// Indices are 0..80 into Sudoku.cells.

// ---- Shared helpers -------------------------------------------------------

int _rowOf(int i) => i ~/ 9;
int _colOf(int i) => i % 9;
int _boxOf(int i) => (_rowOf(i) ~/ 3) * 3 + (_colOf(i) ~/ 3);

/// Build a Pointing hint from explicit clue indices.
/// `indices` must be ≥1 cells in the same box and all in the same row OR column.
/// We infer the digit by requiring that, within that box, only these cells are
/// candidates for the digit. If multiple digits fit, the first is used.
Hint? _pointingFromClues(Sudoku s, CandidateMap cand, List<int> indices) {
  if (indices.isEmpty) return null;
  final box = _boxOf(indices.first);
  if (!indices.every((i) => _boxOf(i) == box)) return null;
  final sameRow = indices.every((i) => _rowOf(i) == _rowOf(indices.first));
  final sameCol = indices.every((i) => _colOf(i) == _colOf(indices.first));
  if (!(sameRow || sameCol)) return null;

  final indexSet = indices.toSet();
  for (var d = 1; d <= 9; d++) {
    // candidates for d inside this box
    final inBox = <int>[];
    for (final i in s.boxIndices(box)) {
      if (s.cells[i] == 0 && cand[i].contains(d)) inBox.add(i);
    }
    if (inBox.isEmpty) continue;
    final set = inBox.toSet();
    if (!indexSet.containsAll(set)) {
      continue; // clues must cover all box candidates
    }

    // eliminations: along the row/col outside the box
    final elim = <int, Set<int>>{};
    if (sameRow) {
      final r = _rowOf(indices.first);
      for (final i in s.rowIndices(r)) {
        if (_boxOf(i) == box) continue;
        if (s.cells[i] == 0 && cand[i].contains(d)) {
          elim.putIfAbsent(i, () => {});
          elim[i]!.add(d);
        }
      }
      if (elim.isEmpty) continue;
      return Hint(
        StrategyType.pointing,
        eliminations: elim,
        cells: inBox,
        digits: [d],
        unit: HintUnit.row,
      );
    } else {
      final c = _colOf(indices.first);
      for (final i in s.colIndices(c)) {
        if (_boxOf(i) == box) continue;
        if (s.cells[i] == 0 && cand[i].contains(d)) {
          elim.putIfAbsent(i, () => {});
          elim[i]!.add(d);
        }
      }
      if (elim.isEmpty) continue;
      return Hint(
        StrategyType.pointing,
        eliminations: elim,
        cells: inBox,
        digits: [d],
        unit: HintUnit.column,
      );
    }
  }
  return null;
}

/// Build a Claiming hint from explicit clue indices.
/// `indices` must be ≥1 cells in the same row OR column and all in the same box.
/// We infer the digit by requiring that, within that line, all candidates of the digit
/// lie inside that single box and match the indices.
Hint? _claimingFromClues(Sudoku s, CandidateMap cand, List<int> indices) {
  if (indices.isEmpty) return null;
  final sameRow = indices.every((i) => _rowOf(i) == _rowOf(indices.first));
  final sameCol = indices.every((i) => _colOf(i) == _colOf(indices.first));
  if (!(sameRow || sameCol)) return null;
  final box = _boxOf(indices.first);
  if (!indices.every((i) => _boxOf(i) == box)) return null;

  final indexSet = indices.toSet();
  for (var d = 1; d <= 9; d++) {
    if (sameRow) {
      final r = _rowOf(indices.first);
      final inRow = <int>[];
      for (final i in s.rowIndices(r)) {
        if (s.cells[i] == 0 && cand[i].contains(d)) inRow.add(i);
      }
      if (inRow.isEmpty) continue;
      if (!inRow.every((i) => _boxOf(i) == box && indexSet.contains(i)))
        continue;

      final elim = <int, Set<int>>{};
      for (final i in s.boxIndices(box)) {
        if (_rowOf(i) == r) continue;
        if (s.cells[i] == 0 && cand[i].contains(d)) {
          elim.putIfAbsent(i, () => {});
          elim[i]!.add(d);
        }
        ;
      }
      if (elim.isEmpty) continue;
      return Hint(
        StrategyType.claiming,
        eliminations: elim,
        cells: inRow,
        digits: [d],
        unit: HintUnit.row,
      );
    } else {
      final c = _colOf(indices.first);
      final inCol = <int>[];
      for (final i in s.colIndices(c)) {
        if (s.cells[i] == 0 && cand[i].contains(d)) inCol.add(i);
      }
      if (inCol.isEmpty) continue;
      if (!inCol.every((i) => _boxOf(i) == box && indexSet.contains(i)))
        continue;

      final elim = <int, Set<int>>{};
      for (final i in s.boxIndices(box)) {
        if (_colOf(i) == c) continue;
        if (s.cells[i] == 0 && cand[i].contains(d)) {
          elim.putIfAbsent(i, () => {});
          elim[i]!.add(d);
        }
        ;
      }
      if (elim.isEmpty) continue;
      return Hint(
        StrategyType.claiming,
        eliminations: elim,
        cells: inCol,
        digits: [d],
        unit: HintUnit.column,
      );
    }
  }
  return null;
}

// ---- Pointing strategy ----------------------------------------------------

class PointingStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.pointing;

  @override
  Difficulty get difficulty => Difficulty.easy;

  @override
  Hint? findHint(Sudoku s, CandidateMap cand) {
    // Scan each box and digit
    for (var b = 0; b < 9; b++) {
      final boxCells = s.boxIndices(b).toList();
      for (var d = 1; d <= 9; d++) {
        final inBox = boxCells
            .where((i) => s.cells[i] == 0 && cand[i].contains(d))
            .toList();
        if (inBox.isEmpty) continue;
        final rows = inBox.map(_rowOf).toSet();
        if (rows.length == 1) {
          final r = rows.first;
          final elim = <int, Set<int>>{};
          for (final i in s.rowIndices(r)) {
            if (_boxOf(i) == b) continue;
            if (s.cells[i] == 0 && cand[i].contains(d)) {
              elim.putIfAbsent(i, () => {});
              elim[i]!.add(d);
            }
            ;
          }
          if (elim.isNotEmpty) {
            return Hint(
              StrategyType.pointing,
              eliminations: elim,
              cells: inBox,
              digits: [d],
              unit: HintUnit.row,
            );
          }
        }
        final cols = inBox.map(_colOf).toSet();
        if (cols.length == 1) {
          final c = cols.first;
          final elim = <int, Set<int>>{};
          for (final i in s.colIndices(c)) {
            if (_boxOf(i) == b) continue;
            if (s.cells[i] == 0 && cand[i].contains(d)) {
              elim.putIfAbsent(i, () => {});
              elim[i]!.add(d);
            }
            ;
          }
          if (elim.isNotEmpty) {
            return Hint(
              StrategyType.pointing,
              eliminations: elim,
              cells: inBox,
              digits: [d],
              unit: HintUnit.column,
            );
          }
        }
      }
    }
    return null;
  }

  @override
  Hint? getHintFromClues(Sudoku s, CandidateMap cand, List<int> indices) {
    return _pointingFromClues(s, cand, indices);
  }
}

// ---- Claiming strategy ----------------------------------------------------

class ClaimingStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.claiming;

  @override
  Difficulty get difficulty => Difficulty.easy;

  @override
  Hint? findHint(Sudoku s, CandidateMap cand) {
    // Row → Box
    for (var r = 0; r < 9; r++) {
      for (var d = 1; d <= 9; d++) {
        final rowCells = s
            .rowIndices(r)
            .where((i) => s.cells[i] == 0 && cand[i].contains(d))
            .toList();
        if (rowCells.isEmpty) continue;
        final boxes = rowCells.map(_boxOf).toSet();
        if (boxes.length == 1) {
          final b = boxes.first;
          final elim = <int, Set<int>>{};
          for (final i in s.boxIndices(b)) {
            if (_rowOf(i) == r) continue;
            if (s.cells[i] == 0 && cand[i].contains(d)) {
              elim.putIfAbsent(i, () => {});
              elim[i]!.add(d);
            }
            ;
          }
          if (elim.isNotEmpty) {
            return Hint(
              StrategyType.claiming,
              eliminations: elim,
              cells: rowCells,
              digits: [d],
              unit: HintUnit.row,
            );
          }
        }
      }
    }

    // Column → Box
    for (var c = 0; c < 9; c++) {
      for (var d = 1; d <= 9; d++) {
        final colCells = s
            .colIndices(c)
            .where((i) => s.cells[i] == 0 && cand[i].contains(d))
            .toList();
        if (colCells.isEmpty) continue;
        final boxes = colCells.map(_boxOf).toSet();
        if (boxes.length == 1) {
          final b = boxes.first;
          final elim = <int, Set<int>>{};
          for (final i in s.boxIndices(b)) {
            if (_colOf(i) == c) continue;
            if (s.cells[i] == 0 && cand[i].contains(d)) {
              elim.putIfAbsent(i, () => {});
              elim[i]!.add(d);
            }
            ;
          }
          if (elim.isNotEmpty) {
            return Hint(
              StrategyType.claiming,
              eliminations: elim,
              cells: colCells,
              digits: [d],
              unit: HintUnit.column,
            );
          }
        }
      }
    }

    return null;
  }

  @override
  Hint? getHintFromClues(Sudoku s, CandidateMap cand, List<int> indices) {
    return _claimingFromClues(s, cand, indices);
  }
}
