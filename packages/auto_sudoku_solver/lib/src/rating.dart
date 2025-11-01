import 'difficulty.dart';
import 'strategy.dart';

class Rating {
  final Difficulty bucket; // caller's classification bucket for reference
  final int hardestIdx; // index into strategyDifficultyOrder
  final Map<StrategyUsed, int> counts;
  final Map<StrategyUsed, int> firstUseIndex;
  const Rating(this.bucket, this.hardestIdx, this.counts, this.firstUseIndex);
}
