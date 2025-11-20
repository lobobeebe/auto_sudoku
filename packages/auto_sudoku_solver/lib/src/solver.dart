import 'package:auto_sudoku_solver/src/strategy/hidden_strategy.dart';
import 'package:auto_sudoku_solver/src/strategy/locked_strategy.dart';
import 'package:auto_sudoku_solver/src/strategy/naked_strategy.dart';
import 'package:auto_sudoku_solver/src/strategy/wing_strategy.dart';

import 'hint.dart';
import 'rating.dart';
import 'solve_result.dart';
import 'strategy/strategy.dart';
import 'sudoku.dart';

import 'solver_settings.dart';

class Solver {
  final List<Strategy> strategyOrder = [
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

    //  Wings
    XWingStrategy(),
    XYWingStrategy(),
    WWingStrategy(),
    //StrategyType.xyzWing,

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

  final SolverSettings settings;

  Solver({SolverSettings? settings})
    : settings = settings ?? SolverSettings.all();

  Hint? getHintByClues(Sudoku s, List<int> clueIndices) {
    return _getHintByClues(s, clueIndices);
  }

  Hint? _getHintByClues(Sudoku s, List<int> clueIndices) {
    for (final strat in strategyOrder) {
      if (!settings.allows(strat.type)) {
        continue;
      }
      final hint = strat.getHintFromClues(s, clueIndices);
      if (hint != null) return hint;
    }

    return null;
  }

  Hint? nextHint(Sudoku s) {
    for (final strat in strategyOrder) {
      if (!settings.allows(strat.type)) {
        continue;
      }
      final hint = strat.findHint(s);
      if (hint != null) return hint;
    }

    return null;
  }

  SolveResult solveLogical(Sudoku s) {
    final steps = <StrategyType>[];

    while (!s.isSolved) {
      final hint = nextHint(s);
      if (hint == null) {
        break;
      }
      final mutated = _applyHint(s, hint);
      if (!mutated) {
        break;
      }
      steps.add(hint.strategy);
    }

    return SolveResult(s.isSolved, !s.isSolved, steps);
  }

  bool _applyHint(Sudoku s, Hint hint) {
    var changed = false;

    for (final entry in hint.placements.entries) {
      int index = entry.key;
      int digit = entry.value;
      if (index < 0 || index >= 81) continue;
      if (digit < 1 || digit > 9) continue;
      if (s.valueAt(index) != digit) {
        s.setValue(index, digit);
        changed = true;
      }
      s.resetNotes(index);
      s.removeFromPeers(index, digit);
    }

    for (final entry in hint.eliminations.entries) {
      final index = entry.key;
      for (final digit in entry.value) {
        // Skip invalid indices/digits and already-filled cells
        if (!Sudoku.isValidIndex(index)) continue;
        if (!Sudoku.isValidDigit(digit)) continue;
        if (!s.isEmpty(index)) continue;
        if (s.setNote(index, digit, false)) {
          changed = true;
        }
      }
    }

    return changed;
  }

  // Hint? _findXYWingHint(Sudoku s, CandidateMap s.notes) {
  //   final peers = List.generate(81, (i) => s.peersOf(i));
  //   for (var pivot = 0; pivot < 81; pivot++) {
  //     if (!s.isEmpty(pivot) || s.notes[pivot].length != 2) continue;
  //     final digits = s.notes[pivot].toList()..sort();
  //     final a = digits[0], b = digits[1];
  //     final wingsA = <int, int>{};
  //     final wingsB = <int, int>{};
  //     for (final peer in peers[pivot]) {
  //       if (!s.isEmpty(peer) || s.notes[peer].length != 2) continue;
  //       final values = s.notes[peer].toList();
  //       if (values.contains(a) && !values.contains(b)) {
  //         final z = values.firstWhere((v) => v != a);
  //         wingsA[peer] = z;
  //       } else if (values.contains(b) && !values.contains(a)) {
  //         final z = values.firstWhere((v) => v != b);
  //         wingsB[peer] = z;
  //       }
  //     }
  //     if (wingsA.isEmpty || wingsB.isEmpty) continue;
  //     for (final entryA in wingsA.entries) {
  //       for (final entryB in wingsB.entries) {
  //         if (entryA.value != entryB.value) continue;
  //         final z = entryA.value;
  //         final cellA = entryA.key;
  //         final cellB = entryB.key;
  //         final intersection = peers[cellA].intersection(peers[cellB]);
  //         final eliminations = <(int, int)>[];
  //         for (final idx in intersection) {
  //           if (!s.isEmpty(idx)) continue;
  //           if (!s.notes[idx].contains(z)) continue;
  //           eliminations.add((idx, z));
  //         }
  //         if (eliminations.isEmpty) continue;
  //         final cells = <int>{pivot, cellA, cellB}.toList()..sort();
  //         final digitsSet = <int>{a, b, z}.toList()..sort();
  //         return Hint(
  //           StrategyType.xyWing,
  //           eliminations: eliminations,
  //           cells: cells,
  //           digits: digitsSet,
  //         );
  //       }
  //     }
  //   }
  //   return null;
  // }

  // Hint? _findColoringHint(Sudoku s, CandidateMap s.notes) {
  //   final peers = List.generate(81, (i) => s.peersOf(i));
  //   for (var digit = 1; digit <= 9; digit++) {
  //     final edges = <int, Set<int>>{};
  //     void addEdge(int a, int b) {
  //       edges.putIfAbsent(a, () => <int>{}).add(b);
  //       edges.putIfAbsent(b, () => <int>{}).add(a);
  //     }

  //     for (var r = 0; r < 9; r++) {
  //       final cells = <int>[];
  //       for (var c = 0; c < 9; c++) {
  //         final idx = s.idx(r, c);
  //         if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) cells.add(idx);
  //       }
  //       if (cells.length == 2) addEdge(cells[0], cells[1]);
  //     }
  //     for (var c = 0; c < 9; c++) {
  //       final cells = <int>[];
  //       for (var r = 0; r < 9; r++) {
  //         final idx = s.idx(r, c);
  //         if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) cells.add(idx);
  //       }
  //       if (cells.length == 2) addEdge(cells[0], cells[1]);
  //     }
  //     for (var b = 0; b < 9; b++) {
  //       final cells = <int>[];
  //       for (final idx in s.boxIndices(b)) {
  //         if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) cells.add(idx);
  //       }
  //       if (cells.length == 2) addEdge(cells[0], cells[1]);
  //     }

  //     if (edges.isEmpty) continue;
  //     final colored = <int, bool>{};
  //     for (final start in edges.keys) {
  //       if (colored.containsKey(start)) continue;
  //       final queue = <int>[start];
  //       colored[start] = false;
  //       final falseColor = <int>{};
  //       final trueColor = <int>{};
  //       var valid = true;
  //       while (queue.isNotEmpty && valid) {
  //         final cell = queue.removeLast();
  //         final colour = colored[cell]!;
  //         (colour ? trueColor : falseColor).add(cell);
  //         for (final neighbor in edges[cell] ?? const <int>{}) {
  //           final desired = !colour;
  //           final current = colored[neighbor];
  //           if (current == null) {
  //             colored[neighbor] = desired;
  //             queue.add(neighbor);
  //           } else if (current == colour) {
  //             valid = false;
  //             break;
  //           }
  //         }
  //       }
  //       if (!valid) continue;
  //       if (falseColor.isEmpty || trueColor.isEmpty) continue;
  //       final coloredSet = {...falseColor, ...trueColor};
  //       final eliminations = <(int, int)>[];
  //       for (var idx = 0; idx < 81; idx++) {
  //         if (!s.isEmpty(idx)) continue;
  //         if (!s.notes[idx].contains(digit)) continue;
  //         if (coloredSet.contains(idx)) continue;
  //         final peerSet = peers[idx];
  //         final seesFalse = peerSet.any(falseColor.contains);
  //         if (!seesFalse) continue;
  //         final seesTrue = peerSet.any(trueColor.contains);
  //         if (!seesTrue) continue;
  //         eliminations.add((idx, digit));
  //       }
  //       if (eliminations.isNotEmpty) {
  //         final cells = coloredSet.toList()..sort();
  //         return Hint(
  //           StrategyType.coloring,
  //           eliminations: eliminations,
  //           cells: cells,
  //           digits: [digit],
  //         );
  //       }
  //     }
  //   }
  //   return null;
  // }

  // Hint? _findSwordfishHint(Sudoku s, CandidateMap s.notes) {
  //   Hint? rowFish(int digit) {
  //     final rowCols = <int, Set<int>>{};
  //     for (var r = 0; r < 9; r++) {
  //       final cols = <int>{};
  //       for (var c = 0; c < 9; c++) {
  //         final idx = s.idx(r, c);
  //         if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) cols.add(c);
  //       }
  //       if (cols.length >= 2 && cols.length <= 3) {
  //         rowCols[r] = cols;
  //       }
  //     }
  //     final rows = rowCols.keys.toList();
  //     for (var a = 0; a < rows.length; a++) {
  //       for (var b = a + 1; b < rows.length; b++) {
  //         for (var c = b + 1; c < rows.length; c++) {
  //           final r1 = rows[a], r2 = rows[b], r3 = rows[c];
  //           final union = {...rowCols[r1]!, ...rowCols[r2]!, ...rowCols[r3]!};
  //           if (union.length != 3) continue;
  //           final columns = union.toList()..sort();
  //           final eliminations = <(int, int)>[];
  //           for (var r = 0; r < 9; r++) {
  //             if (r == r1 || r == r2 || r == r3) continue;
  //             for (final col in columns) {
  //               final idx = s.idx(r, col);
  //               if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) {
  //                 eliminations.add((idx, digit));
  //               }
  //             }
  //           }
  //           if (eliminations.isEmpty) continue;
  //           final pattern = <int>{};
  //           for (final row in [r1, r2, r3]) {
  //             for (final col in rowCols[row]!) {
  //               if (union.contains(col)) {
  //                 pattern.add(s.idx(row, col));
  //               }
  //             }
  //           }
  //           final cells = pattern.toList()..sort();
  //           return Hint(
  //             StrategyType.swordfish,
  //             eliminations: eliminations,
  //             cells: cells,
  //             digits: [digit],
  //           );
  //         }
  //       }
  //     }
  //     return null;
  //   }

  //   Hint? colFish(int digit) {
  //     final colRows = <int, Set<int>>{};
  //     for (var c = 0; c < 9; c++) {
  //       final rows = <int>{};
  //       for (var r = 0; r < 9; r++) {
  //         final idx = s.idx(r, c);
  //         if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) rows.add(r);
  //       }
  //       if (rows.length >= 2 && rows.length <= 3) {
  //         colRows[c] = rows;
  //       }
  //     }
  //     final cols = colRows.keys.toList();
  //     for (var a = 0; a < cols.length; a++) {
  //       for (var b = a + 1; b < cols.length; b++) {
  //         for (var c = b + 1; c < cols.length; c++) {
  //           final c1 = cols[a], c2 = cols[b], c3 = cols[c];
  //           final union = {...colRows[c1]!, ...colRows[c2]!, ...colRows[c3]!};
  //           if (union.length != 3) continue;
  //           final rows = union.toList()..sort();
  //           final eliminations = <(int, int)>[];
  //           for (var col = 0; col < 9; col++) {
  //             if (col == c1 || col == c2 || col == c3) continue;
  //             for (final row in rows) {
  //               final idx = s.idx(row, col);
  //               if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) {
  //                 eliminations.add((idx, digit));
  //               }
  //             }
  //           }
  //           if (eliminations.isEmpty) continue;
  //           final pattern = <int>{};
  //           for (final col in [c1, c2, c3]) {
  //             for (final row in colRows[col]!) {
  //               if (union.contains(row)) {
  //                 pattern.add(s.idx(row, col));
  //               }
  //             }
  //           }
  //           final cells = pattern.toList()..sort();
  //           return Hint(
  //             StrategyType.swordfish,
  //             eliminations: eliminations,
  //             cells: cells,
  //             digits: [digit],
  //           );
  //         }
  //       }
  //     }
  //     return null;
  //   }

  //   for (var digit = 1; digit <= 9; digit++) {
  //     final rowHint = rowFish(digit);
  //     if (rowHint != null) return rowHint;
  //     final colHint = colFish(digit);
  //     if (colHint != null) return colHint;
  //   }
  //   return null;
  // }

  // Hint? _findSkyscraperHint(Sudoku s, CandidateMap s.notes) {
  //   final peers = List.generate(81, (i) => s.peersOf(i));
  //   Set<int> commonPeers(int a, int b) => peers[a].intersection(peers[b]);

  //   for (var digit = 1; digit <= 9; digit++) {
  //     final rowLinks = <int, List<int>>{};
  //     for (var r = 0; r < 9; r++) {
  //       final cols = <int>[];
  //       for (var c = 0; c < 9; c++) {
  //         final idx = s.idx(r, c);
  //         if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) cols.add(c);
  //       }
  //       if (cols.length == 2) rowLinks[r] = cols;
  //     }
  //     final rows = rowLinks.keys.toList();
  //     for (var i = 0; i < rows.length; i++) {
  //       for (var j = i + 1; j < rows.length; j++) {
  //         final r1 = rows[i], r2 = rows[j];
  //         final cols1 = rowLinks[r1]!;
  //         final cols2 = rowLinks[r2]!;
  //         final shared = cols1.toSet().intersection(cols2.toSet()).toList();
  //         if (shared.length != 1) continue;
  //         final sharedCol = shared.first;
  //         final c1 = cols1.firstWhere((c) => c != sharedCol);
  //         final c2 = cols2.firstWhere((c) => c != sharedCol);
  //         final base1 = s.idx(r1, sharedCol);
  //         final base2 = s.idx(r2, sharedCol);
  //         final end1 = s.idx(r1, c1);
  //         final end2 = s.idx(r2, c2);
  //         if (!s.isEmpty(end1] != 0 || s.cells[end2)) continue;
  //         final eliminations = <(int, int)>[];
  //         for (final idx in commonPeers(end1, end2)) {
  //           if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) {
  //             eliminations.add((idx, digit));
  //           }
  //         }
  //         if (eliminations.isEmpty) continue;
  //         final cells = <int>{base1, base2, end1, end2}.toList()..sort();
  //         return Hint(
  //           StrategyType.skyscraper,
  //           eliminations: eliminations,
  //           cells: cells,
  //           digits: [digit],
  //         );
  //       }
  //     }

  //     final colLinks = <int, List<int>>{};
  //     for (var c = 0; c < 9; c++) {
  //       final rowsSet = <int>[];
  //       for (var r = 0; r < 9; r++) {
  //         final idx = s.idx(r, c);
  //         if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) rowsSet.add(r);
  //       }
  //       if (rowsSet.length == 2) colLinks[c] = rowsSet;
  //     }
  //     final cols = colLinks.keys.toList();
  //     for (var i = 0; i < cols.length; i++) {
  //       for (var j = i + 1; j < cols.length; j++) {
  //         final c1 = cols[i], c2 = cols[j];
  //         final rows1 = colLinks[c1]!;
  //         final rows2 = colLinks[c2]!;
  //         final shared = rows1.toSet().intersection(rows2.toSet()).toList();
  //         if (shared.length != 1) continue;
  //         final sharedRow = shared.first;
  //         final r1 = rows1.firstWhere((r) => r != sharedRow);
  //         final r2 = rows2.firstWhere((r) => r != sharedRow);
  //         final base1 = s.idx(sharedRow, c1);
  //         final base2 = s.idx(sharedRow, c2);
  //         final end1 = s.idx(r1, c1);
  //         final end2 = s.idx(r2, c2);
  //         if (!s.isEmpty(end1] != 0 || s.cells[end2)) continue;
  //         final eliminations = <(int, int)>[];
  //         for (final idx in commonPeers(end1, end2)) {
  //           if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) {
  //             eliminations.add((idx, digit));
  //           }
  //         }
  //         if (eliminations.isEmpty) continue;
  //         final cells = <int>{base1, base2, end1, end2}.toList()..sort();
  //         return Hint(
  //           StrategyType.skyscraper,
  //           eliminations: eliminations,
  //           cells: cells,
  //           digits: [digit],
  //         );
  //       }
  //     }
  //   }
  //   return null;
  // }

  // Hint? _findTwoStringKiteHint(Sudoku s, CandidateMap s.notes) {
  //   for (var digit = 1; digit <= 9; digit++) {
  //     final rowLinks = <int, List<int>>{};
  //     final colLinks = <int, List<int>>{};
  //     for (var r = 0; r < 9; r++) {
  //       final cols = <int>[];
  //       for (var c = 0; c < 9; c++) {
  //         final idx = s.idx(r, c);
  //         if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) cols.add(c);
  //       }
  //       if (cols.length == 2) rowLinks[r] = cols;
  //     }
  //     for (var c = 0; c < 9; c++) {
  //       final rows = <int>[];
  //       for (var r = 0; r < 9; r++) {
  //         final idx = s.idx(r, c);
  //         if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) rows.add(r);
  //       }
  //       if (rows.length == 2) colLinks[c] = rows;
  //     }

  //     for (final r in rowLinks.keys) {
  //       final cols = rowLinks[r]!;
  //       final cA = cols[0], cB = cols[1];
  //       for (final c in colLinks.keys) {
  //         final rows = colLinks[c]!;
  //         final rA = rows[0], rB = rows[1];
  //         final p1 = s.idx(r, cA);
  //         final p2 = s.idx(r, cB);
  //         final q1 = s.idx(rA, c);
  //         final q2 = s.idx(rB, c);
  //         bool share(int x, int y) => s.boxOf(x) == s.boxOf(y);
  //         final pairings = [
  //           (p1, q1, s.idx(rB, cB)),
  //           (p1, q2, s.idx(rA, cB)),
  //           (p2, q1, s.idx(rB, cA)),
  //           (p2, q2, s.idx(rA, cA)),
  //         ];
  //         int hits = 0;
  //         int elimCell = -1;
  //         for (final triple in pairings) {
  //           if (share(triple.$1, triple.$2)) {
  //             hits++;
  //             elimCell = triple.$3;
  //           }
  //         }
  //         if (hits != 1 || elimCell < 0) continue;
  //         if (!s.isEmpty(elimCell) || !s.notes[elimCell].contains(digit)) {
  //           continue;
  //         }
  //         final cells = <int>{p1, p2, q1, q2}.toList()..sort();
  //         return Hint(
  //           StrategyType.twoStringKite,
  //           eliminations: [(elimCell, digit)],
  //           cells: cells,
  //           digits: [digit],
  //         );
  //       }
  //     }
  //   }
  //   return null;
  // }

  // Hint? _findTurbotFishHint(Sudoku s, CandidateMap s.notes) => null;

  // Hint? _findXYZWingHint(Sudoku s, CandidateMap s.notes) => null;

  // Hint? _findWWingHint(Sudoku s, CandidateMap s.notes) {
  //   final strongRow = List.generate(10, (_) => <(int, int)>[]);
  //   final strongCol = List.generate(10, (_) => <(int, int)>[]);
  //   for (var digit = 1; digit <= 9; digit++) {
  //     for (var r = 0; r < 9; r++) {
  //       final cols = <int>[];
  //       for (var c = 0; c < 9; c++) {
  //         final idx = s.idx(r, c);
  //         if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) cols.add(c);
  //       }
  //       if (cols.length == 2) {
  //         strongRow[digit].add((r, (cols[0] << 4) | cols[1]));
  //       }
  //     }
  //     for (var c = 0; c < 9; c++) {
  //       final rows = <int>[];
  //       for (var r = 0; r < 9; r++) {
  //         final idx = s.idx(r, c);
  //         if (s.cells[idx] == 0 && s.notes[idx].contains(digit)) rows.add(r);
  //       }
  //       if (rows.length == 2) {
  //         strongCol[digit].add((c, (rows[0] << 4) | rows[1]));
  //       }
  //     }
  //   }

  //   final bivalue = <int, List<int>>{};
  //   for (var idx = 0; idx < 81; idx++) {
  //     if (s.cells[idx] == 0 && s.notes[idx].length == 2) {
  //       bivalue[idx] = s.notes[idx].toList()..sort();
  //     }
  //   }

  //   final peers = List.generate(81, (i) => s.peersOf(i));
  //   bool sees(int cell, int r, int c) =>
  //       s.rowOf(cell) == r || s.colOf(cell) == c;

  //   final cells = bivalue.keys.toList();
  //   for (var i = 0; i < cells.length; i++) {
  //     for (var j = i + 1; j < cells.length; j++) {
  //       final i1 = cells[i], i2 = cells[j];
  //       final pair1 = bivalue[i1]!;
  //       final pair2 = bivalue[i2]!;
  //       if (pair1[0] != pair2[0] || pair1[1] != pair2[1]) continue;
  //       if (s.rowOf(i1) == s.rowOf(i2) ||
  //           s.colOf(i1) == s.colOf(i2) ||
  //           s.boxOf(i1) == s.boxOf(i2)) {
  //         continue;
  //       }
  //       final x = pair1[0];
  //       final y = pair1[1];

  //       Hint? processLinks(List<(int, int)> links, bool rowMode) {
  //         for (final (index, packed) in links) {
  //           final first = (packed >> 4) & 0xF;
  //           final second = packed & 0xF;
  //           final cellA = rowMode ? s.idx(index, first) : s.idx(first, index);
  //           final cellB = rowMode ? s.idx(index, second) : s.idx(second, index);
  //           final i1A = rowMode
  //               ? sees(i1, index, first)
  //               : sees(i1, first, index);
  //           final i1B = rowMode
  //               ? sees(i1, index, second)
  //               : sees(i1, second, index);
  //           final i2A = rowMode
  //               ? sees(i2, index, first)
  //               : sees(i2, first, index);
  //           final i2B = rowMode
  //               ? sees(i2, index, second)
  //               : sees(i2, second, index);
  //           final matched = (i1A && i2B) || (i1B && i2A);
  //           if (!matched) continue;
  //           final inter = peers[i1].intersection(peers[i2]);
  //           final eliminations = <(int, int)>[];
  //           for (final idx in inter) {
  //             if (s.cells[idx] == 0 && s.notes[idx].contains(y)) {
  //               eliminations.add((idx, y));
  //             }
  //           }
  //           if (eliminations.isEmpty) continue;
  //           final cells = <int>{i1, i2, cellA, cellB}.toList()..sort();
  //           final digits = [x, y];
  //           return Hint(
  //             StrategyType.wWing,
  //             eliminations: eliminations,
  //             cells: cells,
  //             digits: digits,
  //           );
  //         }
  //         return null;
  //       }

  //       final rowHint = processLinks(strongRow[x], true);
  //       if (rowHint != null) return rowHint;
  //       final colHint = processLinks(strongCol[x], false);
  //       if (colHint != null) return colHint;
  //     }
  //   }
  //   return null;
  // }

  // Hint? _findUniqueRectangleHint(Sudoku s, CandidateMap s.notes) {
  //   for (var r1 = 0; r1 < 9; r1++) {
  //     for (var r2 = r1 + 1; r2 < 9; r2++) {
  //       for (var c1 = 0; c1 < 9; c1++) {
  //         for (var c2 = c1 + 1; c2 < 9; c2++) {
  //           final i1 = s.idx(r1, c1);
  //           final i2 = s.idx(r1, c2);
  //           final i3 = s.idx(r2, c1);
  //           final i4 = s.idx(r2, c2);
  //           if (!s.isEmpty(i1) ||
  //               !s.isEmpty(i2) ||
  //               !s.isEmpty(i3) ||
  //               !s.isEmpty(i4)) {
  //             continue;
  //           }
  //           final corners = [i1, i2, i3, i4];
  //           for (var a = 1; a <= 9; a++) {
  //             for (var b = a + 1; b <= 9; b++) {
  //               final pair = {a, b};
  //               var subsetCount = 0;
  //               final supers = <int>[];
  //               for (final cell in corners) {
  //                 final candidates = s.notes[cell];
  //                 if (candidates.isEmpty) continue;
  //                 if (candidates.every(pair.contains)) subsetCount++;
  //                 if (candidates.contains(a) &&
  //                     candidates.contains(b) &&
  //                     candidates.length > 2) {
  //                   supers.add(cell);
  //                 }
  //               }
  //               if (subsetCount >= 3 && supers.isNotEmpty) {
  //                 final eliminations = <(int, int)>[];
  //                 for (final cell in supers) {
  //                   if (s.notes[cell].contains(a)) eliminations.add((cell, a));
  //                   if (s.notes[cell].contains(b)) eliminations.add((cell, b));
  //                 }
  //                 if (eliminations.isEmpty) continue;
  //                 final cells = corners.toSet().toList()..sort();
  //                 final digits = [a, b];
  //                 return Hint(
  //                   StrategyType.uniqueRectangle,
  //                   eliminations: eliminations,
  //                   cells: cells,
  //                   digits: digits,
  //                 );
  //               }
  //             }
  //           }
  //         }
  //       }
  //     }
  //   }
  //   return null;
  // }

  // Hint? _findBugHint(Sudoku s, CandidateMap s.notes) => null;

  // Hint? _findRemotePairsHint(Sudoku s, CandidateMap s.notes) => null;

  // Hint? _findXYChainHint(Sudoku s, CandidateMap s.notes) => null;

  // Hint? _findALSHint(Sudoku s, CandidateMap s.notes) => null;

  // Hint? _findALSXyWingHint(Sudoku s, CandidateMap s.notes) => null;

  // Hint? _findAICHint(Sudoku s, CandidateMap s.notes) => null;

  // Backtracking solver (for uniqueness & classification) -- bitmask version
  bool solveBacktracking(Sudoku s) {
    // bitmask rows/cols/boxes: bit k means digit k is used
    final row = List<int>.filled(9, 0);
    final col = List<int>.filled(9, 0);
    final box = List<int>.filled(9, 0);
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final v = s.valueAt(r * 9 + c);
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
      if (s.isEmpty(i)) empties.add(i);
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
        s.setValue(i, d);
        row[r] |= bit;
        col[c] |= bit;
        box[b] |= bit;
        if (dfs(k + 1)) return true;
        row[r] &= ~bit;
        col[c] &= ~bit;
        box[b] &= ~bit;
        s.setValue(i, 0);
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
        final index = r * 9 + c;
        if (!s.isEmpty(index)) {
          final v = s.valueAt(index);
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
      if (s.isEmpty(i)) empties.add(i);
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
        s.setValue(i, d);
        row[r] |= bit;
        col[c] |= bit;
        box[b] |= bit;
        if (dfs(k + 1)) return true;
        row[r] &= ~bit;
        col[c] &= ~bit;
        box[b] &= ~bit;
        s.resetValue(i);
      }
      return false;
    }

    dfs(0);
    return solutions;
  }

  Rating rateLogical(List<int> s) {
    final copy = Sudoku(List<int>.from(s));
    final res = solveLogical(copy);
    final counts = <StrategyType, int>{};
    final first = <StrategyType, int>{};
    for (var i = 0; i < res.steps.length; i++) {
      final st = res.steps[i];
      counts[st] = (counts[st] ?? 0) + 1;
      first.putIfAbsent(st, () => i);
    }
    return Rating(counts, first);
  }
}
