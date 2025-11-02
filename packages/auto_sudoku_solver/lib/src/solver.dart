import 'candidate_map.dart';
import 'difficulty.dart';
import 'hint.dart';
import 'rating.dart';
import 'solve_result.dart';
import 'strategy.dart';
import 'sudoku.dart';

import 'solver_settings.dart';

class Solver {
  // Supported logical techniques in increasing difficulty order
  static const List<StrategyUsed> difficultyOrder = strategyDifficultyOrder;

  Hint? nextHint(Sudoku s, {SolverSettings? settings}) {
    final effective = settings ?? SolverSettings();
    final cand = CandidateMap.fromBoard(s);
    return _nextHintInternal(s, cand, effective);
  }

  Hint? _nextHintInternal(
    Sudoku s,
    CandidateMap cand,
    SolverSettings settings,
  ) {
    final naked = _findNakedSingleHint(s, cand);
    if (naked != null) return naked;

    if (settings.allowHiddenSingles) {
      final hidden = _findHiddenSingleHint(s, cand);
      if (hidden != null) return hidden;
    }

    if (settings.allowPairs) {
      final pair = _findSubsetHint(
        s,
        cand,
        2,
        allowHidden: settings.allowHiddenSubsets,
      );
      if (pair != null) return pair;
    }

    if (settings.allowTriples) {
      final triple = _findSubsetHint(
        s,
        cand,
        3,
        allowHidden: settings.allowHiddenSubsets,
      );
      if (triple != null) return triple;
    }

    if (settings.allowQuads) {
      final quad = _findSubsetHint(
        s,
        cand,
        4,
        allowHidden: settings.allowHiddenSubsets,
      );
      if (quad != null) return quad;
    }

    if (settings.allowLocked) {
      final locked = _findLockedHint(s, cand);
      if (locked != null) return locked;
    }

    if (settings.allowXWing) {
      final x = _findXWingHint(s, cand);
      if (x != null) return x;
    }

    if (settings.allowXYWing) {
      final xy = _findXYWingHint(s, cand);
      if (xy != null) return xy;
    }

    if (settings.allowColoring) {
      final coloring = _findColoringHint(s, cand);
      if (coloring != null) return coloring;
    }

    if (settings.allowSwordfish) {
      final swordfish = _findSwordfishHint(s, cand);
      if (swordfish != null) return swordfish;
    }

    if (settings.allowSkyscraper) {
      final sky = _findSkyscraperHint(s, cand);
      if (sky != null) return sky;
    }

    if (settings.allowTwoStringKite) {
      final kite = _findTwoStringKiteHint(s, cand);
      if (kite != null) return kite;
    }

    if (settings.allowTurbotFish) {
      final turbot = _findTurbotFishHint(s, cand);
      if (turbot != null) return turbot;
    }

    if (settings.allowXYZWing) {
      final xyz = _findXYZWingHint(s, cand);
      if (xyz != null) return xyz;
    }

    if (settings.allowWWing) {
      final w = _findWWingHint(s, cand);
      if (w != null) return w;
    }

    if (settings.allowUR) {
      final ur = _findUniqueRectangleHint(s, cand);
      if (ur != null) return ur;
    }

    if (settings.allowBUG) {
      final bug = _findBugHint(s, cand);
      if (bug != null) return bug;
    }

    if (settings.allowRemotePairs) {
      final rp = _findRemotePairsHint(s, cand);
      if (rp != null) return rp;
    }

    if (settings.allowXYChain) {
      final chain = _findXYChainHint(s, cand);
      if (chain != null) return chain;
    }

    if (settings.allowALS) {
      final als = _findALSHint(s, cand);
      if (als != null) return als;
    }

    if (settings.allowALSXYWing) {
      final alsXy = _findALSXyWingHint(s, cand);
      if (alsXy != null) return alsXy;
    }

    if (settings.allowAIC) {
      final aic = _findAICHint(s, cand);
      if (aic != null) return aic;
    }

    return null;
  }

  Hint? _findNakedSingleHint(Sudoku s, CandidateMap cand) {
    for (var i = 0; i < 81; i++) {
      if (s.cells[i] != 0) continue;
      if (cand[i].length != 1) continue;
      final value = cand[i].first;
      return Hint(
        StrategyUsed.nakedSingle,
        placements: [(i, value)],
        cells: [i],
        digits: [value],
      );
    }
    return null;
  }

  Hint? _findHiddenSingleHint(Sudoku s, CandidateMap cand) {
    Hint? checkUnit(Iterable<int> unit) {
      final spots = List.generate(10, (_) => <int>[]);
      for (final cell in unit) {
        if (s.cells[cell] != 0) continue;
        for (final digit in cand[cell]) {
          spots[digit].add(cell);
        }
      }
      for (var digit = 1; digit <= 9; digit++) {
        final positions = spots[digit];
        if (positions.length == 1) {
          final cell = positions.first;
          return Hint(
            StrategyUsed.hiddenSingle,
            placements: [(cell, digit)],
            cells: [cell],
            digits: [digit],
          );
        }
      }
      return null;
    }

    for (var r = 0; r < 9; r++) {
      final hint = checkUnit(s.rowIndices(r));
      if (hint != null) return hint;
    }
    for (var c = 0; c < 9; c++) {
      final hint = checkUnit(s.colIndices(c));
      if (hint != null) return hint;
    }
    for (var b = 0; b < 9; b++) {
      final hint = checkUnit(s.boxIndices(b));
      if (hint != null) return hint;
    }
    return null;
  }

  /// Returns a Locked Candidates (Pointing/Claiming) hint, with evidence, if any.
  Hint? _findLockedHint(Sudoku s, CandidateMap cand) {
    // Pointing: box -> row/col
    for (var b = 0; b < 9; b++) {
      final boxCells = s.boxIndices(b).toList();
      for (var d = 1; d <= 9; d++) {
        final inBox = boxCells
            .where((i) => s.cells[i] == 0 && cand[i].contains(d))
            .toList();
        if (inBox.isEmpty) continue;
        final rows = inBox.map(s.rowOf).toSet();
        if (rows.length == 1) {
          final r = rows.first;
          final elim = <(int, int)>[];
          for (final i in s.rowIndices(r)) {
            if (!boxCells.contains(i) &&
                s.cells[i] == 0 &&
                cand[i].contains(d)) {
              elim.add((i, d));
            }
          }
          if (elim.isNotEmpty) {
            return Hint(
              StrategyUsed.pointing,
              eliminations: elim,
              cells: inBox,
              digits: [d],
            );
          }
        }
        final cols = inBox.map(s.colOf).toSet();
        if (cols.length == 1) {
          final c = cols.first;
          final elim = <(int, int)>[];
          for (final i in s.colIndices(c)) {
            if (!boxCells.contains(i) &&
                s.cells[i] == 0 &&
                cand[i].contains(d)) {
              elim.add((i, d));
            }
          }
          if (elim.isNotEmpty) {
            return Hint(
              StrategyUsed.pointing,
              eliminations: elim,
              cells: inBox,
              digits: [d],
            );
          }
        }
      }
    }

    // Claiming: row/col -> box
    for (var r = 0; r < 9; r++) {
      for (var d = 1; d <= 9; d++) {
        final rowCells = s
            .rowIndices(r)
            .where((i) => s.cells[i] == 0 && cand[i].contains(d))
            .toList();
        if (rowCells.isEmpty) continue;
        final boxes = rowCells.map(s.boxOf).toSet();
        if (boxes.length == 1) {
          final b = boxes.first;
          final elim = <(int, int)>[];
          for (final i in s.boxIndices(b)) {
            if (s.rowOf(i) != r && s.cells[i] == 0 && cand[i].contains(d)) {
              elim.add((i, d));
            }
          }
          if (elim.isNotEmpty) {
            return Hint(
              StrategyUsed.claiming,
              eliminations: elim,
              cells: rowCells,
              digits: [d],
            );
          }
        }
      }
    }
    for (var c = 0; c < 9; c++) {
      for (var d = 1; d <= 9; d++) {
        final colCells = s
            .colIndices(c)
            .where((i) => s.cells[i] == 0 && cand[i].contains(d))
            .toList();
        if (colCells.isEmpty) continue;
        final boxes = colCells.map(s.boxOf).toSet();
        if (boxes.length == 1) {
          final b = boxes.first;
          final elim = <(int, int)>[];
          for (final i in s.boxIndices(b)) {
            if (s.colOf(i) != c && s.cells[i] == 0 && cand[i].contains(d)) {
              elim.add((i, d));
            }
          }
          if (elim.isNotEmpty) {
            return Hint(
              StrategyUsed.claiming,
              eliminations: elim,
              cells: colCells,
              digits: [d],
            );
          }
        }
      }
    }
    return null;
  }

  // Helper to find a subset hint (naked/hidden, k in {2,3,4})
  Hint? _findSubsetHint(
    Sudoku s,
    CandidateMap cand,
    int k, {
    required bool allowHidden,
  }) {
    // Try Naked subset in each unit
    Hint? processUnitNaked(Iterable<int> unit) {
      final empties = unit.where((i) => s.cells[i] == 0).toList();
      for (var a = 0; a < empties.length; a++) {
        for (var b = a + 1; b < empties.length; b++) {
          if (k == 2) {
            final set = {...cand[empties[a]], ...cand[empties[b]]};
            if (set.length == 2 &&
                cand[empties[a]].length <= 2 &&
                cand[empties[b]].length <= 2) {
              final others = <(int, int)>[];
              for (final i in empties) {
                if (i == empties[a] || i == empties[b]) continue;
                for (final v in set) {
                  if (cand[i].contains(v)) others.add((i, v));
                }
              }
              if (others.isNotEmpty) {
                return Hint(
                  StrategyUsed.nakedPair,
                  eliminations: others,
                  cells: [empties[a], empties[b]],
                  digits: set.toList(),
                );
              }
            }
          } else {
            for (var c = b + 1; c < empties.length; c++) {
              final set = {
                ...cand[empties[a]],
                ...cand[empties[b]],
                ...cand[empties[c]],
              };
              if (set.length == k &&
                  cand[empties[a]].length <= k &&
                  cand[empties[b]].length <= k &&
                  cand[empties[c]].length <= k) {
                final others = <(int, int)>[];
                for (final i in empties) {
                  if (i == empties[a] || i == empties[b] || i == empties[c]) {
                    continue;
                  }
                  for (final v in set) {
                    if (cand[i].contains(v)) others.add((i, v));
                  }
                }
                if (others.isNotEmpty) {
                  return Hint(
                    k == 3 ? StrategyUsed.nakedTriple : StrategyUsed.nakedQuad,
                    eliminations: others,
                    cells: [empties[a], empties[b], empties[c]],
                    digits: set.toList(),
                  );
                }
              }
            }
          }
        }
      }
      return null;
    }

    // Try Hidden subset in each unit
    Hint? processUnitHidden(Iterable<int> unit) {
      final empties = unit.where((i) => s.cells[i] == 0).toList();
      final locs = List.generate(10, (_) => <int>[]);
      for (final i in empties) {
        for (final d in cand[i]) {
          locs[d].add(i);
        }
      }
      for (var d = 1; d <= 9; d++) {
        final pos = locs[d];
        if (pos.length >= 2 && pos.length <= k) {
          final union = <int>{};
          for (final i in pos) {
            union.addAll(cand[i]);
          }
          if (union.length == k) {
            final toTrim = <(int, int)>[]; // (cell, digit)
            for (final i in pos) {
              for (final x in cand[i]) {
                if (!union.contains(x)) toTrim.add((i, x));
              }
            }
            if (toTrim.isNotEmpty) {
              return Hint(
                k == 2
                    ? StrategyUsed.hiddenPair
                    : k == 3
                    ? StrategyUsed.hiddenTriple
                    : StrategyUsed.hiddenQuad,
                eliminations: toTrim,
                cells: pos,
                digits: union.toList(),
              );
            }
          }
        }
      }
      return null;
    }

    for (var r = 0; r < 9; r++) {
      final h =
          processUnitNaked(s.rowIndices(r)) ??
          (allowHidden ? processUnitHidden(s.rowIndices(r)) : null);
      if (h != null) return h;
    }
    for (var c = 0; c < 9; c++) {
      final h =
          processUnitNaked(s.colIndices(c)) ??
          (allowHidden ? processUnitHidden(s.colIndices(c)) : null);
      if (h != null) return h;
    }
    for (var b = 0; b < 9; b++) {
      final h =
          processUnitNaked(s.boxIndices(b)) ??
          (allowHidden ? processUnitHidden(s.boxIndices(b)) : null);
      if (h != null) return h;
    }
    return null;
  }

  Hint? _findXWingHint(Sudoku s, CandidateMap cand) {
    for (var d = 1; d <= 9; d++) {
      final rowsCols = <int, Set<int>>{};
      for (var r = 0; r < 9; r++) {
        final cols = <int>{};
        for (var c = 0; c < 9; c++) {
          final i = s.idx(r, c);
          if (s.cells[i] == 0 && cand[i].contains(d)) cols.add(c);
        }
        if (cols.length == 2) rowsCols[r] = cols;
      }
      final rows = rowsCols.keys.toList();
      for (var i = 0; i < rows.length; i++) {
        for (var j = i + 1; j < rows.length; j++) {
          final r1 = rows[i], r2 = rows[j];
          final cset1 = rowsCols[r1]!;
          final cset2 = rowsCols[r2]!;
          if (cset1.length == 2 && cset1.containsAll(cset2)) {
            final cols = cset1.toList();
            final c1 = cols[0], c2 = cols[1];
            final eliminations = <(int, int)>[];
            for (var r = 0; r < 9; r++) {
              if (r == r1 || r == r2) continue;
              final i1 = s.idx(r, c1);
              final i2 = s.idx(r, c2);
              if (s.cells[i1] == 0 && cand[i1].contains(d)) {
                eliminations.add((i1, d));
              }
              if (s.cells[i2] == 0 && cand[i2].contains(d)) {
                eliminations.add((i2, d));
              }
            }
            final evidCells = [
              s.idx(r1, c1),
              s.idx(r1, c2),
              s.idx(r2, c1),
              s.idx(r2, c2),
            ];
            if (eliminations.isNotEmpty) {
              return Hint(
                StrategyUsed.xWing,
                eliminations: eliminations,
                cells: evidCells,
                digits: [d],
              );
            }
          }
        }
      }
      // Column-based (transpose)
      final colsRows = <int, Set<int>>{};
      for (var c = 0; c < 9; c++) {
        final rowsSet = <int>{};
        for (var r = 0; r < 9; r++) {
          final i = s.idx(r, c);
          if (s.cells[i] == 0 && cand[i].contains(d)) rowsSet.add(r);
        }
        if (rowsSet.length == 2) colsRows[c] = rowsSet;
      }
      final cols = colsRows.keys.toList();
      for (var i = 0; i < cols.length; i++) {
        for (var j = i + 1; j < cols.length; j++) {
          final c1 = cols[i], c2 = cols[j];
          final rset1 = colsRows[c1]!;
          final rset2 = colsRows[c2]!;
          if (rset1.length == 2 && rset1.containsAll(rset2)) {
            final rowsPair = rset1.toList();
            final r1 = rowsPair[0], r2 = rowsPair[1];
            final eliminations = <(int, int)>[];
            for (var c = 0; c < 9; c++) {
              if (c == c1 || c == c2) continue;
              final i1 = s.idx(r1, c);
              final i2 = s.idx(r2, c);
              if (s.cells[i1] == 0 && cand[i1].contains(d)) {
                eliminations.add((i1, d));
              }
              if (s.cells[i2] == 0 && cand[i2].contains(d)) {
                eliminations.add((i2, d));
              }
            }
            final evidCells = [
              s.idx(r1, c1),
              s.idx(r2, c1),
              s.idx(r1, c2),
              s.idx(r2, c2),
            ];
            if (eliminations.isNotEmpty) {
              return Hint(
                StrategyUsed.xWing,
                eliminations: eliminations,
                cells: evidCells,
                digits: [d],
              );
            }
          }
        }
      }
    }
    return null;
  }

  SolveResult solveLogical(
    Sudoku s, {
    bool allowHiddenSingles = true,
    bool allowLocked = true,
    bool allowPairs = true,
    bool allowTriples = true,
    bool allowQuads = true,
    bool allowHiddenSubsets = true,
    bool allowXWing = true,
    bool allowXYWing = true,
    bool allowColoring = false,
    bool allowSwordfish = false,
    bool allowSkyscraper = false,
    bool allowTwoStringKite = false,
    bool allowTurbotFish = false,
    bool allowXYZWing = false,
    bool allowWWing = false,
    bool allowUR = false,
    bool allowBUG = false,
    bool allowRemotePairs = false,
    bool allowXYChain = false,
    bool allowALS = false,
    bool allowALSXYWing = false,
    bool allowAIC = false,
  }) {
    final steps = <StrategyUsed>[];
    final cand = CandidateMap.fromBoard(s);
    final settings = SolverSettings(
      allowHiddenSingles: allowHiddenSingles,
      allowLocked: allowLocked,
      allowPairs: allowPairs,
      allowTriples: allowTriples,
      allowQuads: allowQuads,
      allowHiddenSubsets: allowHiddenSubsets,
      allowXWing: allowXWing,
      allowXYWing: allowXYWing,
      allowColoring: allowColoring,
      allowSwordfish: allowSwordfish,
      allowSkyscraper: allowSkyscraper,
      allowTwoStringKite: allowTwoStringKite,
      allowTurbotFish: allowTurbotFish,
      allowXYZWing: allowXYZWing,
      allowWWing: allowWWing,
      allowUR: allowUR,
      allowBUG: allowBUG,
      allowRemotePairs: allowRemotePairs,
      allowXYChain: allowXYChain,
      allowALS: allowALS,
      allowALSXYWing: allowALSXYWing,
      allowAIC: allowAIC,
    );

    while (!s.isSolved) {
      if (!cand.isNotesDriven) {
        for (var i = 0; i < 81; i++) {
          if (s.cells[i] != 0 || cand[i].isNotEmpty) continue;
          for (var d = 1; d <= 9; d++) {
            if (s.isValidPlacement(i, d)) {
              cand[i].add(d);
            }
          }
        }
      }
      final hint = _nextHintInternal(s, cand, settings);
      if (hint == null) {
        break;
      }
      final mutated = _applyHint(s, cand, hint);
      if (!mutated) {
        break;
      }
      steps.add(hint.technique);
    }

    return SolveResult(s.isSolved, !s.isSolved, steps);
  }

  bool _applyHint(Sudoku s, CandidateMap cand, Hint hint) {
    var changed = false;

    for (final (index, digit) in hint.placements) {
      if (index < 0 || index >= 81) continue;
      if (digit < 1 || digit > 9) continue;
      if (s.cells[index] != digit) {
        s.cells[index] = digit;
        changed = true;
      }
      cand[index].clear();
      cand.removeFromPeers(s, index, digit);
    }

    for (final (index, digit) in hint.eliminations) {
      if (index < 0 || index >= 81) continue;
      if (digit < 1 || digit > 9) continue;
      if (s.cells[index] != 0) continue;
      if (cand[index].remove(digit)) {
        changed = true;
      }
    }

    return changed;
  }

  Hint? _findXYWingHint(Sudoku s, CandidateMap cand) {
    final peers = List.generate(81, (i) => s.peersOf(i));
    for (var pivot = 0; pivot < 81; pivot++) {
      if (s.cells[pivot] != 0 || cand[pivot].length != 2) continue;
      final digits = cand[pivot].toList()..sort();
      final a = digits[0], b = digits[1];
      final wingsA = <int, int>{};
      final wingsB = <int, int>{};
      for (final peer in peers[pivot]) {
        if (s.cells[peer] != 0 || cand[peer].length != 2) continue;
        final values = cand[peer].toList();
        if (values.contains(a) && !values.contains(b)) {
          final z = values.firstWhere((v) => v != a);
          wingsA[peer] = z;
        } else if (values.contains(b) && !values.contains(a)) {
          final z = values.firstWhere((v) => v != b);
          wingsB[peer] = z;
        }
      }
      if (wingsA.isEmpty || wingsB.isEmpty) continue;
      for (final entryA in wingsA.entries) {
        for (final entryB in wingsB.entries) {
          if (entryA.value != entryB.value) continue;
          final z = entryA.value;
          final cellA = entryA.key;
          final cellB = entryB.key;
          final intersection = peers[cellA].intersection(peers[cellB]);
          final eliminations = <(int, int)>[];
          for (final idx in intersection) {
            if (s.cells[idx] != 0) continue;
            if (!cand[idx].contains(z)) continue;
            eliminations.add((idx, z));
          }
          if (eliminations.isEmpty) continue;
          final cells = <int>{pivot, cellA, cellB}.toList()..sort();
          final digitsSet = <int>{a, b, z}.toList()..sort();
          return Hint(
            StrategyUsed.xyWing,
            eliminations: eliminations,
            cells: cells,
            digits: digitsSet,
          );
        }
      }
    }
    return null;
  }

  Hint? _findColoringHint(Sudoku s, CandidateMap cand) {
    final peers = List.generate(81, (i) => s.peersOf(i));
    for (var digit = 1; digit <= 9; digit++) {
      final edges = <int, Set<int>>{};
      void addEdge(int a, int b) {
        edges.putIfAbsent(a, () => <int>{}).add(b);
        edges.putIfAbsent(b, () => <int>{}).add(a);
      }

      for (var r = 0; r < 9; r++) {
        final cells = <int>[];
        for (var c = 0; c < 9; c++) {
          final idx = s.idx(r, c);
          if (s.cells[idx] == 0 && cand[idx].contains(digit)) cells.add(idx);
        }
        if (cells.length == 2) addEdge(cells[0], cells[1]);
      }
      for (var c = 0; c < 9; c++) {
        final cells = <int>[];
        for (var r = 0; r < 9; r++) {
          final idx = s.idx(r, c);
          if (s.cells[idx] == 0 && cand[idx].contains(digit)) cells.add(idx);
        }
        if (cells.length == 2) addEdge(cells[0], cells[1]);
      }
      for (var b = 0; b < 9; b++) {
        final cells = <int>[];
        for (final idx in s.boxIndices(b)) {
          if (s.cells[idx] == 0 && cand[idx].contains(digit)) cells.add(idx);
        }
        if (cells.length == 2) addEdge(cells[0], cells[1]);
      }

      if (edges.isEmpty) continue;
      final colored = <int, bool>{};
      for (final start in edges.keys) {
        if (colored.containsKey(start)) continue;
        final queue = <int>[start];
        colored[start] = false;
        final falseColor = <int>{};
        final trueColor = <int>{};
        var valid = true;
        while (queue.isNotEmpty && valid) {
          final cell = queue.removeLast();
          final colour = colored[cell]!;
          (colour ? trueColor : falseColor).add(cell);
          for (final neighbor in edges[cell] ?? const <int>{}) {
            final desired = !colour;
            final current = colored[neighbor];
            if (current == null) {
              colored[neighbor] = desired;
              queue.add(neighbor);
            } else if (current == colour) {
              valid = false;
              break;
            }
          }
        }
        if (!valid) continue;
        if (falseColor.isEmpty || trueColor.isEmpty) continue;
        final coloredSet = {...falseColor, ...trueColor};
        final eliminations = <(int, int)>[];
        for (var idx = 0; idx < 81; idx++) {
          if (s.cells[idx] != 0) continue;
          if (!cand[idx].contains(digit)) continue;
          if (coloredSet.contains(idx)) continue;
          final peerSet = peers[idx];
          final seesFalse = peerSet.any(falseColor.contains);
          if (!seesFalse) continue;
          final seesTrue = peerSet.any(trueColor.contains);
          if (!seesTrue) continue;
          eliminations.add((idx, digit));
        }
        if (eliminations.isNotEmpty) {
          final cells = coloredSet.toList()..sort();
          return Hint(
            StrategyUsed.coloring,
            eliminations: eliminations,
            cells: cells,
            digits: [digit],
          );
        }
      }
    }
    return null;
  }

  Hint? _findSwordfishHint(Sudoku s, CandidateMap cand) {
    Hint? rowFish(int digit) {
      final rowCols = <int, Set<int>>{};
      for (var r = 0; r < 9; r++) {
        final cols = <int>{};
        for (var c = 0; c < 9; c++) {
          final idx = s.idx(r, c);
          if (s.cells[idx] == 0 && cand[idx].contains(digit)) cols.add(c);
        }
        if (cols.length >= 2 && cols.length <= 3) {
          rowCols[r] = cols;
        }
      }
      final rows = rowCols.keys.toList();
      for (var a = 0; a < rows.length; a++) {
        for (var b = a + 1; b < rows.length; b++) {
          for (var c = b + 1; c < rows.length; c++) {
            final r1 = rows[a], r2 = rows[b], r3 = rows[c];
            final union = {...rowCols[r1]!, ...rowCols[r2]!, ...rowCols[r3]!};
            if (union.length != 3) continue;
            final columns = union.toList()..sort();
            final eliminations = <(int, int)>[];
            for (var r = 0; r < 9; r++) {
              if (r == r1 || r == r2 || r == r3) continue;
              for (final col in columns) {
                final idx = s.idx(r, col);
                if (s.cells[idx] == 0 && cand[idx].contains(digit)) {
                  eliminations.add((idx, digit));
                }
              }
            }
            if (eliminations.isEmpty) continue;
            final pattern = <int>{};
            for (final row in [r1, r2, r3]) {
              for (final col in rowCols[row]!) {
                if (union.contains(col)) {
                  pattern.add(s.idx(row, col));
                }
              }
            }
            final cells = pattern.toList()..sort();
            return Hint(
              StrategyUsed.swordfish,
              eliminations: eliminations,
              cells: cells,
              digits: [digit],
            );
          }
        }
      }
      return null;
    }

    Hint? colFish(int digit) {
      final colRows = <int, Set<int>>{};
      for (var c = 0; c < 9; c++) {
        final rows = <int>{};
        for (var r = 0; r < 9; r++) {
          final idx = s.idx(r, c);
          if (s.cells[idx] == 0 && cand[idx].contains(digit)) rows.add(r);
        }
        if (rows.length >= 2 && rows.length <= 3) {
          colRows[c] = rows;
        }
      }
      final cols = colRows.keys.toList();
      for (var a = 0; a < cols.length; a++) {
        for (var b = a + 1; b < cols.length; b++) {
          for (var c = b + 1; c < cols.length; c++) {
            final c1 = cols[a], c2 = cols[b], c3 = cols[c];
            final union = {...colRows[c1]!, ...colRows[c2]!, ...colRows[c3]!};
            if (union.length != 3) continue;
            final rows = union.toList()..sort();
            final eliminations = <(int, int)>[];
            for (var col = 0; col < 9; col++) {
              if (col == c1 || col == c2 || col == c3) continue;
              for (final row in rows) {
                final idx = s.idx(row, col);
                if (s.cells[idx] == 0 && cand[idx].contains(digit)) {
                  eliminations.add((idx, digit));
                }
              }
            }
            if (eliminations.isEmpty) continue;
            final pattern = <int>{};
            for (final col in [c1, c2, c3]) {
              for (final row in colRows[col]!) {
                if (union.contains(row)) {
                  pattern.add(s.idx(row, col));
                }
              }
            }
            final cells = pattern.toList()..sort();
            return Hint(
              StrategyUsed.swordfish,
              eliminations: eliminations,
              cells: cells,
              digits: [digit],
            );
          }
        }
      }
      return null;
    }

    for (var digit = 1; digit <= 9; digit++) {
      final rowHint = rowFish(digit);
      if (rowHint != null) return rowHint;
      final colHint = colFish(digit);
      if (colHint != null) return colHint;
    }
    return null;
  }

  Hint? _findSkyscraperHint(Sudoku s, CandidateMap cand) {
    final peers = List.generate(81, (i) => s.peersOf(i));
    Set<int> commonPeers(int a, int b) => peers[a].intersection(peers[b]);

    for (var digit = 1; digit <= 9; digit++) {
      final rowLinks = <int, List<int>>{};
      for (var r = 0; r < 9; r++) {
        final cols = <int>[];
        for (var c = 0; c < 9; c++) {
          final idx = s.idx(r, c);
          if (s.cells[idx] == 0 && cand[idx].contains(digit)) cols.add(c);
        }
        if (cols.length == 2) rowLinks[r] = cols;
      }
      final rows = rowLinks.keys.toList();
      for (var i = 0; i < rows.length; i++) {
        for (var j = i + 1; j < rows.length; j++) {
          final r1 = rows[i], r2 = rows[j];
          final cols1 = rowLinks[r1]!;
          final cols2 = rowLinks[r2]!;
          final shared = cols1.toSet().intersection(cols2.toSet()).toList();
          if (shared.length != 1) continue;
          final sharedCol = shared.first;
          final c1 = cols1.firstWhere((c) => c != sharedCol);
          final c2 = cols2.firstWhere((c) => c != sharedCol);
          final base1 = s.idx(r1, sharedCol);
          final base2 = s.idx(r2, sharedCol);
          final end1 = s.idx(r1, c1);
          final end2 = s.idx(r2, c2);
          if (s.cells[end1] != 0 || s.cells[end2] != 0) continue;
          final eliminations = <(int, int)>[];
          for (final idx in commonPeers(end1, end2)) {
            if (s.cells[idx] == 0 && cand[idx].contains(digit)) {
              eliminations.add((idx, digit));
            }
          }
          if (eliminations.isEmpty) continue;
          final cells = <int>{base1, base2, end1, end2}.toList()..sort();
          return Hint(
            StrategyUsed.skyscraper,
            eliminations: eliminations,
            cells: cells,
            digits: [digit],
          );
        }
      }

      final colLinks = <int, List<int>>{};
      for (var c = 0; c < 9; c++) {
        final rowsSet = <int>[];
        for (var r = 0; r < 9; r++) {
          final idx = s.idx(r, c);
          if (s.cells[idx] == 0 && cand[idx].contains(digit)) rowsSet.add(r);
        }
        if (rowsSet.length == 2) colLinks[c] = rowsSet;
      }
      final cols = colLinks.keys.toList();
      for (var i = 0; i < cols.length; i++) {
        for (var j = i + 1; j < cols.length; j++) {
          final c1 = cols[i], c2 = cols[j];
          final rows1 = colLinks[c1]!;
          final rows2 = colLinks[c2]!;
          final shared = rows1.toSet().intersection(rows2.toSet()).toList();
          if (shared.length != 1) continue;
          final sharedRow = shared.first;
          final r1 = rows1.firstWhere((r) => r != sharedRow);
          final r2 = rows2.firstWhere((r) => r != sharedRow);
          final base1 = s.idx(sharedRow, c1);
          final base2 = s.idx(sharedRow, c2);
          final end1 = s.idx(r1, c1);
          final end2 = s.idx(r2, c2);
          if (s.cells[end1] != 0 || s.cells[end2] != 0) continue;
          final eliminations = <(int, int)>[];
          for (final idx in commonPeers(end1, end2)) {
            if (s.cells[idx] == 0 && cand[idx].contains(digit)) {
              eliminations.add((idx, digit));
            }
          }
          if (eliminations.isEmpty) continue;
          final cells = <int>{base1, base2, end1, end2}.toList()..sort();
          return Hint(
            StrategyUsed.skyscraper,
            eliminations: eliminations,
            cells: cells,
            digits: [digit],
          );
        }
      }
    }
    return null;
  }

  Hint? _findTwoStringKiteHint(Sudoku s, CandidateMap cand) {
    for (var digit = 1; digit <= 9; digit++) {
      final rowLinks = <int, List<int>>{};
      final colLinks = <int, List<int>>{};
      for (var r = 0; r < 9; r++) {
        final cols = <int>[];
        for (var c = 0; c < 9; c++) {
          final idx = s.idx(r, c);
          if (s.cells[idx] == 0 && cand[idx].contains(digit)) cols.add(c);
        }
        if (cols.length == 2) rowLinks[r] = cols;
      }
      for (var c = 0; c < 9; c++) {
        final rows = <int>[];
        for (var r = 0; r < 9; r++) {
          final idx = s.idx(r, c);
          if (s.cells[idx] == 0 && cand[idx].contains(digit)) rows.add(r);
        }
        if (rows.length == 2) colLinks[c] = rows;
      }

      for (final r in rowLinks.keys) {
        final cols = rowLinks[r]!;
        final cA = cols[0], cB = cols[1];
        for (final c in colLinks.keys) {
          final rows = colLinks[c]!;
          final rA = rows[0], rB = rows[1];
          final p1 = s.idx(r, cA);
          final p2 = s.idx(r, cB);
          final q1 = s.idx(rA, c);
          final q2 = s.idx(rB, c);
          bool share(int x, int y) => s.boxOf(x) == s.boxOf(y);
          final pairings = [
            (p1, q1, s.idx(rB, cB)),
            (p1, q2, s.idx(rA, cB)),
            (p2, q1, s.idx(rB, cA)),
            (p2, q2, s.idx(rA, cA)),
          ];
          int hits = 0;
          int elimCell = -1;
          for (final triple in pairings) {
            if (share(triple.$1, triple.$2)) {
              hits++;
              elimCell = triple.$3;
            }
          }
          if (hits != 1 || elimCell < 0) continue;
          if (s.cells[elimCell] != 0 || !cand[elimCell].contains(digit)) {
            continue;
          }
          final cells = <int>{p1, p2, q1, q2}.toList()..sort();
          return Hint(
            StrategyUsed.twoStringKite,
            eliminations: [(elimCell, digit)],
            cells: cells,
            digits: [digit],
          );
        }
      }
    }
    return null;
  }

  Hint? _findTurbotFishHint(Sudoku s, CandidateMap cand) => null;

  Hint? _findXYZWingHint(Sudoku s, CandidateMap cand) => null;

  Hint? _findWWingHint(Sudoku s, CandidateMap cand) {
    final strongRow = List.generate(10, (_) => <(int, int)>[]);
    final strongCol = List.generate(10, (_) => <(int, int)>[]);
    for (var digit = 1; digit <= 9; digit++) {
      for (var r = 0; r < 9; r++) {
        final cols = <int>[];
        for (var c = 0; c < 9; c++) {
          final idx = s.idx(r, c);
          if (s.cells[idx] == 0 && cand[idx].contains(digit)) cols.add(c);
        }
        if (cols.length == 2) {
          strongRow[digit].add((r, (cols[0] << 4) | cols[1]));
        }
      }
      for (var c = 0; c < 9; c++) {
        final rows = <int>[];
        for (var r = 0; r < 9; r++) {
          final idx = s.idx(r, c);
          if (s.cells[idx] == 0 && cand[idx].contains(digit)) rows.add(r);
        }
        if (rows.length == 2) {
          strongCol[digit].add((c, (rows[0] << 4) | rows[1]));
        }
      }
    }

    final bivalue = <int, List<int>>{};
    for (var idx = 0; idx < 81; idx++) {
      if (s.cells[idx] == 0 && cand[idx].length == 2) {
        bivalue[idx] = cand[idx].toList()..sort();
      }
    }

    final peers = List.generate(81, (i) => s.peersOf(i));
    bool sees(int cell, int r, int c) =>
        s.rowOf(cell) == r || s.colOf(cell) == c;

    final cells = bivalue.keys.toList();
    for (var i = 0; i < cells.length; i++) {
      for (var j = i + 1; j < cells.length; j++) {
        final i1 = cells[i], i2 = cells[j];
        final pair1 = bivalue[i1]!;
        final pair2 = bivalue[i2]!;
        if (pair1[0] != pair2[0] || pair1[1] != pair2[1]) continue;
        if (s.rowOf(i1) == s.rowOf(i2) ||
            s.colOf(i1) == s.colOf(i2) ||
            s.boxOf(i1) == s.boxOf(i2)) {
          continue;
        }
        final x = pair1[0];
        final y = pair1[1];

        Hint? processLinks(List<(int, int)> links, bool rowMode) {
          for (final (index, packed) in links) {
            final first = (packed >> 4) & 0xF;
            final second = packed & 0xF;
            final cellA = rowMode ? s.idx(index, first) : s.idx(first, index);
            final cellB = rowMode ? s.idx(index, second) : s.idx(second, index);
            final i1A = rowMode
                ? sees(i1, index, first)
                : sees(i1, first, index);
            final i1B = rowMode
                ? sees(i1, index, second)
                : sees(i1, second, index);
            final i2A = rowMode
                ? sees(i2, index, first)
                : sees(i2, first, index);
            final i2B = rowMode
                ? sees(i2, index, second)
                : sees(i2, second, index);
            final matched = (i1A && i2B) || (i1B && i2A);
            if (!matched) continue;
            final inter = peers[i1].intersection(peers[i2]);
            final eliminations = <(int, int)>[];
            for (final idx in inter) {
              if (s.cells[idx] == 0 && cand[idx].contains(y)) {
                eliminations.add((idx, y));
              }
            }
            if (eliminations.isEmpty) continue;
            final cells = <int>{i1, i2, cellA, cellB}.toList()..sort();
            final digits = [x, y];
            return Hint(
              StrategyUsed.wWing,
              eliminations: eliminations,
              cells: cells,
              digits: digits,
            );
          }
          return null;
        }

        final rowHint = processLinks(strongRow[x], true);
        if (rowHint != null) return rowHint;
        final colHint = processLinks(strongCol[x], false);
        if (colHint != null) return colHint;
      }
    }
    return null;
  }

  Hint? _findUniqueRectangleHint(Sudoku s, CandidateMap cand) {
    for (var r1 = 0; r1 < 9; r1++) {
      for (var r2 = r1 + 1; r2 < 9; r2++) {
        for (var c1 = 0; c1 < 9; c1++) {
          for (var c2 = c1 + 1; c2 < 9; c2++) {
            final i1 = s.idx(r1, c1);
            final i2 = s.idx(r1, c2);
            final i3 = s.idx(r2, c1);
            final i4 = s.idx(r2, c2);
            if (s.cells[i1] != 0 ||
                s.cells[i2] != 0 ||
                s.cells[i3] != 0 ||
                s.cells[i4] != 0) {
              continue;
            }
            final corners = [i1, i2, i3, i4];
            for (var a = 1; a <= 9; a++) {
              for (var b = a + 1; b <= 9; b++) {
                final pair = {a, b};
                var subsetCount = 0;
                final supers = <int>[];
                for (final cell in corners) {
                  final candidates = cand[cell];
                  if (candidates.isEmpty) continue;
                  if (candidates.every(pair.contains)) subsetCount++;
                  if (candidates.contains(a) &&
                      candidates.contains(b) &&
                      candidates.length > 2) {
                    supers.add(cell);
                  }
                }
                if (subsetCount >= 3 && supers.isNotEmpty) {
                  final eliminations = <(int, int)>[];
                  for (final cell in supers) {
                    if (cand[cell].contains(a)) eliminations.add((cell, a));
                    if (cand[cell].contains(b)) eliminations.add((cell, b));
                  }
                  if (eliminations.isEmpty) continue;
                  final cells = corners.toSet().toList()..sort();
                  final digits = [a, b];
                  return Hint(
                    StrategyUsed.uniqueRectangle,
                    eliminations: eliminations,
                    cells: cells,
                    digits: digits,
                  );
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  Hint? _findBugHint(Sudoku s, CandidateMap cand) => null;

  Hint? _findRemotePairsHint(Sudoku s, CandidateMap cand) => null;

  Hint? _findXYChainHint(Sudoku s, CandidateMap cand) => null;

  Hint? _findALSHint(Sudoku s, CandidateMap cand) => null;

  Hint? _findALSXyWingHint(Sudoku s, CandidateMap cand) => null;

  Hint? _findAICHint(Sudoku s, CandidateMap cand) => null;

  // Backtracking solver (for uniqueness & classification) -- bitmask version
  bool solveBacktracking(Sudoku s) {
    // bitmask rows/cols/boxes: bit k means digit k is used
    final row = List<int>.filled(9, 0);
    final col = List<int>.filled(9, 0);
    final box = List<int>.filled(9, 0);
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final v = s.cells[r * 9 + c];
        if (v != 0) {
          final b = (r ~/ 3) * 3 + (c ~/ 3);
          final bit = 1 << v;
          if ((row[r] & bit) != 0 ||
              (col[c] & bit) != 0 ||
              (box[b] & bit) != 0) {
            return false;
          }
          row[r] |= bit;
          col[c] |= bit;
          box[b] |= bit;
        }
      }
    }
    List<int> empties = [];
    for (var i = 0; i < 81; i++) {
      if (s.cells[i] == 0) empties.add(i);
    }
    bool dfs(int k) {
      if (k == empties.length) return true;
      // MRV among remaining
      var bestIdx = -1;
      var bestCount = 10;
      var bestMask = 0;
      var bestR = 0, bestC = 0, bestB = 0;
      for (var t = k; t < empties.length; t++) {
        final i = empties[t];
        final r = i ~/ 9, c = i % 9, b = (r ~/ 3) * 3 + (c ~/ 3);
        final used = row[r] | col[c] | box[b];
        var count = 0;
        var mask = 0;
        for (var d = 1; d <= 9; d++) {
          final bit = 1 << d;
          if ((used & bit) == 0) {
            count++;
            mask |= bit;
          }
        }
        if (count < bestCount) {
          bestCount = count;
          bestIdx = t;
          bestMask = mask;
          bestR = r;
          bestC = c;
          bestB = b;
          if (count == 1) break;
        }
      }
      // swap chosen with position k
      final tmp = empties[k];
      empties[k] = empties[bestIdx];
      empties[bestIdx] = tmp;
      final i = empties[k];
      final r = i ~/ 9, c = i % 9, b = (r ~/ 3) * 3 + (c ~/ 3);
      var mask = 0; // recompute for selected
      final used = row[r] | col[c] | box[b];
      for (var d = 1; d <= 9; d++) {
        final bit = 1 << d;
        if ((used & bit) == 0) mask |= bit;
      }
      for (var d = 1; d <= 9; d++) {
        final bit = 1 << d;
        if ((mask & bit) == 0) continue;
        s.cells[i] = d;
        row[r] |= bit;
        col[c] |= bit;
        box[b] |= bit;
        if (dfs(k + 1)) return true;
        row[r] &= ~bit;
        col[c] &= ~bit;
        box[b] &= ~bit;
        s.cells[i] = 0;
      }
      return false;
    }

    return dfs(0);
  }

  int countSolutions(Sudoku s, {int limit = 2}) {
    final row = List<int>.filled(9, 0);
    final col = List<int>.filled(9, 0);
    final box = List<int>.filled(9, 0);
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final v = s.cells[r * 9 + c];
        if (v != 0) {
          final b = (r ~/ 3) * 3 + (c ~/ 3);
          final bit = 1 << v;
          if ((row[r] & bit) != 0 ||
              (col[c] & bit) != 0 ||
              (box[b] & bit) != 0) {
            return 0;
          }
          row[r] |= bit;
          col[c] |= bit;
          box[b] |= bit;
        }
      }
    }
    List<int> empties = [];
    for (var i = 0; i < 81; i++) {
      if (s.cells[i] == 0) empties.add(i);
    }
    int solutions = 0;
    bool dfs(int k) {
      if (k == empties.length) {
        solutions++;
        return solutions >= limit;
      }
      // MRV
      var bestIdx = -1;
      var bestCount = 10;
      for (var t = k; t < empties.length; t++) {
        final i = empties[t],
            r = i ~/ 9,
            c = i % 9,
            b = (r ~/ 3) * 3 + (c ~/ 3);
        final used = row[r] | col[c] | box[b];
        var cnt = 0;
        for (var d = 1; d <= 9; d++) {
          final bit = 1 << d;
          if ((used & bit) == 0) cnt++;
        }
        if (cnt < bestCount) {
          bestCount = cnt;
          bestIdx = t;
          if (cnt == 1) break;
        }
      }
      final tmp = empties[k];
      empties[k] = empties[bestIdx];
      empties[bestIdx] = tmp;
      final i = empties[k], r = i ~/ 9, c = i % 9, b = (r ~/ 3) * 3 + (c ~/ 3);
      final used = row[r] | col[c] | box[b];
      for (var d = 1; d <= 9; d++) {
        final bit = 1 << d;
        if ((used & bit) != 0) continue;
        s.cells[i] = d;
        row[r] |= bit;
        col[c] |= bit;
        box[b] |= bit;
        if (dfs(k + 1)) return true;
        row[r] &= ~bit;
        col[c] &= ~bit;
        box[b] &= ~bit;
        s.cells[i] = 0;
      }
      return false;
    }

    dfs(0);
    return solutions;
  }

  Rating rateLogical(
    Sudoku s, {
    bool allowHiddenSingles = true,
    bool allowLocked = true,
    bool allowPairs = true,
    bool allowTriples = true,
    bool allowQuads = true,
    bool allowHiddenSubsets = true,
    bool allowXWing = true,
    bool allowXYWing = true,
    bool allowColoring = true,
    bool allowSwordfish = true,
    bool allowSkyscraper = true,
    bool allowTwoStringKite = true,
    bool allowTurbotFish = true,
    bool allowXYZWing = true,
    bool allowWWing = true,
    bool allowUR = true,
    bool allowBUG = true,
    bool allowRemotePairs = true,
    bool allowXYChain = true,
    bool allowALS = true,
    bool allowALSXYWing = true,
    bool allowAIC = true,
  }) {
    final copy = Sudoku(List<int>.from(s.cells));
    final res = solveLogical(
      copy,
      allowHiddenSingles: allowHiddenSingles,
      allowLocked: allowLocked,
      allowPairs: allowPairs,
      allowTriples: allowTriples,
      allowQuads: allowQuads,
      allowHiddenSubsets: allowHiddenSubsets,
      allowXWing: allowXWing,
      allowXYWing: allowXYWing,
      allowColoring: allowColoring,
      allowSwordfish: allowSwordfish,
      allowSkyscraper: allowSkyscraper,
      allowTwoStringKite: allowTwoStringKite,
      allowTurbotFish: allowTurbotFish,
      allowXYZWing: allowXYZWing,
      allowWWing: allowWWing,
      allowUR: allowUR,
      allowBUG: allowBUG,
      allowRemotePairs: allowRemotePairs,
      allowXYChain: allowXYChain,
      allowALS: allowALS,
      allowALSXYWing: allowALSXYWing,
      allowAIC: allowAIC,
    );
    var hardest = 0;
    final counts = <StrategyUsed, int>{};
    final first = <StrategyUsed, int>{};
    for (var i = 0; i < res.steps.length; i++) {
      final st = res.steps[i];
      final idx = strategyDifficultyIndex(st);
      if (idx > hardest) hardest = idx;
      counts[st] = (counts[st] ?? 0) + 1;
      first.putIfAbsent(st, () => i);
    }
    return Rating(
      res.solved
          ? Difficulty.trivial
          : Difficulty
                .impossible, // bucket is not used by distance; keep trivial placeholder
      hardest,
      counts,
      first,
    );
  }
}
