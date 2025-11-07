import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

// Model class for reading Sudoku Puzzles from data
class SudokuModel {
  final String puzzle;
  final String solution;
  final Difficulty difficulty;
  final List<String> techniques;

  SudokuModel({
    required this.puzzle,
    required this.solution,
    required this.difficulty,
    required this.techniques,
  }) : assert(puzzle.length == 81),
       assert(solution.length == 81);

  factory SudokuModel.fromJson(Map<String, dynamic> json) {
    final rawDifficulty = (json['difficulty'] as String?)?.trim() ?? "";
    final difficulty = Difficulty.fromString(rawDifficulty) ?? Difficulty.easy;

    return SudokuModel(
      puzzle: json['puzzle'] as String,
      solution: json['solution'] as String,
      difficulty: difficulty,
      techniques: (json['techniques'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }
}
