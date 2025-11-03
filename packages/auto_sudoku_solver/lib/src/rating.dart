import 'difficulty.dart';
import 'strategy/strategy.dart';

class Rating {
  final Difficulty bucket; // caller's classification bucket for reference
  final Map<StrategyType, int> counts;
  final Map<StrategyType, int> firstUseIndex;
  const Rating(this.bucket, this.counts, this.firstUseIndex);
}
