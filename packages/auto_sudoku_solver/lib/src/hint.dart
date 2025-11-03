import 'strategy/strategy.dart';

enum HintUnit { row, column, box }

class Hint {
  final StrategyType strategy;
  final List<(int, int)> placements; // (cellIndex, digit) to place immediately
  final List<(int, int)> eliminations; // (cellIndex, digit) to remove
  final List<int> cells; // indices of pattern cells
  final List<int> digits; // digit(s) involved in the pattern
  final HintUnit? unit; // primary unit that triggered the technique

  Hint(
    this.strategy, {
    List<(int, int)>? placements,
    List<(int, int)>? eliminations,
    List<int>? cells,
    List<int>? digits,
    this.unit,
  }) : placements = placements ?? const [],
       eliminations = eliminations ?? const [],
       cells = cells ?? const [],
       digits = digits ?? const [];
}
