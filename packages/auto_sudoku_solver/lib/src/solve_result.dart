import 'strategy.dart';

class SolveResult {
  final bool solved;
  final bool stuck;
  final List<StrategyUsed> steps;
  SolveResult(this.solved, this.stuck, this.steps);

  StrategyUsed hardestInPrefix(int k) {
    final n = steps.length < k ? steps.length : k;
    var hardest = StrategyUsed.nakedSingle;
    for (var i = 0; i < n; i++) {
      final s = steps[i];
      if (strategyDifficultyIndex(s) > strategyDifficultyIndex(hardest)) {
        hardest = s;
      }
    }
    return hardest;
  }
}
