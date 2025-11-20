import 'dart:convert';
import 'dart:math';

import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PuzzleRepository extends ChangeNotifier {
  PuzzleRepository({this.assetPath = 'assets/puzzles/puzzles.json'});

  final String assetPath;
  final Random _random = Random();
  List<SudokuModel>? _cache;
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;
  Future<void>? _preloadFuture;

  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String? get error => _error;

  Future<void> preload() {
    if (_isLoaded) {
      return Future<void>.value();
    }
    _preloadFuture ??= _performPreload();
    return _preloadFuture!;
  }

  Future<SudokuModel> loadRandomPuzzle() async {
    if (!_isLoaded) {
      await preload();
    }
    final cache = _cache;
    if (cache == null || cache.isEmpty) {
      throw StateError('Puzzle repository is empty.');
    }
    return cache[_random.nextInt(cache.length)];
  }

  Future<SudokuModel> loadRandomPuzzleByDifficulty(
    Difficulty difficulty,
  ) async {
    if (!_isLoaded) {
      await preload();
    }
    final cache = _cache;
    if (cache == null || cache.isEmpty) {
      throw StateError('Puzzle repository is empty.');
    }
    final matching = cache.where((puzzle) => puzzle.difficulty == difficulty);
    final filtered = matching.toList(growable: false);
    if (filtered.isEmpty) {
      throw StateError('No puzzles available for ${difficulty.toString()}.');
    }
    return filtered[_random.nextInt(filtered.length)];
  }

  Future<List<SudokuModel>> loadPuzzlesByTechnique(
    String technique, {
    int limit = 10,
    bool onlyThisTechnique = false,
  }) async {
    if (!_isLoaded) {
      await preload();
    }
    final cache = _cache;
    if (cache == null || cache.isEmpty) {
      throw StateError('Puzzle repository is empty.');
    }
    final normalized = technique.trim();
    Iterable<SudokuModel> it = cache.where(
      (p) => (p.techniqueCounts[normalized] ?? 0) > 0,
    );
    if (onlyThisTechnique) {
      it = it.where(
        (p) => p.techniqueCounts.keys.every((k) => k == normalized),
      );
    }
    final filtered = it.take(limit).toList(growable: false);
    if (filtered.isEmpty) {
      throw StateError('No puzzles available for technique "$technique".');
    }
    return filtered;
  }

  Future<SudokuModel> loadRandomSinglesOnlyPuzzle() async {
    if (!_isLoaded) await preload();
    final cache = _cache;
    if (cache == null || cache.isEmpty) {
      throw StateError('Puzzle repository is empty.');
    }
    final singles = {'Naked Single', 'Hidden Single'};
    final candidates = cache
        .where((p) => p.techniqueCounts.keys.every(singles.contains))
        .toList();
    if (candidates.isEmpty) {
      throw StateError('No singles-only puzzles found.');
    }
    return candidates[_random.nextInt(candidates.length)];
  }

  Future<List<SudokuModel>> loadSinglesOnlyPuzzles({int limit = 20}) async {
    if (!_isLoaded) await preload();
    final cache = _cache;
    if (cache == null || cache.isEmpty) {
      throw StateError('Puzzle repository is empty.');
    }
    final singles = {'Naked Single', 'Hidden Single'};
    final list = cache
        .where(
          (p) =>
              p.techniqueCounts.isNotEmpty &&
              p.techniqueCounts.keys.every(singles.contains),
        )
        .take(limit)
        .toList(growable: false);
    if (list.isEmpty) {
      throw StateError('No singles-only puzzles found.');
    }
    return list;
  }

  Future<void> _performPreload() async {
    if (_isLoaded) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final raw = await rootBundle.loadString(assetPath);
      _cache = await compute(_parsePuzzles, raw);
      _isLoaded = true;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      if (!_isLoaded) {
        _preloadFuture = null;
      }
    }
  }

  // Load an arbitrary asset file that contains a JSON array of SudokuModel
  // entries (same shape as assets/puzzles/puzzles.json or lesson files).
  Future<List<SudokuModel>> loadAssetFile(String path) async {
    final raw = await rootBundle.loadString(path);
    return compute(_parsePuzzles, raw);
  }
}

List<SudokuModel> _parsePuzzles(String raw) {
  final List<dynamic> jsonList = json.decode(raw) as List<dynamic>;
  return jsonList
      .map((entry) => SudokuModel.fromJson(entry as Map<String, dynamic>))
      .toList(growable: false);
}
