import 'dart:math';

import 'classified_puzzle.dart';
import 'difficulty.dart';
import 'solver.dart';
import 'strategy.dart';
import 'sudoku.dart';

// Helper class for generator beam state (used in Generator.generate)
class _State {
  final List<int> grid;
  final int dist;
  const _State(this.grid, this.dist);
}

enum Symmetry { none, rot180, diag, central }

enum Direction { row, col, box }

class PrunePolicy {
  final Symmetry symmetry;
  final bool enforceMinimality;
  final bool ratingGuided;
  final int backboneSteps; // require first K steps to be gentle
  final int minPerBox;
  final int minPerRow;
  final int minPerCol;
  final int minPerDigit;
  const PrunePolicy({
    this.symmetry = Symmetry.rot180,
    this.enforceMinimality = true,
    this.ratingGuided = true,
    this.backboneSteps = 5,
    this.minPerBox = 0,
    this.minPerRow = 0,
    this.minPerCol = 0,
    this.minPerDigit = 0,
  });
}

class Generator {
  final Random rng;
  final Solver solver;
  final PrunePolicy policy;

  Generator({int? seed, PrunePolicy? policy})
    : rng = Random(seed),
      solver = Solver(),
      policy = policy ?? const PrunePolicy();

  // Create a complete solved board by randomized backtracking
  List<int> _randomSolvedGrid() {
    final s = Sudoku(List.filled(81, 0));
    bool fillSmart() {
      // Choose cell with fewest valid options (MRV)
      int best = -1, bestCount = 10;
      for (var i = 0; i < 81; i++) {
        if (s.cells[i] == 0) {
          int c = 0;
          for (var d = 1; d <= 9; d++) {
            if (s.isValidPlacement(i, d)) c++;
          }
          if (c < bestCount) {
            bestCount = c;
            best = i;
          }
        }
      }
      if (best == -1) return true;
      final ds = List<int>.generate(9, (i) => i + 1)..shuffle(rng);
      for (final d in ds) {
        if (s.isValidPlacement(best, d)) {
          s.cells[best] = d;
          if (fillSmart()) return true;
          s.cells[best] = 0;
        }
      }
      return false;
    }

    fillSmart();
    return s.cells;
  }

  int _distanceToTarget(Difficulty targetDiff, List<int> grid) {
    // compute rating with broad logical flags enabled
    final r = solver.rateLogical(Sudoku(List<int>.from(grid)));

    // penalties
    var dist = 0;
    for (final e in r.counts.entries) {
      if (e.key.getDifficulty() != targetDiff) {
        dist += e.value;
      }
    }
    return dist;
  }

  int distanceToTarget(Difficulty target, List<int> grid) =>
      _distanceToTarget(target, grid);

  ClassifiedPuzzle generate({
    Difficulty target = Difficulty.easy,
    int beamWidth = 1,
    int expansions = 8,
    int timeoutMs = 20000,
    int maxRounds = 400,
  }) {
    final full = _randomSolvedGrid();
    final watch = Stopwatch()..start();

    bool isUnique(List<int> grid) {
      final s = Sudoku(List<int>.from(grid));
      return solver.countSolutions(s) == 1;
    }

    List<int> symGroup(int i) {
      switch (policy.symmetry) {
        case Symmetry.none:
          return [i];
        case Symmetry.rot180:
          return (i == 80 - i) ? [i] : [i, 80 - i];
        case Symmetry.diag:
          final r = i ~/ 9, c = i % 9;
          final j = c * 9 + r; // transpose
          return (i == j) ? [i] : [i, j];
        case Symmetry.central:
          final r = i ~/ 9, c = i % 9;
          final j = (8 - r) * 9 + (8 - c);
          final k = r * 9 + (8 - c);
          final l = (8 - r) * 9 + c;
          final set = {i, j, k, l}.toList();
          return set;
      }
    }

    bool violatesQuotas(List<int> grid) {
      final perRow = List.filled(9, 0);
      final perCol = List.filled(9, 0);
      final perBox = List.filled(9, 0);
      final perDigit = List.filled(10, 0);
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final v = grid[r * 9 + c];
          if (v != 0) {
            perRow[r]++;
            perCol[c]++;
            perBox[(r ~/ 3) * 3 + (c ~/ 3)]++;
            perDigit[v]++;
          }
        }
      }
      for (var i = 0; i < 9; i++) {
        if (perRow[i] < policy.minPerRow) return true;
        if (perCol[i] < policy.minPerCol) return true;
        if (perBox[i] < policy.minPerBox) return true;
      }
      for (var d = 1; d <= 9; d++) {
        if (perDigit[d] < policy.minPerDigit) return true;
      }
      return false;
    }

    // (Local _State class removed; now using top-level _State)

    // Helper: compare two grids for equality
    bool gridsEqual(List<int> a, List<int> b) {
      if (identical(a, b)) return true;
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }

    // start from the full solution and dig
    List<_State> beam = [
      _State(List<int>.from(full), _distanceToTarget(target, full)),
    ];

    // helper to try removing a symmetric group from a grid
    List<int>? tryRemove(List<int> grid, int cell) {
      if (grid[cell] == 0) return null;
      final group = symGroup(cell).where((g) => grid[g] != 0).toList();
      if (group.isEmpty) return null;
      final next = List<int>.from(grid);
      for (final g in group) {
        next[g] = 0;
      }
      if (!isUnique(next)) return null;
      if (violatesQuotas(next)) return null;
      // Signature forcing via distance
      final nd = _distanceToTarget(target, next);
      // Reject if it obviously pushes outside target by a large amount
      if (nd > 2000) return null;
      return next;
    }

    int stagnant = 0;
    List<int>? lastBestGrid;
    int lastBestDist = 1 << 30;
    int digSteps = 0;
    while (true) {
      final children = <_State>[];
      for (final st in beam) {
        // choose a few random candidates to try
        for (var e = 0; e < expansions; e++) {
          final i = rng.nextInt(81);
          final next = tryRemove(st.grid, i);
          if (next == null) continue;
          final dist = _distanceToTarget(target, next);
          children.add(_State(next, dist));
        }
      }
      if (children.isEmpty) break;
      // keep best beamWidth
      children.sort((a, b) => a.dist.compareTo(b.dist));
      beam = children.take(max(1, beamWidth)).toList();
      digSteps++;

      // Timeout / max-rounds guard
      if (watch.elapsedMilliseconds > timeoutMs || digSteps >= maxRounds) {
        break;
      }

      // Stagnation detection: if best grid and dist do not change for many rounds, stop
      final best = beam.first;
      if (lastBestGrid != null &&
          best.dist == lastBestDist &&
          gridsEqual(best.grid, lastBestGrid)) {
        stagnant++;
      } else {
        stagnant = 0;
        lastBestDist = best.dist;
        lastBestGrid = List<int>.from(best.grid);
      }
      if (stagnant >= 30) {
        break;
      }

      // check best for fit
      final bestClass = classify(best.grid);
      final diff = bestClass;
      if (diff == target) {
        final sol = Sudoku(List<int>.from(best.grid));
        solver.solveBacktracking(sol);
        return ClassifiedPuzzle(best.grid, sol.cells, diff);
      }
      // stop if puzzle is too empty
      final clues = best.grid.where((v) => v != 0).length;
      if (clues <= 22) break; // guardrail
    }

    if (beam.isNotEmpty) {
      final best = beam.first;
      final bestClass = classify(best.grid);
      final diff = bestClass;
      // If we timed out or stagnated, return the best-so-far (if it has a valid solution)
      final sol = Sudoku(List<int>.from(best.grid));
      if (solver.solveBacktracking(sol)) {
        return ClassifiedPuzzle(best.grid, sol.cells, diff);
      }
    }

    final greedy = List<int>.from(full);
    final candidates = [for (var i = 0; i < 81; i++) i]..shuffle(rng);
    for (final i in candidates) {
      if (greedy[i] == 0) continue;
      final group = symGroup(i).where((g) => greedy[g] != 0).toList();
      if (group.isEmpty) continue;
      final saved = [for (final g in group) greedy[g]];
      for (final g in group) {
        greedy[g] = 0;
      }
      if (!isUnique(greedy) || violatesQuotas(greedy)) {
        for (var k = 0; k < group.length; k++) {
          greedy[group[k]] = saved[k];
        }
      }
    }
    final classification = classify(greedy);
    final sol = Sudoku(List<int>.from(greedy));
    if (!solver.solveBacktracking(sol)) {
      return ClassifiedPuzzle(
        greedy,
        List<int>.from(full),
        Difficulty.impossible,
      );
    }
    return ClassifiedPuzzle(greedy, sol.cells, classification);
  }

  Difficulty classify(List<int> grid) {
    final t = Sudoku(List<int>.from(grid));
    final tr = solver.solveLogical(t);

    if (!tr.solved) {
      return Difficulty.impossible;
    }

    Difficulty maxDifficulty = Difficulty.trivial;
    for (StrategyUsed tech in tr.steps) {
      final difficulty = tech.getDifficulty();
      maxDifficulty = Difficulty.max(difficulty, maxDifficulty);
    }

    return maxDifficulty;
  }
}
