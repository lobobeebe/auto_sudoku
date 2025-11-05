import 'package:auto_sudoku_solver/src/sudoku_tool.dart';

abstract class NakedStrategy extends Strategy {
  // Helper to find a subset hint (naked/hidden, k in {2,3,4})
  Hint? _findNakedHint(Sudoku s, CandidateMap cand, int k) {
    for (var r = 0; r < 9; r++) {
      final h = _processUnitNaked(s, cand, k, s.rowIndices(r), HintUnit.row);
      if (h != null) return h;
    }
    for (var c = 0; c < 9; c++) {
      final h = _processUnitNaked(s, cand, k, s.colIndices(c), HintUnit.column);
      if (h != null) return h;
    }
    for (var b = 0; b < 9; b++) {
      final h = _processUnitNaked(s, cand, k, s.boxIndices(b), HintUnit.box);
      if (h != null) return h;
    }
    return null;
  }

  // Build a Naked subset hint (k in {2,3,4}) from explicit user-selected indices.
  Hint? _getHintFromCluesCommon(
    Sudoku s,
    CandidateMap cand,
    List<int> indices,
    int k,
    StrategyType type,
  ) {
    if (indices.length != k) return null;

    // Reject filled cells and candidates that are not 2..k in size.
    for (final i in indices) {
      if (s.cells[i] != 0) return null;
      final len = cand[i].length;
      if (len < 2 || len > k) return null;
    }

    // Union must be exactly k digits.
    final union = <int>{};
    for (final i in indices) {
      union.addAll(cand[i]);
    }
    if (union.length != k) return null;

    // Compute unit membership.
    int rowOf(int i) => i ~/ 9;
    int colOf(int i) => i % 9;
    int boxOf(int i) => (rowOf(i) ~/ 3) * 3 + (colOf(i) ~/ 3);

    final baseRow = rowOf(indices.first);
    final baseCol = colOf(indices.first);
    final baseBox = boxOf(indices.first);

    final inSameRow = indices.every((i) => rowOf(i) == baseRow);
    final inSameCol = indices.every((i) => colOf(i) == baseCol);
    final inSameBox = indices.every((i) => boxOf(i) == baseBox);

    if (!(inSameRow || inSameCol || inSameBox)) return null;

    // Helper to collect eliminations within a unit that contains all selected cells.
    final eliminationsMap = <int, Set<int>>{};
    HintUnit? chosenUnit;

    void collect(Iterable<int> unit, HintUnit unitType) {
      // Ensure the unit really contains all selected indices
      final unitSet = unit.toSet();
      if (!indices.every(unitSet.contains)) return;

      var any = false;
      for (final i in unit) {
        if (indices.contains(i)) {
          continue; // never eliminate from the triple/pair/quad cells
        }
        if (s.cells[i] != 0) continue;
        final cands = cand[i];
        for (final d in union) {
          if (cands.contains(d)) {
            eliminationsMap.putIfAbsent(i, () => <int>{}).add(d);
            any = true;
          }
        }
      }
      if (any && chosenUnit == null) chosenUnit = unitType;
    }

    if (inSameRow) collect(s.rowIndices(baseRow), HintUnit.row);
    if (inSameCol) collect(s.colIndices(baseCol), HintUnit.column);
    if (inSameBox) collect(s.boxIndices(baseBox), HintUnit.box);

    if (eliminationsMap.isEmpty) return null;

    final digits = union.toList()..sort();
    return Hint(
      type,
      eliminations: eliminationsMap,
      cells: List<int>.from(indices),
      digits: digits,
      unit: chosenUnit,
    );
  }

  // Try Naked subset in each unit (generalized for k in {2,3,4})
  Hint? _processUnitNaked(
    Sudoku s,
    CandidateMap cand,
    int k,
    Iterable<int> unit,
    HintUnit unitType,
  ) {
    final empties = unit.where((i) => s.cells[i] == 0).toList();
    if (empties.length < k) return null;

    // Consider only cells with 2..k candidates
    final subsetPool = empties.where((i) {
      final len = cand[i].length;
      return len >= 2 && len <= k;
    }).toList();
    if (subsetPool.length < k) return null;

    for (final combo in _combinations(subsetPool, k)) {
      // Build union of candidates in the chosen cells
      final union = <int>{};
      var validSize = true;
      for (final idx in combo) {
        final len = cand[idx].length;
        if (len > k || len < 2) {
          validSize = false;
          break;
        }
        union.addAll(cand[idx]);
      }
      if (!validSize || union.length != k) continue;

      // Gather eliminations from the rest of the unit
      final eliminations = <int, Set<int>>{};
      for (final i in empties) {
        if (combo.contains(i)) continue;
        for (final d in union) {
          if (cand[i].contains(d)) {
            eliminations.putIfAbsent(i, () => {}).add(d);
          }
        }
      }
      if (eliminations.isEmpty) continue;

      final type = _strategyTypeForK(k);
      return Hint(
        type,
        eliminations: eliminations,
        cells: List<int>.from(combo),
        digits: union.toList(),
        unit: unitType,
      );
    }
    return null;
  }

  StrategyType _strategyTypeForK(int k) {
    switch (k) {
      case 2:
        return StrategyType.nakedPair;
      case 3:
        return StrategyType.nakedTriple;
      case 4:
        return StrategyType.nakedQuad;
      default:
        throw ArgumentError('Unsupported naked subset size: $k');
    }
  }

  // Simple combinations iterator: returns all k-sized selections from items.
  Iterable<List<int>> _combinations(List<int> items, int k) sync* {
    final n = items.length;
    if (k <= 0 || k > n) return;
    final idx = List<int>.generate(k, (i) => i);

    List<int> current() => [for (var t = 0; t < k; t++) items[idx[t]]];
    yield current();

    while (true) {
      var i = k - 1;
      while (i >= 0 && idx[i] == i + n - k) i--;
      if (i < 0) break;
      idx[i]++;
      for (var j = i + 1; j < k; j++) {
        idx[j] = idx[j - 1] + 1;
      }
      yield current();
    }
  }
}

class NakedPairStrategy extends NakedStrategy {
  @override
  StrategyType get type => StrategyType.nakedPair;
  @override
  Hint? findHint(Sudoku s, CandidateMap cand) {
    return _findNakedHint(s, cand, 2);
  }

  @override
  Difficulty get difficulty => Difficulty.easy;

  @override
  Hint? getHintFromClues(Sudoku s, CandidateMap cand, List<int> indices) {
    return _getHintFromCluesCommon(s, cand, indices, 2, StrategyType.nakedPair);
  }
}

class NakedTripleStrategy extends NakedStrategy {
  @override
  StrategyType get type => StrategyType.nakedTriple;

  @override
  Hint? findHint(Sudoku s, CandidateMap cand) {
    return _findNakedHint(s, cand, 3);
  }

  @override
  Difficulty get difficulty => Difficulty.easy;

  @override
  Hint? getHintFromClues(Sudoku s, CandidateMap cand, List<int> indices) {
    return _getHintFromCluesCommon(
      s,
      cand,
      indices,
      3,
      StrategyType.nakedTriple,
    );
  }
}

class NakedQuadStrategy extends NakedStrategy {
  @override
  StrategyType get type => StrategyType.nakedQuad;

  @override
  Hint? findHint(Sudoku s, CandidateMap cand) {
    return _findNakedHint(s, cand, 4);
  }

  @override
  Difficulty get difficulty => Difficulty.easy;

  @override
  Hint? getHintFromClues(Sudoku s, CandidateMap cand, List<int> indices) {
    return _getHintFromCluesCommon(s, cand, indices, 4, StrategyType.nakedQuad);
  }
}

class NakedSingleStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.nakedSingle;

  @override
  Difficulty get difficulty => Difficulty.easy;

  @override
  Hint? findHint(Sudoku s, CandidateMap cand) {
    // Find the first empty cell that has exactly one candidate.
    for (var i = 0; i < 81; i++) {
      if (s.cells[i] != 0) continue;
      final cands = cand[i];
      if (cands.length == 1) {
        final d = cands.first;
        return Hint(
          StrategyType.nakedSingle,
          eliminations: const <int, Set<int>>{},
          placements: {i: d},
          cells: [i],
          digits: [d],
          unit: null,
        );
      }
    }
    return null;
  }

  @override
  Hint? getHintFromClues(Sudoku s, CandidateMap cand, List<int> indices) {
    if (indices.length != 1) return null;
    final i = indices.first;
    if (s.cells[i] != 0) return null;
    final cands = cand[i];
    if (cands.length != 1) return null;
    final d = cands.first;
    return Hint(
      StrategyType.nakedSingle,
      eliminations: const <int, Set<int>>{},
      placements: {i: d},
      cells: [i],
      digits: [d],
      unit: null,
    );
  }
}
