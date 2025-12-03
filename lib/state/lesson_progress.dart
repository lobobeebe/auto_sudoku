import 'package:auto_sudoku/data/lessons.dart';
import 'package:auto_sudoku/data/shared_prefs.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonProgress extends ChangeNotifier {
  final Map<StrategyType, _LessonState> _states = {};
  SharedPreferences? _prefs;

  Future<void> loadAll() async {
    _prefs ??= await SharedPreferences.getInstance();
    for (final l in PuzzleLessons.all.entries) {
      final s = _ensure(l.key);
      s.progress = getProgress(_prefs!, l.key);
      s.done = getDone(_prefs!, l.key);
      // total is set later when puzzles load
    }
    notifyListeners();
  }

  // State queries
  bool isDone(StrategyType type) => _ensure(type).done;

  // Mutations
  Future<void> resetAll() async {
    await _ensurePrefs();
    _prefs?.clear();
    _states.clear();
    notifyListeners();
  }

  // Internal helpers
  _LessonState _ensure(StrategyType type) =>
      _states.putIfAbsent(type, () => _LessonState());

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
}

class _LessonState {
  int progress = 0;
  int total = 0;
  bool done = false;
}
