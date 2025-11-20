import 'package:auto_sudoku/data/lesson.dart';
import 'package:auto_sudoku/data/lessons.dart';
import 'package:auto_sudoku/data/shared_prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonProgress extends ChangeNotifier {
  final Map<String, _LessonState> _states = {};
  SharedPreferences? _prefs;

  Future<void> loadAll() async {
    _prefs ??= await SharedPreferences.getInstance();
    for (final l in Lessons.all) {
      final s = _ensure(l.title);
      s.progress = getProgress(_prefs!, l.title);
      s.done = getDone(_prefs!, l.title);
      // total is set later when puzzles load
    }
    notifyListeners();
  }

  // State queries
  int progressFor(Lesson l) => _ensure(l.title).progress;
  int totalFor(Lesson l) => _ensure(l.title).total;
  bool isDone(Lesson l) => _ensure(l.title).done;
  bool isDoneByTitle(String title) => _ensure(title).done;
  bool isPrereqDone(Lesson l) =>
      l.preReqLesson == null || _ensure(l.preReqLesson!).done;

  // Mutations
  Future<void> setTotal(Lesson l, int total) async {
    final s = _ensure(l.title);
    s.total = total;
    _recomputeDone(l.title);
    notifyListeners();
  }

  Future<void> markSolvedIndex(Lesson l, int index) async {
    await _ensurePrefs();
    final s = _ensure(l.title);
    final next = (s.progress >= index + 1) ? s.progress : index + 1;
    if (next != s.progress) {
      s.progress = next;
      await setProgress(_prefs!, l.title, s.progress);
      _recomputeDone(l.title);
      notifyListeners();
    }
  }

  Future<void> markAllCompleteForDebug(Lesson l) async {
    await _ensurePrefs();
    final s = _ensure(l.title);
    if (s.total > 0) {
      s.progress = s.total;
      s.done = true;
      await setProgress(_prefs!, l.title, s.progress);
      await setDone(_prefs!, l.title, true);
      notifyListeners();
    }
  }

  Future<void> resetAll() async {
    await _ensurePrefs();
    _prefs?.clear();
    _states.clear();
    notifyListeners();
  }

  // Internal helpers
  _LessonState _ensure(String title) =>
      _states.putIfAbsent(title, () => _LessonState());

  void _recomputeDone(String title) {
    final s = _ensure(title);
    if (s.total > 0 && s.progress >= s.total) {
      s.done = true;
      _prefs?.let((p) => setDone(p, title, true));
    }
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
}

class _LessonState {
  int progress = 0;
  int total = 0;
  bool done = false;
}

extension _Let<T> on T {
  R? let<R>(R Function(T) block) => block(this);
}
