import 'package:auto_sudoku_solver/src/sudoku_tool.dart';

import 'strategy.dart';

class SolveResult {
  final bool solved;
  final bool stuck;
  final List<StrategyUsed> steps;
  SolveResult(this.solved, this.stuck, this.steps);
}
