import 'strategy/strategy.dart';

class Rating {
  final Map<StrategyType, int> counts;
  final Map<StrategyType, int> firstUseIndex;
  const Rating(this.counts, this.firstUseIndex);
}
