import 'strategy.dart';

class Hint {
  final StrategyUsed technique;
  final List<(int, int)> placements; // (cellIndex, digit) to place immediately
  final List<(int, int)> eliminations; // (cellIndex, digit) to remove
  final List<int> cells; // indices of pattern cells
  final List<int> digits; // digit(s) involved in the pattern

  Hint(
    this.technique, {
    List<(int, int)>? placements,
    List<(int, int)>? eliminations,
    List<int>? cells,
    List<int>? digits,
  }) : placements = placements ?? const [],
       eliminations = eliminations ?? const [],
       cells = cells ?? const [],
       digits = digits ?? const [];
}
