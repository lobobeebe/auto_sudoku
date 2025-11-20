import 'package:auto_sudoku/data/lesson.dart';
import 'package:flutter/material.dart';

class Lessons {
  static const theBasics = Lesson(
    title: 'The Basics',
    icon: Icons.grid_on_rounded,
    shortDesc: "Reward: Free Play",
    description:
        'Learn the fundamentals of Sudoku and the basic strategies to solve them.',
    path: "assets/puzzles/lessons/the_basics.json",
  );

  static List<Lesson> get all => [
    theBasics,
    Lesson(
      title: 'Hidden Singles',
      icon: Icons.filter_1_rounded,
      shortDesc: "Reward: Hidden Single Auto-Complete",
      description:
          'Complete these puzzles using only the Hidden Single strategy to unlock auto-completing of Hidden Singles.',
      path: "assets/puzzles/lessons/hidden_singles.json",
      preReqLesson: theBasics.title,
      showNotes: false,
    ),
    Lesson(
      title: 'Open Singles',
      icon: Icons.looks_one_rounded,
      shortDesc: "Reward: Open Single Auto-Complete",
      description:
          'Complete these puzzles using only the Open Single strategy to unlock auto-completing of Open Singles.',
      path: "assets/puzzles/lessons/open_singles.json",
      preReqLesson: theBasics.title,
    ),
  ];
}
