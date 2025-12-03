import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:shared_preferences/shared_preferences.dart';

int getProgress(SharedPreferences prefs, StrategyType type) {
  String key = "${_slug(type)}_progress";
  if (prefs.containsKey(key)) {
    final progress = prefs.get(key);
    if (progress is int) {
      return progress;
    }
  }

  return 0;
}

Future<bool> setProgress(
  SharedPreferences prefs,
  StrategyType type,
  int progress,
) async {
  String key = "${_slug(type)}_progress";
  return prefs.setInt(key, progress);
}

bool getDone(SharedPreferences prefs, StrategyType type) {
  String key = "${_slug(type)}_done";
  if (prefs.containsKey(key)) {
    final done = prefs.get(key);
    if (done is bool) {
      return done;
    }
  }

  return false;
}

Future<bool> setDone(SharedPreferences prefs, StrategyType type, bool done) {
  String key = "${_slug(type)}_done";
  return prefs.setBool(key, done);
}

String _slug(StrategyType type) => type.name
    .toLowerCase()
    .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
    .replaceAll(RegExp(r"_+"), '_')
    .replaceAll(RegExp(r"^_+|_+$"), '');
