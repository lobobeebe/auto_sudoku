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
//   dart run sudoku_tool.dart [--target trivial|easy|medium|hard|any] [--seed N] [--board]
//                              [--max-attempts N] [--beam W] [--exp K] [--count N] [--out path]
//                              [--allow techniques] [--except techniques]
//   - Beam search: keep W best candidates each round (default 1). Each state expands by K random removals per round (default 8).
//   - --count N: generate N puzzles that match the requested difficulty (default 1).
//   - --out path: write a JSON array of {"puzzle","solution","techniques"} objects to this file (default: sudoku_output.json).
//   - --timeout MS: abort a single generation attempt after MS milliseconds (default 20000).
//   - --max-rounds N: abort beam digging after N rounds (default 400).
//   - JSON output excludes Trivial and Impossible puzzles.
//   - If --board is provided, it also prints the pretty board (difficulty, reason, grids) and progress messages.
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

import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:auto_sudoku_solver/src/classified_puzzle.dart';
import 'package:auto_sudoku_solver/src/difficulty.dart';
import 'package:auto_sudoku_solver/src/generator.dart';
import 'package:auto_sudoku_solver/src/strategy/strategy.dart';
import 'package:auto_sudoku_solver/src/sudoku.dart';

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
  Difficulty target = Difficulty.easy;
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
      final inTarget = Difficulty.fromString(args[++i].toLowerCase());
      if (inTarget == null) {
        throw ArgumentError(
          'Invalid --target. Use ${Difficulty.values.map((d) => d.name).join('|')}.',
        );
      }
      target = inTarget;
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

  // Parse strategy filters
  Set<StrategyType>? allow;
  Set<StrategyType>? except;

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
    if (a == '--allow' && i + 1 < args.length) {
      allow = parseTechList(args[++i]);
    } else if (a == '--except' && i + 1 < args.length) {
      except = parseTechList(args[++i]);
    }
  }

  final SolverSettings settings = allow != null
      ? SolverSettings(allowed: allow)
      : SolverSettings.all(except: except);

  final gen = Generator(seed: seed, settings: settings);
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
    } while (result.difficulty != target && attempts < maxAttempts);

    if (result.difficulty != target) {
      print(
        '  WARNING: Reached max attempts ($maxAttempts) without hitting exact difficulty for item $n; keeping closest attempt.',
      );
    }

    String diffLabel = result.difficulty.name;
    print('Difficulty: $diffLabel');
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

    if (result.difficulty != Difficulty.trivial &&
        result.difficulty != Difficulty.impossible) {
      outList.add({
        'id': SudokuModel.computeIdFromPuzzle(puzzleStr),
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
  file.writeAsStringSync('${jsonEncode(outList)}\n');
  print('Wrote ${outList.length} puzzle(s) to $outPath');
}
