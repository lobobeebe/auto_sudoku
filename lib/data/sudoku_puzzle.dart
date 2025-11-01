class SudokuPuzzle {
  final String puzzle;
  final String solution;
  final String difficulty;
  final List<String> techniques;

  SudokuPuzzle({
    required this.puzzle,
    required this.solution,
    required this.difficulty,
    required this.techniques,
  })  : assert(puzzle.length == 81),
        assert(solution.length == 81);

  factory SudokuPuzzle.fromJson(Map<String, dynamic> json) {
    return SudokuPuzzle(
      puzzle: json['puzzle'] as String,
      solution: json['solution'] as String,
      difficulty: (json['difficulty'] as String?)?.trim().isNotEmpty == true
          ? json['difficulty'] as String
          : 'Unknown',
      techniques: (json['techniques'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }
}
