import 'package:auto_sudoku_solver/data/tutorial_step.dart';

class Tutorial {
  final List<TutorialStep> steps;
  final bool? overrideShowNotes;

  Tutorial({required this.steps, this.overrideShowNotes});

  factory Tutorial.fromJson(Map<String, dynamic> json) {
    List<TutorialStep>? steps;
    final rawSteps = json['steps'];
    if (rawSteps is List) {
      steps = rawSteps
          .whereType<Map<String, dynamic>>()
          .map((m) => TutorialStep.fromJson(m))
          .toList(growable: false);
    }

    const showNotesKey = 'showNotes';
    bool? showNotes = json.containsKey(showNotesKey)
        ? json[showNotesKey]
        : null;

    return Tutorial(steps: steps ?? [], overrideShowNotes: showNotes);
  }
}
