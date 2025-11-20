import 'dart:convert';
import 'dart:io';

import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:auto_sudoku_solver/src/solver.dart';
import 'package:auto_sudoku_solver/src/sudoku.dart';

// Verifies puzzles and emits normalized JSON array with
// { "puzzle": String(81), "solution": String(81), "techniques": {name: count} }
void main(List<String> args) {
  String inPath = 'sudoku_output.json';
  String outPath = 'sudoku_output.json';

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--in' && i + 1 < args.length) {
      inPath = args[++i];
    } else if (a == '--out' && i + 1 < args.length) {
      outPath = args[++i];
    }
  }

  // Setup solver
  final solver = Solver(settings: SolverSettings.all());

  // Read JSON array from file. Input can be an array of:
  // - Strings (puzzle only)
  // - Objects with a "puzzle" field (other fields ignored)
  final file = File(inPath);
  final dynamic decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! List) {
    stderr.writeln('Input is not a JSON array: $inPath');
    exitCode = 2;
    return;
  }

  final output = <Map<String, dynamic>>[];
  int index = 0;
  for (final entry in decoded) {
    index++;
    String? puzzleStr;
    String? id;
    if (entry is String && entry.length == 81) {
      puzzleStr = entry;
    } else if (entry is Map) {
      final p = entry['puzzle']?.toString();
      if (p != null && p.length == 81) puzzleStr = p;
      final maybeId = entry['id']?.toString();
      if (maybeId != null && maybeId.isNotEmpty) id = maybeId;
    }
    if (puzzleStr == null) {
      stderr.writeln('Skipping item #$index: invalid puzzle format');
      continue;
    }

    final s = Sudoku.fromString(puzzleStr);
    final res = solver.solveLogical(s);
    if (!res.solved) {
      stderr.writeln('Warning: unsolved puzzle at index $index; excluding');
      continue;
    }

    // Collect technique counts
    final Map<String, int> techniques = {};
    for (final st in res.steps) {
      final label = st.toString();
      techniques[label] = (techniques[label] ?? 0) + 1;
    }

    final solutionStr = s.grid.map((e) => e.toString()).join();

    output.add({
      'id': id ?? SudokuModel.computeIdFromPuzzle(puzzleStr),
      'puzzle': puzzleStr,
      'solution': solutionStr,
      'techniques': techniques,
    });
  }

  final outFile = File(outPath);
  outFile.writeAsStringSync('${jsonEncode(output)}\n');
  stdout.writeln('Wrote ${output.length} puzzle(s) to $outPath');
}
