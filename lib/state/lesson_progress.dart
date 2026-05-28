import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonProgress extends ChangeNotifier {
  static const String _completedLessonPref = "completedLessonIds";

  static const Map<Difficulty, List<String>> lessons = {
    Difficulty.trivial: [
      "BAS101", // hiddenSingle
      "BAS102", // openSingle
      "BAS103", // Complete Trivial
    ],
    Difficulty.easy: [
      "cCeFy1", // openPair
      "j8UYJR", // openTriple
      "SOUX9O", // pointing
      "yNlKCo", // claiming
    ],
    Difficulty.medium: [
      "MORECO", // More coming...
      //"xYJlX2", // XY-Wing
      //"voICg2", // X-Wing
      //"", // W-Wing
    ],
  };

  late Set<String> _completedLessonIds = {};
  SharedPreferences? _prefs;

  Future<void> loadAll() async {
    final prefs = await _getPrefs();

    // Load completed lessons
    _completedLessonIds = (prefs.getStringList(_completedLessonPref) ?? [])
        .toSet();

    notifyListeners();
  }

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  // State queries
  bool isDoneById(String key) => _completedLessonIds.contains(key);

  int getNumLessonsRequired(Difficulty difficulty) {
    // No lesson for difficulty
    if (!lessons.containsKey(difficulty)) {
      return 0;
    }

    final lessonList = lessons[difficulty]!;
    return lessonList.length;
  }

  int getNumLessonsCompleted(Difficulty difficulty) {
    // No lesson for difficulty
    if (!lessons.containsKey(difficulty)) {
      return 0;
    }

    final lessonList = lessons[difficulty]!;
    int numComplete = 0;
    for (final lesson in lessonList) {
      // Return the next incomplete lesson ID in the list
      if (isDoneById(lesson)) {
        numComplete++;
      }
    }

    return numComplete;
  }

  String? getNextLessonByDifficulty(Difficulty difficulty) {
    // No lesson for difficulty
    if (!lessons.containsKey(difficulty)) {
      return null;
    }

    final lessonList = lessons[difficulty]!;
    for (final lesson in lessonList) {
      // Return the next incomplete lesson ID in the list
      if (!isDoneById(lesson)) {
        return lesson;
      }
    }

    // All lessons have been completed
    return null;
  }

  // Mutations
  Future<void> setIsDone(String lessonId) async {
    if (_completedLessonIds.contains(lessonId)) {
      return;
    }

    _completedLessonIds.add(lessonId);

    // Write to prefs
    final prefs = await _getPrefs();
    prefs.setStringList(_completedLessonPref, _completedLessonIds.toList());

    // Notify listeners
    notifyListeners();
  }

  Future<void> resetAll() async {
    final prefs = await _getPrefs();
    prefs.clear();
    _completedLessonIds.clear();
    notifyListeners();
  }
}
