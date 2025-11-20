import 'package:shared_preferences/shared_preferences.dart';

int getProgress(SharedPreferences prefs, String lessonTitle) {
  String key = "${_slug(lessonTitle)}_progress";
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
  String lessonTitle,
  int progress,
) async {
  String key = "${_slug(lessonTitle)}_progress";
  return prefs.setInt(key, progress);
}

bool getDone(SharedPreferences prefs, String lessonTitle) {
  String key = "${_slug(lessonTitle)}_done";
  if (prefs.containsKey(key)) {
    final done = prefs.get(key);
    if (done is bool) {
      return done;
    }
  }

  return false;
}

Future<bool> setDone(SharedPreferences prefs, String lessonTitle, bool done) {
  String key = "${_slug(lessonTitle)}_done";
  return prefs.setBool(key, done);
}

String _slug(String input) => input
    .toLowerCase()
    .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
    .replaceAll(RegExp(r"_+"), '_')
    .replaceAll(RegExp(r"^_+|_+$"), '');
