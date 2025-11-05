import 'strategy/strategy.dart';

enum HintUnit { row, column, box }

class Hint {
  final StrategyType strategy;
  final Map<int, int> placements; // (cellIndex, digit) to place immediately
  final Map<int, Set<int>> eliminations; // (cellIndex, set of digits) to remove
  final List<int> cells; // indices of pattern cells
  final List<int> digits; // digit(s) involved in the pattern
  final HintUnit? unit; // primary unit that triggered the technique

  Hint(
    this.strategy, {
    Map<int, int>? placements,
    Map<int, Set<int>>? eliminations,
    List<int>? cells,
    List<int>? digits,
    this.unit,
  }) : placements = placements ?? <int, int>{},
       eliminations = eliminations ?? <int, Set<int>>{},
       cells = cells ?? const [],
       digits = digits ?? const [];
}
