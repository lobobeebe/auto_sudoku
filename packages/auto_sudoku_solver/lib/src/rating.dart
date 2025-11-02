import 'difficulty.dart';
import 'strategy.dart';

class Rating {
  final Difficulty bucket; // caller's classification bucket for reference
  final Map<StrategyUsed, int> counts;
  final Map<StrategyUsed, int> firstUseIndex;
  const Rating(this.bucket, this.counts, this.firstUseIndex);
}
