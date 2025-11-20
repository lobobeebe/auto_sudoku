import 'package:flutter/material.dart';

class Lesson {
  final String title;
  final String shortDesc;
  final String description;
  final IconData icon;
  final String path;
  final String? preReqPrefKey;

  const Lesson({
    required this.title,
    required this.icon,
    required this.shortDesc,
    required this.description,
    required this.path,
    this.preReqPrefKey,
  });
}
