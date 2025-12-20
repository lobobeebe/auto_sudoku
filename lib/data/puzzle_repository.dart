import 'dart:convert';
import 'dart:math';

import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PuzzleRepository extends ChangeNotifier {
  PuzzleRepository({this.assetPath = 'assets/puzzles/'});

  final String assetPath;
  final Random _random = Random();
  List<SudokuModel>? _cache;
  Map<String, SudokuModel>? _cacheById;
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
    final singles = {'Open Single', 'Hidden Single'};
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
    final singles = {'Open Single', 'Hidden Single'};
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

  Future<SudokuModel> loadPuzzleById(String id) async {
    if (!_isLoaded) {
      await preload();
    }
    final cacheById = _cacheById;
    if (cacheById == null || cacheById.isEmpty) {
      throw StateError('Puzzle repository is empty.');
    }
    final puzzle = cacheById[id];
    if (puzzle == null) {
      throw StateError('Puzzle with id "$id" not found.');
    }
    return puzzle;
  }

  Future<void> _performPreload() async {
    if (_isLoaded) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final puzzles = await _loadPuzzlesFromAsset(assetPath);
      _cache = puzzles;
      _cacheById = {
        for (final puzzle in puzzles) puzzle.id: puzzle,
      };
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

  // Load an arbitrary asset file that resolves to SudokuModel entries.
  Future<List<SudokuModel>> loadAssetFile(String path) async {
    return _loadPuzzlesFromAsset(path);
  }

  Future<List<SudokuModel>> _loadPuzzlesFromAsset(String path) async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final manifest = json.decode(manifestContent);
    if (manifest is! Map<String, dynamic>) {
      throw const FormatException('Invalid asset manifest');
    }
    final normalizedPath = path.endsWith('/') ? path : '$path/';
    final isExactFile = manifest.containsKey(path);
    final candidates = isExactFile
        ? <String>[path]
        : manifest.keys
              .where(
                (asset) =>
                    asset.startsWith(normalizedPath) && asset.endsWith('.json'),
              )
              .toList(growable: false);
    if (candidates.isEmpty) {
      throw FormatException('No puzzles found under $path');
    }
    candidates.sort();
    final rawEntries = await Future.wait(
      candidates.map((puzzlePath) => rootBundle.loadString(puzzlePath)),
    );
    final parsed = await compute(_parsePuzzleAssets, rawEntries);
    if (parsed.isEmpty) {
      throw FormatException('No puzzles found under $path');
    }
    return parsed;
  }
}

List<SudokuModel> _parsePuzzleAssets(List<String> rawEntries) {
  final puzzles = <SudokuModel>[];
  for (final raw in rawEntries) {
    final decoded = json.decode(raw);
    if (decoded is Map<String, dynamic>) {
      puzzles.add(SudokuModel.fromJson(decoded));
      continue;
    }
    if (decoded is List) {
      if (decoded.isEmpty) continue;
      final first = decoded.first;
      if (first is Map<String, dynamic>) {
        puzzles.addAll(
          decoded
              .cast<Map<String, dynamic>>()
              .map(SudokuModel.fromJson)
              .toList(growable: false),
        );
      }
    }
  }
  return puzzles.toList(growable: false);
}
