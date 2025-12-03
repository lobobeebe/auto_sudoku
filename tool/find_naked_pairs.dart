import 'dart:convert';
import 'dart:io';

import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

void main(List<String> args) async {
  // Read the lesson file path from args or default to easy_strategies.json
  final lessonPath = args.isNotEmpty
      ? args.first
      : 'assets/puzzles/lessons/easy_strategies.json';

  final file = File(lessonPath);
  if (!await file.exists()) {
    stderr.writeln('Lesson file not found: $lessonPath');
    exit(1);
  }
  final raw = await file.readAsString();
  final data = json.decode(raw);
  if (data is! List || data.isEmpty || data.first is! Map) {
    stderr.writeln('Unexpected JSON format in $lessonPath');
    exit(1);
  }
  final first = data.first as Map<String, dynamic>;
  final puzzle = (first['puzzle'] ?? '').toString();
  if (puzzle.length != 81) {
    stderr.writeln('Puzzle string must be 81 chars');
    exit(1);
  }

  final s = Sudoku.fromString(puzzle);

  // Helper to get all pairs (two-cell combos) that form a valid Open Pair
  // in rows, columns, and boxes at the current candidate state.
  List<(List<int> cells, List<int> digits, HintUnit unit, int unitIndex)>
  findOpenPairs(Sudoku s) {
    final results = <(List<int>, List<int>, HintUnit, int)>[];

    void processUnit(Iterable<int> unit, HintUnit unitType, int unitIdx) {
      final empties = unit.where((i) => s.isEmpty(i)).toList();
      if (empties.length < 2) return;

      // Consider cells with 2 candidates (pairs can also include a cell with >2
      // as long as union size is 2, but standard Open Pair requires each cell
      // has subset of size 2..2 or <=2? Here we allow 2..2 and union size 2.
      final subsetPool = empties.where((i) => s.numNotesAt(i) >= 2).toList();
      for (var a = 0; a < subsetPool.length; a++) {
        for (var b = a + 1; b < subsetPool.length; b++) {
          final i = subsetPool[a];
          final j = subsetPool[b];
          final candsI = s.notesSet(i);
          final candsJ = s.notesSet(j);
          final union = {...candsI, ...candsJ};
          if (union.length != 2) continue;
          // There must be an elimination elsewhere in the unit for it to be useful
          var hasElimination = false;
          for (final k in empties) {
            if (k == i || k == j) continue;
            final c = s.notesSet(k);
            if (c.any(union.contains)) {
              hasElimination = true;
              break;
            }
          }
          if (!hasElimination) continue;
          final cells = [i, j]..sort();
          final digits = union.toList()..sort();
          results.add((cells, digits, unitType, unitIdx));
        }
      }
    }

    for (var r = 0; r < 9; r++) {
      processUnit(s.rowIndices(r), HintUnit.row, r);
    }
    for (var c = 0; c < 9; c++) {
      processUnit(s.colIndices(c), HintUnit.column, c);
    }
    for (var b = 0; b < 9; b++) {
      processUnit(s.boxIndices(b), HintUnit.box, b);
    }
    // Deduplicate by cells+unit
    final seen = <String>{};
    final unique = <(List<int>, List<int>, HintUnit, int)>[];
    for (final r in results) {
      final key = '${r.$3}-${r.$4}-${r.$1.join(',')}';
      if (seen.add(key)) unique.add(r);
    }
    return unique;
  }

  final pairs0 = findOpenPairs(s);
  if (pairs0.isEmpty) {
    print('No Open Pair at initial state.');
  } else {
    // Print initial pairs
    for (var idx = 0; idx < pairs0.length && idx < 10; idx++) {
      final p = pairs0[idx];
      final unit = switch (p.$3) {
        HintUnit.row => 'row',
        HintUnit.column => 'col',
        HintUnit.box => 'box',
        null => 'unit',
      };
      print('initial[$idx]: cells=${p.$1} digits=${p.$2} unit=$unit${p.$4}');
    }
  }

  // Apply a few Open Singles until a new pair appears
  final solver = Solver(
    settings: SolverSettings(allowed: {StrategyType.openSingle}),
  );
  final s2 = s.clone();
  var singlesApplied = 0;
  const maxSingles = 20;
  while (singlesApplied < maxSingles) {
    final h = solver.nextHint(s2);
    if (h == null) break;
    if (h.strategy != StrategyType.openSingle) break;
    final changed = s2.applyHint(h);
    // Log the placement(s)
    if (h.placements.isNotEmpty) {
      for (final e in h.placements.entries) {
        print('placed single: idx=${e.key} digit=${e.value}');
      }
    }
    if (changed.isEmpty) break;
    singlesApplied++;
    final pairsNow = findOpenPairs(s2);
    // Find a pair that wasn't present initially
    final firstNew = pairsNow.firstWhere(
      (p) => !pairs0.any(
        (q) =>
            q.$3 == p.$3 &&
            q.$4 == p.$4 &&
            q.$1[0] == p.$1[0] &&
            q.$1[1] == p.$1[1],
      ),
      orElse: () => ([], [], HintUnit.row, -1),
    );
    if (firstNew.$1.isNotEmpty) {
      final unit = switch (firstNew.$3) {
        HintUnit.row => 'row',
        HintUnit.column => 'col',
        HintUnit.box => 'box',
        null => 'unit',
      };
      print(
        'after $singlesApplied singles: cells=${firstNew.$1} digits=${firstNew.$2} unit=$unit${firstNew.$4}',
      );
      break;
    }
  }
}
