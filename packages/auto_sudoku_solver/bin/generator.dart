// Sudoku Generator + Classifier (Dart)
// ------------------------------------
// Generates valid 9x9 Sudoku puzzles and classifies difficulty.
//
// Difficulty rules used here (as requested):
// - Trivial: Singles only (Open + Hidden).
// - Easy: Open + Hidden Pairs/Triples/Quads, plus Locked Candidates (Pointing/Claiming). No fish.
// - Medium: X-Wing and XY-Wing (plus all Easy techniques).
// - Hard: Advanced human techniques above Medium (no guessing).
// - Impossible: Unsolvable even with backtracking, or requires guessing (invalid puzzle).
//
// Usage:
//   dart run sudoku_tool.dart [--target trivial|easy|medium|hard|any] [--seed N] [--board]
//                              [--max-attempts N] [--beam W] [--exp K] [--count N] [--out path]
//                              [--allow techniques] [--except techniques]
//   - Beam search: keep W best candidates each round (default 1). Each state expands by K random removals per round (default 8).
//   - --count N: generate N puzzles that match the requested difficulty (default 1).
//   - --out path: write a JSON array of {"puzzle","solution","techniques"} objects to this file (default: sudoku_output.json).
//   - --timeout MS: abort a single generation attempt after MS milliseconds (default 20000).
//   - --max-rounds N: abort beam digging after N rounds (default 400).
//   - --min-moves N: require at least N logical steps to solve.
//   - --max-moves N: require at most N logical steps to solve.
//   - JSON output excludes Trivial and Impossible puzzles.
//   - If --board is provided, it also prints the pretty board (difficulty, reason, grids) and progress messages.
//   - Use --max-attempts to cap the attempts when searching for an exact difficulty match (default 500).
//
// Implementation notes:
// - Board representation: 81-length List<int> with 0 for empty.
// - Constraint helpers compute peers and boxes.
// - Solver applies strategies in passes until fixed point.
// - Strategies: Open Single, Hidden Single, Open Pair/Triple, Hidden Pair/Triple, X-Wing (row/col).
// - Uniqueness check: limited backtracking counting up to 2 solutions.
// - Generator: builds a full solution by backtracking, then removes clues symmetrically
//   while preserving uniqueness and matching the requested difficulty.

import 'dart:convert';
import 'dart:io';

import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:auto_sudoku_solver/src/classified_puzzle.dart';
import 'package:auto_sudoku_solver/src/generator.dart';

String formatGrid(List<int> g) {
  final sb = StringBuffer();
  for (var r = 0; r < 9; r++) {
    if (r % 3 == 0) sb.writeln('+-------+-------+-------+');
    for (var c = 0; c < 9; c++) {
      if (c % 3 == 0) sb.write('| ');
      final v = g[r * 9 + c];
      sb.write(v == 0 ? '. ' : '$v ');
    }
    sb.writeln('|');
  }
  sb.writeln('+-------+-------+-------+');
  return sb.toString();
}

void _printUsage() {
  print('Sudoku Generator + Classifier');
  print(
    'Usage: dart run packages/auto_sudoku_solver/bin/generator.dart '
    '[--target trivial|easy|medium|hard|any] [--seed N] [--board]',
  );
  print(
    '       [--max-attempts N] [--beam W] [--exp K] [--count N] [--out path]',
  );
  print('       [--allow techniques] [--except techniques]');
  print(
    '       [--timeout MS] [--max-rounds N] [--min-moves N] [--max-moves N]',
  );
  print('Options:');
  print('  --seed          RNG seed for reproducible generation');
  print('  --board         Print board grids and progress for each result');
  print('  --max-attempts  Limit attempts per puzzle (default: 500)');
  print('  --beam          Beam width for search (default: 1)');
  print('  --exp           Expansions per round (default: 8)');
  print('  --count         Number of puzzles to generate (default: 1)');
  print('  --out           Output JSON path (default: sudoku_output.json)');
  print('  --allow         Comma-separated strategies to allow');
  print('  --except        Comma-separated strategies to disallow');
  print(
    '  --timeout       Generation timeout per attempt in ms (default: 20000)',
  );
  print('  --max-rounds    Limit beam digging rounds (default: 400)');
  print('  --min-moves     Require at least this many logical steps');
  print('  --max-moves     Require at most this many logical steps');
  print('  --help          Show this help and exit');
}

void main(List<String> args) {
  Set<StrategyType> must = {};
  Set<StrategyType>? only;

  int? seed;
  bool showBoard = false;
  int maxAttempts = 500;
  int beamWidth = 1;
  int expansions = 8;
  int count = 1;
  String outPath = 'sudoku_output.json';
  int timeoutMs = 20000;
  int maxRounds = 400;
  int? minMoves; // Minimum number of logical steps required
  int? maxMoves; // Maximum number of logical steps allowed

  Set<StrategyType> parseTechList(String raw) {
    final parts = raw.split(',');
    final out = <StrategyType>{};
    for (final p in parts) {
      final t = p.trim().toLowerCase();
      for (final st in StrategyType.values) {
        if (st.toString().toLowerCase() == t || st.name.toLowerCase() == t) {
          out.add(st);
          break;
        }
      }
    }
    return out;
  }

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--help') {
      _printUsage();
      return;
    } else if (a == '--only' && i + 1 < args.length) {
      only = parseTechList(args[++i]);
    } else if (a == '--must' && i + 1 < args.length) {
      must = parseTechList(args[++i]);
    } else if (a == '--seed' && i + 1 < args.length) {
      seed = int.tryParse(args[++i]);
    } else if (a == '--board') {
      showBoard = true;
    } else if (a == '--max-attempts' && i + 1 < args.length) {
      maxAttempts = int.tryParse(args[++i]) ?? maxAttempts;
    } else if (a == '--beam' && i + 1 < args.length) {
      beamWidth = int.tryParse(args[++i]) ?? beamWidth;
    } else if (a == '--exp' && i + 1 < args.length) {
      expansions = int.tryParse(args[++i]) ?? expansions;
    } else if (a == '--count' && i + 1 < args.length) {
      count = int.tryParse(args[++i]) ?? count;
      if (count < 1) count = 1;
    } else if (a == '--out' && i + 1 < args.length) {
      outPath = args[++i];
    } else if (a == '--timeout' && i + 1 < args.length) {
      timeoutMs = int.tryParse(args[++i]) ?? timeoutMs;
    } else if (a == '--max-rounds' && i + 1 < args.length) {
      maxRounds = int.tryParse(args[++i]) ?? maxRounds;
    } else if (a == '--min-moves' && i + 1 < args.length) {
      minMoves = int.tryParse(args[++i]);
    } else if (a == '--max-moves' && i + 1 < args.length) {
      maxMoves = int.tryParse(args[++i]);
    }
  }

  final SolverSettings settings = only != null
      ? SolverSettings(allowed: only)
      : SolverSettings.all();

  final gen = Generator(seed: seed, settings: settings);
  final List<Map<String, dynamic>> outList = [];

  for (var n = 1; n <= count; n++) {
    ClassifiedPuzzle result;
    int attempts = 0;

    print(
      'Generating puzzle $n/$count (must=${must.map((e) => e.name).join(',')}, only=${only?.map((e) => e.name).join(',') ?? '-'}, minMoves=${minMoves ?? 0}, maxMoves=${maxMoves ?? '-'}, max $maxAttempts attempts)...',
    );

    do {
      attempts++;
      result = gen.generate(
        mustUse: must,
        minMoves: minMoves ?? 0,
        beamWidth: beamWidth,
        expansions: expansions,
        timeoutMs: timeoutMs,
        maxRounds: maxRounds,
      );

      // Verify signature satisfaction
      final check = gen.solver.solveLogical(
        Sudoku(List<int>.from(result.puzzle)),
      );
      final present = check.steps.toSet();
      final stepsCount = check.steps.length;
      final requiredMoves = minMoves ?? 0;
      final int? cap = maxMoves;
      final withinMax = cap == null || stepsCount <= cap;
      final satisfied =
          must.every(present.contains) &&
          (only == null || check.solved) &&
          (minMoves == null || stepsCount >= requiredMoves) &&
          withinMax;
      print('  Attempt $attempts -> satisfied=$satisfied, steps=$stepsCount');
      if (satisfied) break;
    } while (attempts < maxAttempts);
    if (showBoard) {
      print('Puzzle:');
      print(formatGrid(result.puzzle));
      print('Solution:');
      print(formatGrid(result.solution));
    }

    final puzzleStr = result.puzzle.map((e) => e.toString()).join();
    final solutionStr = result.solution.map((e) => e.toString()).join();

    // Compute technique counts for this puzzle (including singles)
    final sTech = Sudoku(List<int>.from(result.puzzle));
    final resTech = gen.solver.solveLogical(sTech);
    final Map<String, int> techniques = {};
    for (final st in resTech.steps) {
      final label = st.toString();
      techniques[label] = (techniques[label] ?? 0) + 1;
    }

    outList.add({
      'id': SudokuModel.computeIdFromPuzzle(puzzleStr),
      'puzzle': puzzleStr,
      'solution': solutionStr,
      'techniques': techniques,
    });
    print('  -> Added to output');
  }

  // Write JSON array to file
  final file = File(outPath);
  file.writeAsStringSync('${jsonEncode(outList)}\n');
  print('Wrote ${outList.length} puzzle(s) to $outPath');
}
