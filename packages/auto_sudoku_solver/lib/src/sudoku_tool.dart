// Sudoku Generator + Classifier (Dart)
// ------------------------------------
// Generates valid 9x9 Sudoku puzzles and classifies difficulty.
//
// Difficulty rules used here (as requested):
// - Trivial: Singles only (Naked + Hidden).
// - Easy: Naked + Hidden Pairs/Triples/Quads, plus Locked Candidates (Pointing/Claiming). No fish.
// - Medium: X-Wing and XY-Wing (plus all Easy techniques).
// - Hard: Advanced human techniques above Medium (no guessing).
// - Impossible: Unsolvable even with backtracking, or requires guessing (invalid puzzle).
//
// Usage:
//   dart run sudoku_tool.dart [--target trivial|easy|medium|hard|any] [--seed N] [--board] [--steps]
//                              [--max-attempts N] [--beam W] [--exp K] [--count N] [--out path]
//   - Beam search: keep W best candidates each round (default 1). Each state expands by K random removals per round (default 8).
//   - --count N: generate N puzzles that match the requested difficulty (default 1).
//   - --out path: write a JSON array of {"difficulty","puzzle","solution"} objects to this file (default: sudoku_output.json).
//   - --timeout MS: abort a single generation attempt after MS milliseconds (default 20000).
//   - --max-rounds N: abort beam digging after N rounds (default 400).
//   - JSON output excludes Trivial and Impossible puzzles.
//   - If --board is provided, it also prints the pretty board (difficulty, reason, grids) and progress messages.
//   - If --steps is provided, it lists the logical solving steps used (excluding simple singles).
//   - Use --max-attempts to cap the attempts when searching for an exact difficulty match (default 500).
//
// Implementation notes:
// - Board representation: 81-length List<int> with 0 for empty.
// - Constraint helpers compute peers and boxes.
// - Solver applies strategies in passes until fixed point.
// - Strategies: Naked Single, Hidden Single, Naked Pair/Triple, Hidden Pair/Triple, X-Wing (row/col).
// - Uniqueness check: limited backtracking counting up to 2 solutions.
// - Generator: builds a full solution by backtracking, then removes clues symmetrically
//   while preserving uniqueness and matching the requested difficulty.

import 'dart:convert';
import 'dart:io';

import 'classified_puzzle.dart';
import 'difficulty.dart';
import 'generator.dart';
import 'strategy.dart';
import 'sudoku.dart';

export 'candidate_map.dart';
export 'classified_puzzle.dart';
export 'difficulty.dart';
export 'generator.dart';
export 'hint.dart';
export 'rating.dart';
export 'solve_result.dart';
export 'solver.dart';
export 'strategy.dart';
export 'sudoku.dart';

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

void main(List<String> args) {
  String target = 'any';
  int? seed;
  bool showBoard = false;
  int maxAttempts = 500;
  int beamWidth = 1;
  int expansions = 8;
  int count = 1;
  String outPath = 'sudoku_output.json';
  int timeoutMs = 20000;
  int maxRounds = 400;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--target' && i + 1 < args.length) {
      target = args[++i].toLowerCase();
      if (!['trivial', 'easy', 'medium', 'hard', 'any'].contains(target)) {
        throw ArgumentError(
          'Invalid --target. Use trivial|easy|medium|hard|any',
        );
      }
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
    }
  }

  final gen = Generator(seed: seed);
  final desired = Difficulty.fromString(target);
  final bool showSteps = args.contains('--steps');

  final List<Map<String, dynamic>> outList = [];

  for (var n = 1; n <= count; n++) {
    ClassifiedPuzzle result;
    int attempts = 0;

    print(
      'Generating puzzle $n/$count (target=$target, max $maxAttempts attempts)...',
    );

    do {
      attempts++;
      result = gen.generate(
        target: target,
        beamWidth: beamWidth,
        expansions: expansions,
        timeoutMs: timeoutMs,
        maxRounds: maxRounds,
      );

      final diff = result.difficulty;
      final dist = gen.distanceToTarget(target, result.puzzle);
      print(
        '  Attempt $attempts -> ${diff.toString().split('.').last} (dist=$dist)',
      );
    } while (desired != null &&
        target != 'any' &&
        result.difficulty != desired &&
        attempts < maxAttempts);

    if (desired != null && target != 'any' && result.difficulty != desired) {
      print(
        '  WARNING: Reached max attempts ($maxAttempts) without hitting exact difficulty for item $n; keeping closest attempt.',
      );
    }

    String diffLabel;
    switch (result.difficulty) {
      case Difficulty.trivial:
        diffLabel = 'Trivial';
        break;
      case Difficulty.easy:
        diffLabel = 'Easy';
        break;
      case Difficulty.medium:
        diffLabel = 'Medium';
        break;
      case Difficulty.hard:
        diffLabel = 'Hard';
        break;
      case Difficulty.impossible:
        diffLabel = 'Impossible';
        break;
    }
    print('Difficulty: $diffLabel');
    if (showBoard) {
      print('Puzzle:');
      print(formatGrid(result.puzzle));
      print('Solution:');
      print(formatGrid(result.solution));
    }

    if (showSteps) {
      print('Steps used to solve (excluding naked/hidden singles):');
      final s = Sudoku(List<int>.from(result.puzzle));
      final res = gen.solver.solveLogical(s);
      final filtered = res.steps
          .where(
            (st) =>
                st != StrategyUsed.nakedSingle &&
                st != StrategyUsed.hiddenSingle,
          )
          .toList();
      if (filtered.isEmpty) {
        print('  (No advanced techniques used)');
      } else {
        for (var i = 0; i < filtered.length; i++) {
          print('  ${i + 1}. ${filtered[i]}');
        }
      }
    }

    String diffOut;
    switch (result.difficulty) {
      case Difficulty.trivial:
        diffOut = 'Trivial';
        break;
      case Difficulty.easy:
        diffOut = 'Easy';
        break;
      case Difficulty.medium:
        diffOut = 'Medium';
        break;
      case Difficulty.hard:
        diffOut = 'Hard';
        break;
      case Difficulty.impossible:
        diffOut = 'Impossible';
        break;
    }

    final puzzleStr = result.puzzle.map((e) => e.toString()).join();
    final solutionStr = result.solution.map((e) => e.toString()).join();

    // Compute unique techniques (including singles) for this puzzle, human-readable
    final sTech = Sudoku(List<int>.from(result.puzzle));
    final resTech = gen.solver.solveLogical(sTech);
    final techSet = <StrategyUsed>{};
    for (final st in resTech.steps) {
      techSet.add(st);
    }
    final techniques = techSet.map(techniqueLabel).toList()..sort();

    if (result.difficulty != Difficulty.trivial &&
        result.difficulty != Difficulty.impossible) {
      outList.add({
        'difficulty': diffOut,
        'puzzle': puzzleStr,
        'solution': solutionStr,
        'techniques': techniques,
      });
      print('  -> Added to output');
    } else {
      print('  -> Skipped (Trivial or Impossible)');
    }
  }

  // Write JSON array to file
  final file = File(outPath);
  file.writeAsStringSync(jsonEncode(outList) + '\n');
  print('Wrote ${outList.length} puzzle(s) to $outPath');
}
