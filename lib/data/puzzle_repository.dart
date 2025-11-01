import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:auto_sudoku/data/sudoku_puzzle.dart';

class PuzzleRepository {
  PuzzleRepository({this.assetPath = 'assets/puzzles/puzzles.json'});

  final String assetPath;
  List<SudokuPuzzle>? _cache;
  final Random _random = Random();

  Future<SudokuPuzzle> loadRandomPuzzle() async {
    if (_cache == null) {
      final raw = await rootBundle.loadString(assetPath);
      final List<dynamic> jsonList = json.decode(raw) as List<dynamic>;
      final puzzles = jsonList
          .map((entry) => SudokuPuzzle.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false);
      _cache = puzzles;
    }
    return _cache![_random.nextInt(_cache!.length)];
  }
}
