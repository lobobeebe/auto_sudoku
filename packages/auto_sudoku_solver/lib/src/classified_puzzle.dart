import 'difficulty.dart';

class ClassifiedPuzzle {
  final List<int> puzzle; // 81 values, 0 = empty
  final List<int> solution; // solved grid
  final Difficulty difficulty;
  ClassifiedPuzzle(this.puzzle, this.solution, this.difficulty);
}
