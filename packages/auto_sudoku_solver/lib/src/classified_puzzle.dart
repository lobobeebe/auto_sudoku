import 'difficulty.dart';

class ClassifiedPuzzle {
  final List<int> puzzle; // 81 values, 0 = empty
  final List<int> solution; // solved grid
  final Difficulty difficulty;
  final String reason;
  ClassifiedPuzzle(this.puzzle, this.solution, this.difficulty, this.reason);
}
