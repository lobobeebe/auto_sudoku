import 'candidate_map.dart';
import 'difficulty.dart';
import 'hint.dart';
import 'rating.dart';
import 'solve_result.dart';
import 'strategy.dart';
import 'sudoku.dart';

class Solver {
  // Supported logical techniques in increasing difficulty order
  static const List<StrategyUsed> difficultyOrder = strategyDifficultyOrder;

  // A simple hint structure for UI/assistive solving
  Hint? nextHint(Sudoku s, {bool allowTriples = true, bool allowXWing = true}) {
    // Non-destructive pass: compute candidates, then scan for techniques
    final cand = CandidateMap.fromBoard(s);

    // 1) Naked Single
    for (var i = 0; i < 81; i++) {
      if (s.cells[i] == 0 && cand[i].length == 1) {
        final v = cand[i].first;
        return Hint(
          StrategyUsed.nakedSingle,
          description:
              'Naked Single at r${s.rowOf(i) + 1}c${s.colOf(i) + 1} = $v',
          placements: [(i, v)],
        );
      }
    }

    // 2) Hidden Single (scan units)
    Hint? hiddenSingle() {
      Hint? checkUnit(Iterable<int> unit) {
        final positionsByDigit = List.generate(10, (_) => <int>[]);
        for (final i in unit) {
          if (s.cells[i] == 0) {
            for (final d in cand[i]) positionsByDigit[d].add(i);
          }
        }
        for (var d = 1; d <= 9; d++) {
          final pos = positionsByDigit[d];
          if (pos.length == 1) {
            final i = pos.first;
            return Hint(
              StrategyUsed.hiddenSingle,
              description:
                  'Hidden Single ${d} only fits at r${s.rowOf(i) + 1}c${s.colOf(i) + 1}',
              placements: [(i, d)],
            );
          }
        }
        return null;
      }

      for (var r = 0; r < 9; r++) {
        final h = checkUnit(s.rowIndices(r));
        if (h != null) return h;
      }
      for (var c = 0; c < 9; c++) {
        final h = checkUnit(s.colIndices(c));
        if (h != null) return h;
      }
      for (var b = 0; b < 9; b++) {
        final h = checkUnit(s.boxIndices(b));
        if (h != null) return h;
      }
      return null;
    }

    final hs = hiddenSingle();
    if (hs != null) return hs;

    // 3) Locked Candidates (Pointing/Claiming)
    final locked = _findLockedHint(s, cand);
    if (locked != null) return locked;

    // 4) Naked/Hidden Pairs
    Hint? pairHint = _findSubsetHint(s, cand, 2);
    if (pairHint != null) return pairHint;

    // 5) Triples (optional)
    if (allowTriples) {
      final tripleHint = _findSubsetHint(s, cand, 3);
      if (tripleHint != null) return tripleHint;
    }

    // 6) X-Wing (optional)
    if (allowXWing) {
      final xh = _findXWingHint(s, cand);
      if (xh != null) return xh;
    }

    return null; // no logical hint available
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
              description:
                  'Locked Candidates (Pointing) for $d in box ${b + 1} restricts row ${r + 1}',
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
              description:
                  'Locked Candidates (Pointing) for $d in box ${b + 1} restricts col ${c + 1}',
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
              description:
                  'Locked Candidates (Claiming) for $d in row ${r + 1} restricts box ${b + 1}',
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
              description:
                  'Locked Candidates (Claiming) for $d in col ${c + 1} restricts box ${b + 1}',
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

  // Helper to find a subset hint (naked/hidden, k in {2,3})
  Hint? _findSubsetHint(Sudoku s, CandidateMap cand, int k) {
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
                  description:
                      'Naked Pair {${set.join(',')}} in unit eliminates elsewhere',
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
                  if (i == empties[a] || i == empties[b] || i == empties[c])
                    continue;
                  for (final v in set) {
                    if (cand[i].contains(v)) others.add((i, v));
                  }
                }
                if (others.isNotEmpty) {
                  return Hint(
                    k == 3 ? StrategyUsed.nakedTriple : StrategyUsed.nakedQuad,
                    description:
                        'Naked ${k == 3 ? 'Triple' : 'Quad'} {${set.join(',')}} in unit eliminates elsewhere',
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
        for (final d in cand[i]) locs[d].add(i);
      }
      for (var d = 1; d <= 9; d++) {
        final pos = locs[d];
        if (pos.length >= 2 && pos.length <= k) {
          final union = <int>{};
          for (final i in pos) union.addAll(cand[i]);
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
                description:
                    'Hidden ${k == 2
                        ? 'Pair'
                        : k == 3
                        ? 'Triple'
                        : 'Quad'} locks digits {${union.join(',')}} into specific cells',
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
          processUnitHidden(s.rowIndices(r));
      if (h != null) return h;
    }
    for (var c = 0; c < 9; c++) {
      final h =
          processUnitNaked(s.colIndices(c)) ??
          processUnitHidden(s.colIndices(c));
      if (h != null) return h;
    }
    for (var b = 0; b < 9; b++) {
      final h =
          processUnitNaked(s.boxIndices(b)) ??
          processUnitHidden(s.boxIndices(b));
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
              if (s.cells[i1] == 0 && cand[i1].contains(d))
                eliminations.add((i1, d));
              if (s.cells[i2] == 0 && cand[i2].contains(d))
                eliminations.add((i2, d));
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
                description:
                    'X-Wing on digit $d across rows ${r1 + 1} & ${r2 + 1} and cols ${c1 + 1}/${c2 + 1}',
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
              if (s.cells[i1] == 0 && cand[i1].contains(d))
                eliminations.add((i1, d));
              if (s.cells[i2] == 0 && cand[i2].contains(d))
                eliminations.add((i2, d));
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
                description:
                    'X-Wing on digit $d across cols ${c1 + 1} & ${c2 + 1} and rows ${r1 + 1}/${r2 + 1}',
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
    bool progress = true;
    while (!s.isSolved && progress) {
      progress = false;
      // Recompute candidates lazily for filled cells
      if (!cand.isNotesDriven) {
        for (var i = 0; i < 81; i++) {
          if (s.cells[i] == 0 && cand[i].isEmpty) {
            for (var d = 1; d <= 9; d++) {
              if (s.isValidPlacement(i, d)) cand[i].add(d);
            }
          }
        }
      }
      // 1) Naked Singles
      for (var i = 0; i < 81; i++) {
        if (s.cells[i] == 0 && cand[i].length == 1) {
          final v = cand[i].first;
          s.cells[i] = v;
          cand.removeFromPeers(s, i, v);
          steps.add(StrategyUsed.nakedSingle);
          progress = true;
        }
      }
      if (progress) continue;
      // 2) Hidden Singles in units
      if (allowHiddenSingles && _hiddenSingle(s, cand)) {
        steps.add(StrategyUsed.hiddenSingle);
        progress = true;
        continue;
      }
      // Locked Candidates
      if (allowLocked) {
        if (_pointing(s, cand)) {
          steps.add(StrategyUsed.pointing);
          progress = true;
          continue;
        }
        if (_claiming(s, cand)) {
          steps.add(StrategyUsed.claiming);
          progress = true;
          continue;
        }
      }
      // Pairs
      if (allowPairs) {
        if (_nakedSubset(s, cand, 2)) {
          steps.add(StrategyUsed.nakedPair);
          progress = true;
          continue;
        }
        if (allowHiddenSubsets && _hiddenSubset(s, cand, 2)) {
          steps.add(StrategyUsed.hiddenPair);
          progress = true;
          continue;
        }
      }
      // Triples
      if (allowTriples) {
        if (_nakedSubset(s, cand, 3)) {
          steps.add(StrategyUsed.nakedTriple);
          progress = true;
          continue;
        }
        if (allowHiddenSubsets && _hiddenSubset(s, cand, 3)) {
          steps.add(StrategyUsed.hiddenTriple);
          progress = true;
          continue;
        }
      }
      // Quads
      if (allowQuads) {
        if (_nakedSubset(s, cand, 4)) {
          steps.add(StrategyUsed.nakedQuad);
          progress = true;
          continue;
        }
        if (allowHiddenSubsets && _hiddenSubset(s, cand, 4)) {
          steps.add(StrategyUsed.hiddenQuad);
          progress = true;
          continue;
        }
      }
      if (allowXWing) {
        if (_xWing(s, cand)) {
          steps.add(StrategyUsed.xWing);
          progress = true;
          continue;
        }
      }
      if (allowXYWing) {
        if (_xyWing(s, cand)) {
          steps.add(StrategyUsed.xyWing);
          progress = true;
          continue;
        }
      }
      if (allowColoring && _coloring(s, cand)) {
        steps.add(StrategyUsed.coloring);
        progress = true;
        continue;
      }
      if (allowSwordfish && _swordfish(s, cand)) {
        steps.add(StrategyUsed.swordfish);
        progress = true;
        continue;
      }
      if (allowSkyscraper && _skyscraper(s, cand)) {
        steps.add(StrategyUsed.skyscraper);
        progress = true;
        continue;
      }
      if (allowTwoStringKite && _twoStringKite(s, cand)) {
        steps.add(StrategyUsed.twoStringKite);
        progress = true;
        continue;
      }
      if (allowTurbotFish && _turbotFish(s, cand)) {
        steps.add(StrategyUsed.turbotFish);
        progress = true;
        continue;
      }
      if (allowXYZWing && _xyzWing(s, cand)) {
        steps.add(StrategyUsed.xyzWing);
        progress = true;
        continue;
      }
      if (allowWWing && _wWing(s, cand)) {
        steps.add(StrategyUsed.wWing);
        progress = true;
        continue;
      }
      if (allowUR && _uniqueRectangle(s, cand)) {
        steps.add(StrategyUsed.uniqueRectangle);
        progress = true;
        continue;
      }
      if (allowBUG && _bug(s, cand)) {
        steps.add(StrategyUsed.bug);
        progress = true;
        continue;
      }
      if (allowRemotePairs && _remotePairs(s, cand)) {
        steps.add(StrategyUsed.remotePairs);
        progress = true;
        continue;
      }
      if (allowXYChain && _xyChain(s, cand)) {
        steps.add(StrategyUsed.xyChain);
        progress = true;
        continue;
      }
      if (allowALS && _als(s, cand)) {
        steps.add(StrategyUsed.als);
        progress = true;
        continue;
      }
      if (allowALSXYWing && _alsXyWing(s, cand)) {
        steps.add(StrategyUsed.alsXyWing);
        progress = true;
        continue;
      }
      if (allowAIC && _aic(s, cand)) {
        steps.add(StrategyUsed.aic);
        progress = true;
        continue;
      }
    }
    return SolveResult(s.isSolved, !s.isSolved, steps);
  }

  bool _xyWing(Sudoku s, CandidateMap cand) {
    bool changed = false;
    final peerSets = List.generate(81, (i) => s.peersOf(i));
    for (var i = 0; i < 81; i++) {
      if (s.cells[i] != 0 || cand[i].length != 2) continue;
      final pivot = i;
      final pv = cand[pivot].toList();
      final a = pv[0], b = pv[1];
      final peers = peerSets[pivot];
      final ax = <int, int>{};
      final bx = <int, int>{};
      for (final p in peers) {
        if (s.cells[p] == 0 && cand[p].length == 2) {
          final two = cand[p].toList();
          final x = two[0], y = two[1];
          if (two.contains(a) && !two.contains(b)) {
            final z = (x == a) ? y : x;
            ax[p] = z;
          } else if (two.contains(b) && !two.contains(a)) {
            final z = (x == b) ? y : x;
            bx[p] = z;
          }
        }
      }
      if (ax.isEmpty || bx.isEmpty) continue;
      for (final e1 in ax.entries) {
        for (final e2 in bx.entries) {
          final z = e1.value;
          if (e2.value != z) continue;
          final A = e1.key;
          final B = e2.key;
          final intersect = peerSets[A].intersection(peerSets[B]);
          for (final q in intersect) {
            if (s.cells[q] == 0 && cand[q].remove(z)) changed = true;
          }
          if (changed) return true;
        }
      }
    }
    return changed;
  }

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
          if ((row[r] & bit) != 0 || (col[c] & bit) != 0 || (box[b] & bit) != 0)
            return false;
          row[r] |= bit;
          col[c] |= bit;
          box[b] |= bit;
        }
      }
    }
    List<int> empties = [];
    for (var i = 0; i < 81; i++) if (s.cells[i] == 0) empties.add(i);
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
          if ((row[r] & bit) != 0 || (col[c] & bit) != 0 || (box[b] & bit) != 0)
            return 0;
          row[r] |= bit;
          col[c] |= bit;
          box[b] |= bit;
        }
      }
    }
    List<int> empties = [];
    for (var i = 0; i < 81; i++) if (s.cells[i] == 0) empties.add(i);
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

  // --- Strategy helpers ---
  bool _hiddenSingle(Sudoku s, CandidateMap cand) {
    // For each unit, for each digit, if it appears in candidates only once -> place it
    bool placed = false;
    bool checkUnit(Iterable<int> unit) {
      final positionsByDigit = List.generate(10, (_) => <int>[]);
      for (final i in unit) {
        if (s.cells[i] == 0) {
          for (final d in cand[i]) positionsByDigit[d].add(i);
        }
      }
      for (var d = 1; d <= 9; d++) {
        final pos = positionsByDigit[d];
        if (pos.length == 1) {
          final i = pos.first;
          s.cells[i] = d;
          cand.removeFromPeers(s, i, d);
          placed = true;
        }
      }
      return placed;
    }

    for (var r = 0; r < 9; r++) {
      if (checkUnit(s.rowIndices(r))) return true;
    }
    for (var c = 0; c < 9; c++) {
      if (checkUnit(s.colIndices(c))) return true;
    }
    for (var b = 0; b < 9; b++) {
      if (checkUnit(s.boxIndices(b))) return true;
    }
    return placed;
  }

  bool _nakedSubset(Sudoku s, CandidateMap cand, int k) {
    bool changed = false;
    bool processUnit(Iterable<int> unit) {
      final empties = unit.where((i) => s.cells[i] == 0).toList();
      // Find subsets of size k whose combined candidate set has size k
      for (var a = 0; a < empties.length; a++) {
        for (var b = a + 1; b < empties.length; b++) {
          if (k == 2) {
            final set = {...cand[empties[a]], ...cand[empties[b]]};
            if (set.length == 2 &&
                (cand[empties[a]].length <= 2) &&
                (cand[empties[b]].length <= 2)) {
              for (final i in empties) {
                if (i == empties[a] || i == empties[b]) continue;
                changed |= cand[i].remove(set.first) | cand[i].remove(set.last);
              }
            }
          } else if (k == 3) {
            for (var c = b + 1; c < empties.length; c++) {
              final set = {
                ...cand[empties[a]],
                ...cand[empties[b]],
                ...cand[empties[c]],
              };
              if (set.length == 3 &&
                  cand[empties[a]].length <= 3 &&
                  cand[empties[b]].length <= 3 &&
                  cand[empties[c]].length <= 3) {
                for (final i in empties) {
                  if (i == empties[a] || i == empties[b] || i == empties[c])
                    continue;
                  for (final v in set) changed |= cand[i].remove(v);
                }
              }
            }
          } else if (k == 4) {
            for (var c = b + 1; c < empties.length; c++) {
              for (var d = c + 1; d < empties.length; d++) {
                final set = {
                  ...cand[empties[a]],
                  ...cand[empties[b]],
                  ...cand[empties[c]],
                  ...cand[empties[d]],
                };
                if (set.length == 4 &&
                    cand[empties[a]].length <= 4 &&
                    cand[empties[b]].length <= 4 &&
                    cand[empties[c]].length <= 4 &&
                    cand[empties[d]].length <= 4) {
                  for (final i in empties) {
                    if (i == empties[a] ||
                        i == empties[b] ||
                        i == empties[c] ||
                        i == empties[d])
                      continue;
                    for (final v in set) changed |= cand[i].remove(v);
                  }
                }
              }
            }
          }
        }
      }
      return changed;
    }

    for (var r = 0; r < 9; r++) if (processUnit(s.rowIndices(r))) return true;
    for (var c = 0; c < 9; c++) if (processUnit(s.colIndices(c))) return true;
    for (var b = 0; b < 9; b++) if (processUnit(s.boxIndices(b))) return true;
    return changed;
  }

  bool _pointing(Sudoku s, CandidateMap cand) {
    bool changed = false;
    for (var b = 0; b < 9; b++) {
      final cells = s.boxIndices(b).toList();
      for (var d = 1; d <= 9; d++) {
        final inBox = cells
            .where((i) => s.cells[i] == 0 && cand[i].contains(d))
            .toList();
        if (inBox.isEmpty) continue;
        final rows = inBox.map(s.rowOf).toSet();
        if (rows.length == 1) {
          final r = rows.first;
          for (final i in s.rowIndices(r)) {
            if (!cells.contains(i)) {
              changed |= cand[i].remove(d);
            }
          }
          if (changed) return true;
        }
        final cols = inBox.map(s.colOf).toSet();
        if (cols.length == 1) {
          final c = cols.first;
          for (final i in s.colIndices(c)) {
            if (!cells.contains(i)) {
              changed |= cand[i].remove(d);
            }
          }
          if (changed) return true;
        }
      }
    }
    return changed;
  }

  bool _claiming(Sudoku s, CandidateMap cand) {
    bool changed = false;
    // rows -> boxes
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
          for (final i in s.boxIndices(b)) {
            if (s.rowOf(i) != r) changed |= cand[i].remove(d);
          }
          if (changed) return true;
        }
      }
    }
    // cols -> boxes
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
          for (final i in s.boxIndices(b)) {
            if (s.colOf(i) != c) changed |= cand[i].remove(d);
          }
          if (changed) return true;
        }
      }
    }
    return changed;
  }

  // --- Advanced techniques ---
  bool _coloring(Sudoku s, CandidateMap cand) {
    bool changed = false;
    // For each digit, build conjugate graph (strong links) across rows, cols, and boxes.
    for (var d = 1; d <= 9; d++) {
      final edges = <int, Set<int>>{}; // cell -> neighbors via strong links
      void addEdge(int a, int b) {
        edges.putIfAbsent(a, () => <int>{}).add(b);
        edges.putIfAbsent(b, () => <int>{}).add(a);
      }

      // Rows: if digit appears in exactly two cells in a row, add a strong link
      for (var r = 0; r < 9; r++) {
        final pos = <int>[];
        for (var c = 0; c < 9; c++) {
          final i = s.idx(r, c);
          if (s.cells[i] == 0 && cand[i].contains(d)) pos.add(i);
        }
        if (pos.length == 2) addEdge(pos[0], pos[1]);
      }
      // Cols
      for (var c = 0; c < 9; c++) {
        final pos = <int>[];
        for (var r = 0; r < 9; r++) {
          final i = s.idx(r, c);
          if (s.cells[i] == 0 && cand[i].contains(d)) pos.add(i);
        }
        if (pos.length == 2) addEdge(pos[0], pos[1]);
      }
      // Boxes
      for (var b = 0; b < 9; b++) {
        final pos = <int>[];
        for (final i in s.boxIndices(b)) {
          if (s.cells[i] == 0 && cand[i].contains(d)) pos.add(i);
        }
        if (pos.length == 2) addEdge(pos[0], pos[1]);
      }

      if (edges.isEmpty) continue;
      final colored = <int, bool>{}; // cell -> color (false/true)

      // Two-color each connected component
      for (final start in edges.keys) {
        if (colored.containsKey(start)) continue;
        colored[start] = false;
        final queue = <int>[start];
        final compFalse = <int>{};
        final compTrue = <int>{};
        while (queue.isNotEmpty) {
          final u = queue.removeLast();
          final col = colored[u]!;
          if (col)
            compTrue.add(u);
          else
            compFalse.add(u);
          for (final v in edges[u] ?? const <int>{}) {
            final want = !col;
            final cur = colored[v];
            if (cur == null) {
              colored[v] = want;
              queue.add(v);
            } else if (cur == col) {
              // Contradiction inside a component; skip advanced handling.
            }
          }
        }

        // Color trap eliminations: any other candidate that sees both colors loses d
        final compAll = {...compFalse, ...compTrue};
        for (var i = 0; i < 81; i++) {
          if (s.cells[i] != 0) continue;
          if (!cand[i].contains(d)) continue;
          if (compAll.contains(i))
            continue; // we only eliminate in uncolored cells
          final peers = s.peersOf(i);
          bool seeFalse = peers.any((p) => compFalse.contains(p));
          if (!seeFalse) continue;
          bool seeTrue = peers.any((p) => compTrue.contains(p));
          if (!seeTrue) continue;
          if (cand[i].remove(d)) {
            changed = true;
            // Early return on first elimination for performance in solve loop
            return true;
          }
        }
      }
    }
    return changed;
  }

  bool _swordfish(Sudoku s, CandidateMap cand) {
    bool changed = false;

    bool rowFish(int d) {
      // For digit d, collect rows whose candidate columns count is 2 or 3
      final rowCols = <int, Set<int>>{}; // row -> columns where d is candidate
      for (var r = 0; r < 9; r++) {
        final cols = <int>{};
        for (var c = 0; c < 9; c++) {
          final i = s.idx(r, c);
          if (s.cells[i] == 0 && cand[i].contains(d)) cols.add(c);
        }
        if (cols.length >= 2 && cols.length <= 3) rowCols[r] = cols;
      }
      final rows = rowCols.keys.toList();
      for (var a = 0; a < rows.length; a++) {
        for (var b = a + 1; b < rows.length; b++) {
          for (var c = b + 1; c < rows.length; c++) {
            final r1 = rows[a], r2 = rows[b], r3 = rows[c];
            final union = {...rowCols[r1]!, ...rowCols[r2]!, ...rowCols[r3]!};
            if (union.length != 3)
              continue; // Swordfish requires exactly 3 columns total
            final cols = union.toList();
            // Eliminate d from other rows in these 3 columns
            bool localChanged = false;
            for (var r = 0; r < 9; r++) {
              if (r == r1 || r == r2 || r == r3) continue;
              for (final col in cols) {
                final i = s.idx(r, col);
                if (s.cells[i] == 0 && cand[i].remove(d)) localChanged = true;
              }
            }
            if (localChanged) return true;
          }
        }
      }
      return false;
    }

    bool colFish(int d) {
      // Transposed version: columns with 2 or 3 candidate rows
      final colRows = <int, Set<int>>{}; // col -> rows where d is candidate
      for (var c = 0; c < 9; c++) {
        final rows = <int>{};
        for (var r = 0; r < 9; r++) {
          final i = s.idx(r, c);
          if (s.cells[i] == 0 && cand[i].contains(d)) rows.add(r);
        }
        if (rows.length >= 2 && rows.length <= 3) colRows[c] = rows;
      }
      final cols = colRows.keys.toList();
      for (var a = 0; a < cols.length; a++) {
        for (var b = a + 1; b < cols.length; b++) {
          for (var c = b + 1; c < cols.length; c++) {
            final c1 = cols[a], c2 = cols[b], c3 = cols[c];
            final union = {...colRows[c1]!, ...colRows[c2]!, ...colRows[c3]!};
            if (union.length != 3) continue; // exactly 3 rows
            final rows3 = union.toList();
            bool localChanged = false;
            for (var col = 0; col < 9; col++) {
              if (col == c1 || col == c2 || col == c3) continue;
              for (final r in rows3) {
                final i = s.idx(r, col);
                if (s.cells[i] == 0 && cand[i].remove(d)) localChanged = true;
              }
            }
            if (localChanged) return true;
          }
        }
      }
      return false;
    }

    for (var d = 1; d <= 9; d++) {
      if (rowFish(d)) return true;
      if (colFish(d)) return true;
    }
    return changed;
  }

  bool _skyscraper(Sudoku s, CandidateMap cand) {
    bool changed = false;

    // Helper: intersection of peers of two cells
    Set<int> _commonPeers(int a, int b) {
      final pa = s.peersOf(a);
      final pb = s.peersOf(b);
      return pa.intersection(pb);
    }

    for (var d = 1; d <= 9; d++) {
      // ROW-BASED: find two rows each with exactly two candidates for d,
      // sharing exactly one column. Eliminate d from cells that see both
      // "far" endpoints (the non-shared columns).
      final rowToCols = <int, List<int>>{};
      for (var r = 0; r < 9; r++) {
        final cols = <int>[];
        for (var c = 0; c < 9; c++) {
          final i = s.idx(r, c);
          if (s.cells[i] == 0 && cand[i].contains(d)) cols.add(c);
        }
        if (cols.length == 2) rowToCols[r] = cols;
      }
      final rows = rowToCols.keys.toList();
      for (var i = 0; i < rows.length; i++) {
        for (var j = i + 1; j < rows.length; j++) {
          final r1 = rows[i], r2 = rows[j];
          final a = rowToCols[r1]!;
          final b = rowToCols[r2]!;
          // Shared exactly one column?
          final shared = a.toSet().intersection(b.toSet()).toList();
          if (shared.length != 1) continue;
          final sharedC = shared.first;
          final c1 = a.firstWhere((c) => c != sharedC);
          final c2 = b.firstWhere((c) => c != sharedC);
          final e1 = s.idx(r1, c1); // far endpoints
          final e2 = s.idx(r2, c2);
          if (!(s.cells[e1] == 0 && s.cells[e2] == 0)) continue;
          // Eliminations: any unfilled cell that sees both e1 and e2
          for (final q in _commonPeers(e1, e2)) {
            if (s.cells[q] == 0 && cand[q].remove(d)) {
              changed = true;
            }
          }
          if (changed) return true;
        }
      }

      // COLUMN-BASED: transpose the logic
      final colToRows = <int, List<int>>{};
      for (var c = 0; c < 9; c++) {
        final rowsSet = <int>[];
        for (var r = 0; r < 9; r++) {
          final i = s.idx(r, c);
          if (s.cells[i] == 0 && cand[i].contains(d)) rowsSet.add(r);
        }
        if (rowsSet.length == 2) colToRows[c] = rowsSet;
      }
      final cols = colToRows.keys.toList();
      for (var i = 0; i < cols.length; i++) {
        for (var j = i + 1; j < cols.length; j++) {
          final c1 = cols[i], c2 = cols[j];
          final a = colToRows[c1]!; // two rows
          final b = colToRows[c2]!;
          final shared = a.toSet().intersection(b.toSet()).toList();
          if (shared.length != 1) continue;
          final sharedR = shared.first;
          final r1 = a.firstWhere((r) => r != sharedR);
          final r2 = b.firstWhere((r) => r != sharedR);
          final e1 = s.idx(r1, c1);
          final e2 = s.idx(r2, c2);
          if (!(s.cells[e1] == 0 && s.cells[e2] == 0)) continue;
          for (final q in _commonPeers(e1, e2)) {
            if (s.cells[q] == 0 && cand[q].remove(d)) {
              changed = true;
            }
          }
          if (changed) return true;
        }
      }
    }
    return changed;
  }

  bool _twoStringKite(Sudoku s, CandidateMap cand) {
    bool changed = false;

    // For each digit, combine one row-strong-link and one column-strong-link
    // where exactly one pair of endpoints lies in the same 3x3 box.
    // Then eliminate the digit at the opposite intersection cell.
    for (var d = 1; d <= 9; d++) {
      // Collect strong links per row and per column
      final rowToCols = <int, List<int>>{};
      for (var r = 0; r < 9; r++) {
        final cols = <int>[];
        for (var c = 0; c < 9; c++) {
          final i = s.idx(r, c);
          if (s.cells[i] == 0 && cand[i].contains(d)) cols.add(c);
        }
        if (cols.length == 2) rowToCols[r] = cols;
      }
      final colToRows = <int, List<int>>{};
      for (var c = 0; c < 9; c++) {
        final rows = <int>[];
        for (var r = 0; r < 9; r++) {
          final i = s.idx(r, c);
          if (s.cells[i] == 0 && cand[i].contains(d)) rows.add(r);
        }
        if (rows.length == 2) colToRows[c] = rows;
      }

      for (final r in rowToCols.keys) {
        final rc = rowToCols[r]!; // two columns in row r
        final rcA = rc[0], rcB = rc[1];
        for (final c in colToRows.keys) {
          final cr = colToRows[c]!; // two rows in col c
          final crA = cr[0], crB = cr[1];

          // Endpoints
          final p1 = s.idx(r, rcA);
          final p2 = s.idx(r, rcB);
          final q1 = s.idx(crA, c);
          final q2 = s.idx(crB, c);

          // Try four pairings; if exactly one pairing shares a box, eliminate at the opposite intersection
          bool share(int a, int b) => s.boxOf(a) == s.boxOf(b);

          final pairs = [
            (
              p1,
              q1,
              s.idx(crB, rcB),
            ), // p1~q1 share box -> eliminate at opposite r=crB,c=rcB
            (
              p1,
              q2,
              s.idx(crA, rcB),
            ), // p1~q2 share box -> eliminate at r=crA,c=rcB
            (
              p2,
              q1,
              s.idx(crB, rcA),
            ), // p2~q1 share box -> eliminate at r=crB,c=rcA
            (
              p2,
              q2,
              s.idx(crA, rcA),
            ), // p2~q2 share box -> eliminate at r=crA,c=rcA
          ];

          int hits = 0;
          int elimCell = -1;
          for (final t in pairs) {
            final a = t.$1, b = t.$2, opp = t.$3;
            if (share(a, b)) {
              hits++;
              elimCell = opp;
            }
          }
          if (hits == 1 && elimCell >= 0) {
            // Valid two-string kite; eliminate d at the opposite intersection if present
            if (s.cells[elimCell] == 0 && cand[elimCell].remove(d)) {
              return true;
            }
          }
        }
      }
    }

    return changed;
  }

  bool _turbotFish(Sudoku s, CandidateMap cand) {
    return false;
  } // TODO

  bool _xyzWing(Sudoku s, CandidateMap cand) {
    return false;
  } // TODO

  bool _wWing(Sudoku s, CandidateMap cand) {
    // Build conjugate links for each digit in rows and columns
    final strongRow = List.generate(10, (_) => <(int, int)>[]); // (r, c1|c2)
    final strongCol = List.generate(10, (_) => <(int, int)>[]); // (c, r1|r2)

    for (var d = 1; d <= 9; d++) {
      // Rows
      for (var r = 0; r < 9; r++) {
        final cols = <int>[];
        for (var c = 0; c < 9; c++) {
          final i = s.idx(r, c);
          if (s.cells[i] == 0 && cand[i].contains(d)) cols.add(c);
        }
        if (cols.length == 2) strongRow[d].add((r, (cols[0] << 4) | cols[1]));
      }
      // Cols
      for (var c = 0; c < 9; c++) {
        final rows = <int>[];
        for (var r = 0; r < 9; r++) {
          final i = s.idx(r, c);
          if (s.cells[i] == 0 && cand[i].contains(d)) rows.add(r);
        }
        if (rows.length == 2) strongCol[d].add((c, (rows[0] << 4) | rows[1]));
      }
    }

    // Collect bi-value cells
    final bivals = <int, List<int>>{}; // cell -> [a,b]
    for (var i = 0; i < 81; i++) {
      if (s.cells[i] == 0 && cand[i].length == 2) {
        bivals[i] = cand[i].toList()..sort();
      }
    }

    // For each pair of bi-value cells with the same {x,y}
    final cells = bivals.keys.toList();
    for (var a = 0; a < cells.length; a++) {
      for (var b = a + 1; b < cells.length; b++) {
        final i1 = cells[a], i2 = cells[b];
        final p = bivals[i1]!, q = bivals[i2]!;
        if (p[0] != q[0] || p[1] != q[1]) continue; // require same pair
        // Not in same row, col, or box (otherwise simpler techniques apply)
        if (s.rowOf(i1) == s.rowOf(i2) ||
            s.colOf(i1) == s.colOf(i2) ||
            s.boxOf(i1) == s.boxOf(i2))
          continue;
        final x = p[0], y = p[1];

        // Check against conjugate links of x in rows and columns
        bool sees(int cell, int r, int c) =>
            s.rowOf(cell) == r || s.colOf(cell) == c;

        bool tryWithRowLinks() {
          for (final (r, packed) in strongRow[x]) {
            final c1 = (packed >> 4) & 0xF, c2 = packed & 0xF;
            final u = s.idx(r, c1), v = s.idx(r, c2);
            // i1 must see one endpoint and i2 the other (forming the W structure)
            final i1u = sees(i1, r, c1), i1v = sees(i1, r, c2);
            final i2u = sees(i2, r, c1), i2v = sees(i2, r, c2);
            final matched = (i1u && i2v) || (i1v && i2u);
            if (!matched) continue;
            // Eliminate y from common peers of i1 and i2
            final inter = s.peersOf(i1).intersection(s.peersOf(i2));
            bool changed = false;
            for (final t in inter) {
              if (s.cells[t] == 0 && cand[t].remove(y)) changed = true;
            }
            if (changed) return true;
          }
          return false;
        }

        bool tryWithColLinks() {
          for (final (c, packed) in strongCol[x]) {
            final r1 = (packed >> 4) & 0xF, r2 = packed & 0xF;
            final u = s.idx(r1, c), v = s.idx(r2, c);
            final i1u = sees(i1, r1, c), i1v = sees(i1, r2, c);
            final i2u = sees(i2, r1, c), i2v = sees(i2, r2, c);
            final matched = (i1u && i2v) || (i1v && i2u);
            if (!matched) continue;
            final inter = s.peersOf(i1).intersection(s.peersOf(i2));
            bool changed = false;
            for (final t in inter) {
              if (s.cells[t] == 0 && cand[t].remove(y)) changed = true;
            }
            if (changed) return true;
          }
          return false;
        }

        if (tryWithRowLinks()) return true;
        if (tryWithColLinks()) return true;
      }
    }

    return false;
  }

  bool _uniqueRectangle(Sudoku s, CandidateMap cand) {
    bool changed = false;
    // Iterate over all 2x2 rectangles formed by two rows and two columns
    for (var r1 = 0; r1 < 9; r1++) {
      for (var r2 = r1 + 1; r2 < 9; r2++) {
        for (var c1 = 0; c1 < 9; c1++) {
          for (var c2 = c1 + 1; c2 < 9; c2++) {
            final i1 = s.idx(r1, c1);
            final i2 = s.idx(r1, c2);
            final i3 = s.idx(r2, c1);
            final i4 = s.idx(r2, c2);
            // All four must be empty to participate in a UR pattern
            if (s.cells[i1] != 0 ||
                s.cells[i2] != 0 ||
                s.cells[i3] != 0 ||
                s.cells[i4] != 0) {
              continue;
            }
            // Try all digit pairs {a,b}
            for (var a = 1; a <= 9; a++) {
              for (var b = a + 1; b <= 9; b++) {
                final pair = {a, b};
                // Count how many corners are subset-of {a,b}
                final cells = [i1, i2, i3, i4];
                int subsetCount = 0;
                final supers = <int>[]; // cells that contain {a,b} plus extras
                bool anyEmptyHasPair = false;
                for (final i in cells) {
                  final ci = cand[i];
                  if (ci.isEmpty) {
                    anyEmptyHasPair = true;
                  }
                  if (ci.isNotEmpty && ci.every((d) => pair.contains(d))) {
                    subsetCount++;
                  }
                  if (ci.contains(a) && ci.contains(b) && ci.length > 2) {
                    supers.add(i);
                  }
                }
                // UR Type 1: at least three corners are exactly the pair {a,b},
                // and one corner has extra candidates including {a,b} -> eliminate a and b from that corner.
                if (subsetCount >= 3 && supers.isNotEmpty) {
                  for (final i in supers) {
                    if (cand[i].remove(a)) changed = true;
                    if (cand[i].remove(b)) changed = true;
                    if (changed) return true; // early exit on first success
                  }
                }
              }
            }
          }
        }
      }
    }
    return changed;
  }

  bool _bug(Sudoku s, CandidateMap cand) {
    return false;
  } // TODO

  bool _remotePairs(Sudoku s, CandidateMap cand) {
    return false;
  } // TODO

  bool _xyChain(Sudoku s, CandidateMap cand) {
    return false;
  } // TODO

  bool _als(Sudoku s, CandidateMap cand) {
    return false;
  } // TODO

  bool _alsXyWing(Sudoku s, CandidateMap cand) {
    return false;
  } // TODO

  bool _aic(Sudoku s, CandidateMap cand) {
    return false;
  } // TODO

  bool _hiddenSubset(Sudoku s, CandidateMap cand, int k) {
    bool changed = false;
    bool processUnit(Iterable<int> unit) {
      final empties = unit.where((i) => s.cells[i] == 0).toList();
      // Count candidate locations per digit
      final locs = List.generate(10, (_) => <int>[]);
      for (final i in empties) {
        for (final d in cand[i]) locs[d].add(i);
      }
      for (var d = 1; d <= 9; d++) {
        final pos = locs[d];
        if (pos.length >= 2 && pos.length <= k) {
          // Check if union of candidates across these positions has size == k
          final union = <int>{};
          for (final i in pos) union.addAll(cand[i]);
          if (union.length == k) {
            // lock these k digits to these cells; remove others from those cells
            for (final i in pos) {
              final toRemove = cand[i]
                  .where((x) => !union.contains(x))
                  .toList();
              for (final x in toRemove) changed |= cand[i].remove(x);
            }
          }
        }
      }
      return changed;
    }

    for (var r = 0; r < 9; r++) if (processUnit(s.rowIndices(r))) return true;
    for (var c = 0; c < 9; c++) if (processUnit(s.colIndices(c))) return true;
    for (var b = 0; b < 9; b++) if (processUnit(s.boxIndices(b))) return true;
    return changed;
  }

  bool _xWing(Sudoku s, CandidateMap cand) {
    // Row-based X-Wing and Column-based X-Wing for each digit 1..9
    bool changed = false;
    for (var d = 1; d <= 9; d++) {
      // Row pattern
      final rowsCols =
          <int, Set<int>>{}; // row -> set of columns where d appears
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
          if (cset1.length == 2 &&
              cset1.length == cset2.length &&
              cset1.containsAll(cset2)) {
            // Found X-Wing on columns c1,c2 -> eliminate d from other rows in these columns
            final cols = cset1.toList();
            final c1 = cols[0], c2 = cols[1];
            for (var r = 0; r < 9; r++) {
              if (r == r1 || r == r2) continue;
              final i1 = s.idx(r, c1);
              final i2 = s.idx(r, c2);
              changed |= cand[i1].remove(d);
              changed |= cand[i2].remove(d);
            }
            if (changed) return true;
          }
        }
      }
      // Column pattern
      final colsRows = <int, Set<int>>{}; // col -> set of rows where d appears
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
          if (rset1.length == 2 &&
              rset1.length == rset2.length &&
              rset1.containsAll(rset2)) {
            // Found X-Wing on rows r1,r2 -> eliminate d from other columns in these rows
            final rowsPair = rset1.toList();
            final r1 = rowsPair[0], r2 = rowsPair[1];
            for (var c = 0; c < 9; c++) {
              if (c == c1 || c == c2) continue;
              final i1 = s.idx(r1, c);
              final i2 = s.idx(r2, c);
              changed |= cand[i1].remove(d);
              changed |= cand[i2].remove(d);
            }
            if (changed) return true;
          }
        }
      }
    }
    return changed;
  }
}
