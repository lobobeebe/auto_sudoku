import 'package:auto_sudoku_solver/src/strategy/hidden_strategy.dart';
import 'package:auto_sudoku_solver/src/strategy/locked_strategy.dart';
import 'package:auto_sudoku_solver/src/strategy/naked_strategy.dart';

import 'candidate_map.dart';
import 'difficulty.dart';
import 'hint.dart';
import 'rating.dart';
import 'solve_result.dart';
import 'strategy/strategy.dart';
import 'sudoku.dart';

import 'solver_settings.dart';

class Solver {
  final strategyOrder = [
    // Trivial Singles
    NakedSingleStrategy(),
    HiddenSingleStrategy(),

    // Naked Sets
    NakedPairStrategy(),
    NakedTripleStrategy(),
    NakedQuadStrategy(),

    // Locked Candidates
    ClaimingStrategy(),
    PointingStrategy(),

    // Hidden Sets
    HiddenPairStrategy(),
    HiddenTripleStrategy(),
    HiddenQuadStrategy(),

    // // Fish & Wings
    // StrategyType.xWing,
    // StrategyType.xyWing,
    // StrategyType.wWing,
    // StrategyType.xyzWing,
    // StrategyType.swordfish,
    // // Chain/Graph & Uniqueness
    // StrategyType.coloring,
    // StrategyType.skyscraper,
    // StrategyType.twoStringKite,
    // StrategyType.turbotFish,
    // StrategyType.uniqueRectangle,
    // StrategyType.bug,
    // StrategyType.remotePairs,
    // StrategyType.xyChain,
    // // ALS & AIC
    // StrategyType.als,
    // StrategyType.alsXyWing,
    // StrategyType.aic,
  ];

  Hint? getHintByClues(
    Sudoku s,
    List<int> clueIndices, {
    SolverSettings? settings,
  }) {
    final effective = settings ?? SolverSettings.all();
    final cand = CandidateMap.fromBoard(s);
    return _getHintByClues(s, cand, effective, clueIndices);
  }

  Hint? _getHintByClues(
    Sudoku s,
    CandidateMap cand,
    SolverSettings settings,
    List<int> clueIndices,
  ) {
    for (final strat in strategyOrder) {
      if (!settings.allows(strat.type)) {
        continue;
      }
      final hint = strat.getHintFromClues(s, cand, clueIndices);
      if (hint != null) return hint;
    }

    return null;
  }

  Hint? nextHint(Sudoku s, {SolverSettings? settings}) {
    final effective = settings ?? SolverSettings.all();
    final cand = CandidateMap.fromBoard(s);
    return _nextHintInternal(s, cand, effective);
  }

  Hint? _nextHintInternal(
    Sudoku s,
    CandidateMap cand,
    SolverSettings settings,
  ) {
    for (final strat in strategyOrder) {
      if (!settings.allows(strat.type)) {
        print("Not allowed");
        continue;
      }
      final hint = strat.findHint(s, cand);
      if (hint != null) return hint;
    }

    return null;
  }

  // Hint? _findNakedSingleHint(Sudoku s, CandidateMap cand) {
  //   for (var i = 0; i < 81; i++) {
  //     if (s.cells[i] != 0) continue;
  //     if (cand[i].length != 1) continue;
  //     final value = cand[i].first;
  //     return Hint(
  //       StrategyType.nakedSingle,
  //       placements: [(i, value)],
  //       cells: [i],
  //       digits: [value],
  //     );
  //   }
  //   return null;
  // }

  // Hint? _findHiddenSingleHint(Sudoku s, CandidateMap cand) {
  //   Hint? checkUnit(Iterable<int> unit, HintUnit unitType) {
  //     final spots = List.generate(10, (_) => <int>[]);
  //     for (final cell in unit) {
  //       if (s.cells[cell] != 0) continue;
  //       for (final digit in cand[cell]) {
  //         spots[digit].add(cell);
  //       }
  //     }
  //     for (var digit = 1; digit <= 9; digit++) {
  //       final positions = spots[digit];
  //       if (positions.length == 1) {
  //         final cell = positions.first;
  //         return Hint(
  //           StrategyType.hiddenSingle,
  //           placements: [(cell, digit)],
  //           cells: [cell],
  //           digits: [digit],
  //           unit: unitType,
  //         );
  //       }
  //     }
  //     return null;
  //   }

  //   for (var r = 0; r < 9; r++) {
  //     final hint = checkUnit(s.rowIndices(r), HintUnit.row);
  //     if (hint != null) return hint;
  //   }
  //   for (var c = 0; c < 9; c++) {
  //     final hint = checkUnit(s.colIndices(c), HintUnit.column);
  //     if (hint != null) return hint;
  //   }
  //   for (var b = 0; b < 9; b++) {
  //     final hint = checkUnit(s.boxIndices(b), HintUnit.box);
  //     if (hint != null) return hint;
  //   }
  //   return null;
  // }

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
              StrategyType.pointing,
              eliminations: elim,
              cells: inBox,
              digits: [d],
              unit: HintUnit.row,
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

  // Helper to find a subset hint (naked/hidden, k in {2,3,4})
  Hint? _findNakedHint(Sudoku s, CandidateMap cand, int k) {
    // Try Naked subset in each unit
    Hint? processUnitNaked(Iterable<int> unit, HintUnit unitType) {
      final empties = unit.where((i) => s.cells[i] == 0).toList();
      if (empties.length < k) return null;
      final subsetCandidates = empties
          .where((i) => cand[i].length >= 2 && cand[i].length <= k)
          .toList();
      for (var a = 0; a < subsetCandidates.length; a++) {
        for (var b = a + 1; b < subsetCandidates.length; b++) {
          if (k == 2) {
            final set = {
              ...cand[subsetCandidates[a]],
              ...cand[subsetCandidates[b]],
            };
            if (set.length == 2 &&
                cand[subsetCandidates[a]].length <= 2 &&
                cand[subsetCandidates[b]].length <= 2) {
              final others = <(int, int)>[];
              for (final i in empties) {
                if (i == subsetCandidates[a] || i == subsetCandidates[b]) {
                  continue;
                }
                for (final v in set) {
                  if (cand[i].contains(v)) others.add((i, v));
                }
              }
              if (others.isNotEmpty) {
                return Hint(
                  StrategyType.nakedPair,
                  eliminations: others,
                  cells: [subsetCandidates[a], subsetCandidates[b]],
                  digits: set.toList(),
                  unit: unitType,
                );
              }
            }
          } else if (k == 3) {
            for (var c = b + 1; c < subsetCandidates.length; c++) {
              final set = {
                ...cand[subsetCandidates[a]],
                ...cand[subsetCandidates[b]],
                ...cand[subsetCandidates[c]],
              };
              if (set.length == 3 &&
                  cand[subsetCandidates[a]].length <= 3 &&
                  cand[subsetCandidates[b]].length <= 3 &&
                  cand[subsetCandidates[c]].length <= 3) {
                final others = <(int, int)>[];
                for (final i in empties) {
                  if (i == subsetCandidates[a] ||
                      i == subsetCandidates[b] ||
                      i == subsetCandidates[c]) {
                    continue;
                  }
                  for (final v in set) {
                    if (cand[i].contains(v)) others.add((i, v));
                  }
                }
                if (others.isNotEmpty) {
                  return Hint(
                    StrategyType.nakedTriple,
                    eliminations: others,
                    cells: [
                      subsetCandidates[a],
                      subsetCandidates[b],
                      subsetCandidates[c],
                    ],
                    digits: set.toList(),
                    unit: unitType,
                  );
                }
              }
            }
          } else {
            for (var c = b + 1; c < subsetCandidates.length; c++) {
              for (var d = c + 1; d < subsetCandidates.length; d++) {
                final set = {
                  ...cand[subsetCandidates[a]],
                  ...cand[subsetCandidates[b]],
                  ...cand[subsetCandidates[c]],
                  ...cand[subsetCandidates[d]],
                };
                if (set.length == 4 &&
                    cand[subsetCandidates[a]].length <= 4 &&
                    cand[subsetCandidates[b]].length <= 4 &&
                    cand[subsetCandidates[c]].length <= 4 &&
                    cand[subsetCandidates[d]].length <= 4) {
                  final others = <(int, int)>[];
                  for (final i in empties) {
                    if (i == subsetCandidates[a] ||
                        i == subsetCandidates[b] ||
                        i == subsetCandidates[c] ||
                        i == subsetCandidates[d]) {
                      continue;
                    }
                    for (final v in set) {
                      if (cand[i].contains(v)) others.add((i, v));
                    }
                  }
                  if (others.isNotEmpty) {
                    return Hint(
                      StrategyType.nakedQuad,
                      eliminations: others,
                      cells: [
                        subsetCandidates[a],
                        subsetCandidates[b],
                        subsetCandidates[c],
                        subsetCandidates[d],
                      ],
                      digits: set.toList(),
                      unit: unitType,
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

    for (var r = 0; r < 9; r++) {
      final h = processUnitNaked(s.rowIndices(r), HintUnit.row);
      if (h != null) return h;
    }
    for (var c = 0; c < 9; c++) {
      final h = processUnitNaked(s.colIndices(c), HintUnit.column);
      if (h != null) return h;
    }
    for (var b = 0; b < 9; b++) {
      final h = processUnitNaked(s.boxIndices(b), HintUnit.box);
      if (h != null) return h;
    }
    return null;
  }

  Hint? _findHiddenHint(Sudoku s, CandidateMap cand) {
    Hint? processUnit(Iterable<int> unit, HintUnit unitType) {
      for (final k in [2, 3, 4]) {
        final hint = _findHiddenSubsetInUnit(s, cand, unit, unitType, k);
        if (hint != null) return hint;
      }
      return null;
    }

    for (var r = 0; r < 9; r++) {
      final h = processUnit(s.rowIndices(r), HintUnit.row);
      if (h != null) return h;
    }
    for (var c = 0; c < 9; c++) {
      final h = processUnit(s.colIndices(c), HintUnit.column);
      if (h != null) return h;
    }
    for (var b = 0; b < 9; b++) {
      final h = processUnit(s.boxIndices(b), HintUnit.box);
      if (h != null) return h;
    }
    return null;
  }

  Hint? _findHiddenSubsetInUnit(
    Sudoku s,
    CandidateMap cand,
    Iterable<int> unit,
    HintUnit unitType,
    int k,
  ) {
    final empties = unit.where((i) => s.cells[i] == 0).toList();
    if (empties.isEmpty) return null;
    final locs = List.generate(10, (_) => <int>[]);
    for (final i in empties) {
      for (final d in cand[i]) {
        locs[d].add(i);
      }
    }

    final digits = <int>[];
    for (var d = 1; d <= 9; d++) {
      final positions = locs[d];
      if (positions.length >= 2 && positions.length <= k) {
        digits.add(d);
      }
    }
    if (digits.length < k) return null;

    Hint? result;
    final current = <int>[];
    void choose(int start) {
      if (result != null) return;
      if (current.length == k) {
        final positions = <int>{};
        for (final digit in current) {
          positions.addAll(locs[digit]);
        }
        if (positions.length != k) return;

        final subset = current.toSet();
        final toTrim = <(int, int)>[];
        for (final cell in positions) {
          for (final candidate in cand[cell]) {
            if (!subset.contains(candidate)) {
              toTrim.add((cell, candidate));
            }
          }
        }
        if (toTrim.isEmpty) return;

        result = Hint(
          switch (k) {
            2 => StrategyType.hiddenPair,
            3 => StrategyType.hiddenTriple,
            _ => StrategyType.hiddenQuad,
          },
          eliminations: toTrim,
          cells: positions.toList()..sort(),
          digits: subset.toList()..sort(),
          unit: unitType,
        );
        return;
      }

      for (var i = start; i < digits.length; i++) {
        current.add(digits[i]);
        choose(i + 1);
        current.removeLast();
        if (result != null) return;
      }
    }

    choose(0);
    return result;
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
                StrategyType.xWing,
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
                StrategyType.xWing,
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

  SolveResult solveLogical(Sudoku s, {SolverSettings? settings}) {
    settings ??= SolverSettings.all();

    final steps = <StrategyType>[];
    final cand = CandidateMap.fromBoard(s);

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
      steps.add(hint.strategy);
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
            StrategyType.xyWing,
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
            StrategyType.coloring,
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
              StrategyType.swordfish,
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
              StrategyType.swordfish,
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
            StrategyType.skyscraper,
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
            StrategyType.skyscraper,
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
            StrategyType.twoStringKite,
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
              StrategyType.wWing,
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
                    StrategyType.uniqueRectangle,
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
      for (var t = k; t < empties.length; t++) {
        final i = empties[t];
        final r = i ~/ 9, c = i % 9, b = (r ~/ 3) * 3 + (c ~/ 3);
        final used = row[r] | col[c] | box[b];
        var count = 0;
        for (var d = 1; d <= 9; d++) {
          final bit = 1 << d;
          if ((used & bit) == 0) {
            count++;
          }
        }
        if (count < bestCount) {
          bestCount = count;
          bestIdx = t;
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
    SolverSettings settings = const SolverSettings(),
  }) {
    final copy = Sudoku(List<int>.from(s.cells));
    final res = solveLogical(copy, settings: settings);
    final counts = <StrategyType, int>{};
    final first = <StrategyType, int>{};
    for (var i = 0; i < res.steps.length; i++) {
      final st = res.steps[i];
      counts[st] = (counts[st] ?? 0) + 1;
      first.putIfAbsent(st, () => i);
    }
    return Rating(
      res.solved
          ? Difficulty.trivial
          : Difficulty
                .impossible, // bucket is not used by distance; keep trivial placeholder
      counts,
      first,
    );
  }
}
