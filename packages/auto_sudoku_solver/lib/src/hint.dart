import 'strategy.dart';

enum HintUnit { row, column, box }

class Hint {
  final StrategyUsed technique;
  final List<(int, int)> placements; // (cellIndex, digit) to place immediately
  final List<(int, int)> eliminations; // (cellIndex, digit) to remove
  final List<int> cells; // indices of pattern cells
  final List<int> digits; // digit(s) involved in the pattern
  final HintUnit? unit; // primary unit that triggered the technique

  Hint(
    this.technique, {
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
