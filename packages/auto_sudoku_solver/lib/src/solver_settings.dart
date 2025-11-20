import 'package:auto_sudoku_solver/src/strategy/strategy.dart';

class SolverSettings {
  final Set<StrategyType> _allowedStrategies;

  /// Constructs SolverSettings allowing only the given strategies.
  /// Accepts either a Set or List of [StrategyType].
  const SolverSettings({Set<StrategyType>? allowed})
    : _allowedStrategies = allowed ?? const {};

  /// Constructs SolverSettings allowing all strategies except those listed in [except].
  /// Accepts either a Set or List of [StrategyType].
  SolverSettings.all({Set<StrategyType>? except})
    : _allowedStrategies = _computeAllExcept(except);

  static Set<StrategyType> _computeAllExcept(Set<StrategyType>? except) {
    final all = Set<StrategyType>.from(StrategyType.values);
    final excluded = except ?? {};
    all.removeAll(excluded);
    return all;
  }

  bool allows(StrategyType type) => _allowedStrategies.contains(type);
}
