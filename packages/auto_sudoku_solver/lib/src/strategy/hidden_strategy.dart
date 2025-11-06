import '../difficulty.dart';
import '../hint.dart';
import '../sudoku.dart';
import 'strategy.dart';

/// Hidden strategies (Single/Pair/Triple/Quad)
///
/// Common idea:
///   In a unit (row/column/box), pick k digits whose candidate positions
///   cover exactly k cells. Those k cells form a hidden subset; eliminate
///   any *other* candidates from those cells.
///
/// Indices are 0..80 into Sudoku.cells.
abstract class HiddenStrategy extends Strategy {
  /// Size of subset (k in {2,3,4}). HiddenSingle is a separate class.
  int get k;

  /// Strategy type for this k (hiddenPair/hiddenTriple/hiddenQuad).
  StrategyType get subsetType;

  @override
  Hint? findHint(Sudoku s) {
    // Rows
    for (var r = 0; r < 9; r++) {
      final h = _processUnitHidden(s, s.rowIndices(r), HintUnit.row);
      if (h != null) return h;
    }
    // Columns
    for (var c = 0; c < 9; c++) {
      final h = _processUnitHidden(s, s.colIndices(c), HintUnit.column);
      if (h != null) return h;
    }
    // Boxes
    for (var b = 0; b < 9; b++) {
      final h = _processUnitHidden(s, s.boxIndices(b), HintUnit.box);
      if (h != null) return h;
    }
    return null;
  }

  /// Build a Hidden subset hint from explicit user-selected indices (cells).
  /// The indices must all lie in the same unit (row/col/box). We then find
  /// the digits whose positions (restricted to that unit) are *entirely*
  /// within those indices. If exactly k digits qualify and at least one
  /// elimination exists, we return a Hint.
  Hint? getHintFromCluesCommon(
    Sudoku s,

    List<int> indices,
    int k,
    StrategyType type,
  ) {
    if (indices.length != k) return null;
    for (final i in indices) {
      if (s.cells[i] != 0) return null;
    }

    int rowOf(int i) => i ~/ 9;
    int colOf(int i) => i % 9;
    int boxOf(int i) => (rowOf(i) ~/ 3) * 3 + (colOf(i) ~/ 3);

    final base = indices.first;
    final sameRow = indices.every((i) => rowOf(i) == rowOf(base));
    final sameCol = indices.every((i) => colOf(i) == colOf(base));
    final sameBox = indices.every((i) => boxOf(i) == boxOf(base));
    if (!(sameRow || sameCol || sameBox)) return null;

    Iterable<int> unit;
    HintUnit unitType;
    if (sameRow) {
      unit = s.rowIndices(rowOf(base));
      unitType = HintUnit.row;
    } else if (sameCol) {
      unit = s.colIndices(colOf(base));
      unitType = HintUnit.column;
    } else {
      unit = s.boxIndices(boxOf(base));
      unitType = HintUnit.box;
    }

    // Digits whose positions (in this unit) are subset of the selected cells.
    final targetDigits = <int>[];
    final indexSet = indices.toSet();
    for (var d = 1; d <= 9; d++) {
      var ok = true;
      var seenAny = false;
      for (final i in unit) {
        if (s.cells[i] != 0) continue;
        if (s.notes[i].contains(d)) {
          seenAny = true;
          if (!indexSet.contains(i)) {
            ok = false;
            break;
          }
        }
      }
      if (ok && seenAny) targetDigits.add(d);
    }
    if (targetDigits.length != k) return null;

    // Eliminations: in the selected cells, remove candidates not among the target digits.
    final elim = <int, Set<int>>{};
    final digitSet = targetDigits.toSet();
    for (final i in indices) {
      for (final cnd in s.notes[i]) {
        if (!digitSet.contains(cnd)) {
          elim.putIfAbsent(i, () => {});
          elim[i]!.add((cnd));
        }
      }
    }
    if (elim.isEmpty) return null;

    targetDigits.sort();
    return Hint(
      type,
      eliminations: elim,
      cells: List<int>.from(indices),
      digits: targetDigits,
      unit: unitType,
    );
  }

  Hint? _processUnitHidden(Sudoku s, Iterable<int> unit, HintUnit unitType) {
    final empties = unit.where((i) => s.cells[i] == 0).toList();
    if (empties.length < k) return null;

    // Candidate locations per digit (in this unit).
    final locs = List.generate(10, (_) => <int>[]);
    for (final i in empties) {
      for (final d in s.notes[i]) {
        locs[d].add(i);
      }
    }

    // Digits whose locations size is within [2..k].
    final candidateDigits = <int>[];
    for (var d = 1; d <= 9; d++) {
      final pos = locs[d];
      if (pos.length >= 2 && pos.length <= k) candidateDigits.add(d);
    }
    if (candidateDigits.length < k) return null;

    return _chooseDigitsAndBuildHint(
      s,
      locs,
      candidateDigits,
      unitType,
      k,
      subsetType,
    );
  }

  Hint? _chooseDigitsAndBuildHint(
    Sudoku s,

    List<List<int>> locs,
    List<int> digits,
    HintUnit unitType,
    int k,
    StrategyType type,
  ) {
    Hint? out;
    final pick = <int>[];

    void dfs(int start) {
      if (out != null) return;
      if (pick.length == k) {
        // Union of positions for chosen digits must be exactly k cells.
        final posSet = <int>{};
        for (final d in pick) {
          posSet.addAll(locs[d]);
        }
        if (posSet.length != k) return;

        // Eliminations: within those cells, drop candidates not in chosen digits.
        final elim = <int, Set<int>>{};
        final digitSet = pick.toSet();
        for (final i in posSet) {
          for (final cnd in s.notes[i]) {
            if (!digitSet.contains(cnd)) {
              elim.putIfAbsent(i, () => {});
              elim[i]!.add(cnd);
            }
          }
        }
        if (elim.isEmpty) return;

        final cells = posSet.toList()..sort();
        final digs = pick.toList()..sort();
        out = Hint(
          type,
          eliminations: elim,
          cells: cells,
          digits: digs,
          unit: unitType,
        );
        return;
      }
      for (var i = start; i < digits.length; i++) {
        pick.add(digits[i]);
        dfs(i + 1);
        pick.removeLast();
        if (out != null) return;
      }
    }

    dfs(0);
    return out;
  }
}

class HiddenSingleStrategy extends Strategy {
  @override
  StrategyType get type => StrategyType.hiddenSingle;

  @override
  Difficulty get difficulty => Difficulty.easy;

  @override
  Hint? findHint(Sudoku s) {
    Hint? scan(Iterable<int> unit, HintUnit unitType) {
      final spots = List.generate(10, (_) => <int>[]);
      for (final i in unit) {
        if (s.cells[i] != 0) continue;
        for (final d in s.notes[i]) {
          spots[d].add(i);
        }
      }
      for (var d = 1; d <= 9; d++) {
        final pos = spots[d];
        if (pos.length == 1) {
          final cell = pos.first;
          return Hint(
            StrategyType.hiddenSingle,
            placements: {cell: d},
            cells: [cell],
            digits: [d],
            unit: unitType,
          );
        }
      }
      return null;
    }

    for (var r = 0; r < 9; r++) {
      final h = scan(s.rowIndices(r), HintUnit.row);
      if (h != null) return h;
    }
    for (var c = 0; c < 9; c++) {
      final h = scan(s.colIndices(c), HintUnit.column);
      if (h != null) return h;
    }
    for (var b = 0; b < 9; b++) {
      final h = scan(s.boxIndices(b), HintUnit.box);
      if (h != null) return h;
    }
    return null;
  }

  @override
  Hint? getHintFromClues(Sudoku s, List<int> indices) {
    if (indices.length != 1) return null;
    final i = indices.first;
    if (s.cells[i] != 0) return null;

    Hint? uniqueIn(Iterable<int> unit, HintUnit unitType) {
      for (var d = 1; d <= 9; d++) {
        var count = 0;
        var onlyHere = false;
        for (final u in unit) {
          if (s.cells[u] != 0) continue;
          if (s.notes[u].contains(d)) {
            count++;
            if (u == i) onlyHere = true;
            if (count > 1) break;
          }
        }
        if (count == 1 && onlyHere) {
          return Hint(
            StrategyType.hiddenSingle,
            placements: {i: d},
            cells: [i],
            digits: [d],
            unit: unitType,
          );
        }
      }
      return null;
    }

    final r = i ~/ 9, c = i % 9, b = (r ~/ 3) * 3 + (c ~/ 3);
    return uniqueIn(s.rowIndices(r), HintUnit.row) ??
        uniqueIn(s.colIndices(c), HintUnit.column) ??
        uniqueIn(s.boxIndices(b), HintUnit.box);
  }
}

class HiddenPairStrategy extends HiddenStrategy {
  @override
  int get k => 2;

  @override
  StrategyType get subsetType => StrategyType.hiddenPair;

  @override
  StrategyType get type => StrategyType.hiddenPair;

  @override
  Difficulty get difficulty => Difficulty.easy;

  @override
  Hint? getHintFromClues(Sudoku s, List<int> indices) {
    return getHintFromCluesCommon(s, indices, 2, StrategyType.hiddenPair);
  }
}

class HiddenTripleStrategy extends HiddenStrategy {
  @override
  int get k => 3;

  @override
  StrategyType get subsetType => StrategyType.hiddenTriple;

  @override
  StrategyType get type => StrategyType.hiddenTriple;

  @override
  Difficulty get difficulty => Difficulty.easy;

  @override
  Hint? getHintFromClues(Sudoku s, List<int> indices) {
    return getHintFromCluesCommon(s, indices, 3, StrategyType.hiddenTriple);
  }
}

class HiddenQuadStrategy extends HiddenStrategy {
  @override
  int get k => 4;

  @override
  StrategyType get subsetType => StrategyType.hiddenQuad;

  @override
  StrategyType get type => StrategyType.hiddenQuad;

  @override
  Difficulty get difficulty => Difficulty.medium;

  @override
  Hint? getHintFromClues(Sudoku s, List<int> indices) {
    return getHintFromCluesCommon(s, indices, 4, StrategyType.hiddenQuad);
  }
}
