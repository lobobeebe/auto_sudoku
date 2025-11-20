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

  static const easyStrategies = Lesson(
    title: 'Easy Strategies',
    icon: Icons.school_rounded,
    shortDesc: "Reward: Easy Difficulty Free Play",
    description:
        'Overview of easy strategies including Open/Hidden Singles, Open/Hidden Sets, and Locked Candidates. Complete to unlock practice lessons.',
    path: "assets/puzzles/lessons/easy_strategies.json",
    preReqLesson: 'The Basics',
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
    Lesson(
      title: 'Open Sets',
      icon: Icons.looks_two_rounded,
      shortDesc: "Reward: Open Set Auto-Complete",
      description:
          'Complete these puzzles using only the Open Set strategy to unlock auto-completing of Open Sets.',
      path: "assets/puzzles/lessons/open_sets.json",
      preReqLesson: easyStrategies.title,
    ),
    Lesson(
      title: 'Hidden Sets',
      icon: Icons.filter_2_rounded,
      shortDesc: "Reward: Hidden Set Auto-Complete",
      description:
          'Complete these puzzles using only the Hidden Set strategy to unlock auto-completing of Hidden Sets.',
      path: "assets/puzzles/lessons/hidden_sets.json",
      preReqLesson: easyStrategies.title,
    ),
    Lesson(
      title: 'Locked Candidates',
      icon: Icons.lock_rounded,
      shortDesc: "Reward: Locked Candidates Auto-Complete",
      description:
          'Complete these puzzles using only the Locked Candidates strategy to unlock auto-completing of Locked Candidates.',
      path: "assets/puzzles/lessons/locked_candidates.json",
      preReqLesson: easyStrategies.title,
    ),
  ];
}
