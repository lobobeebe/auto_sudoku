import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

class SudokuPuzzle {
  final String puzzle;
  final String solution;
  final Difficulty difficulty;
  final List<String> techniques;

  SudokuPuzzle({
    required this.puzzle,
    required this.solution,
    required this.difficulty,
    required this.techniques,
  }) : assert(puzzle.length == 81),
       assert(solution.length == 81);

  factory SudokuPuzzle.fromJson(Map<String, dynamic> json) {
    final rawDifficulty = (json['difficulty'] as String?)?.trim() ?? "";
    final difficulty = Difficulty.fromString(rawDifficulty) ?? Difficulty.easy;

    return SudokuPuzzle(
      puzzle: json['puzzle'] as String,
      solution: json['solution'] as String,
      difficulty: difficulty,
      techniques: (json['techniques'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }
}
