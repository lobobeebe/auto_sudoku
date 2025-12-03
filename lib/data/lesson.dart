import 'package:flutter/material.dart';

class PuzzleLesson {
  final String path;

  const PuzzleLesson({required this.path});
}

class Lesson {
  final String title;
  final String shortDesc;
  final String description;
  final IconData icon;
  final String path;
  final bool? showNotes;
  final String? preReqLesson;

  const Lesson({
    required this.title,
    required this.icon,
    required this.shortDesc,
    required this.description,
    required this.path,
    this.showNotes,
    this.preReqLesson,
  });
}
