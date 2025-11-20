import 'package:auto_sudoku_solver/data/tutorial.dart';
import 'package:auto_sudoku_solver/src/difficulty.dart';

// Model class for reading Sudoku Puzzles from data (new format)
// JSON shape:
// { "puzzle": String(81), "solution": String(81), "techniques": { name: count } }
class SudokuModel {
  final String puzzle;
  final String solution;
  final Map<String, int> techniqueCounts;
  final String id;
  final Tutorial? tutorial;

  SudokuModel({
    required this.puzzle,
    required this.solution,
    required this.techniqueCounts,
    String? id,
    this.tutorial,
  }) : id = id ?? _computeIdFromPuzzle(puzzle),
       assert(puzzle.length == 81),
       assert(solution.length == 81);

  factory SudokuModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawTech =
        (json['techniques'] as Map?)?.cast<String, dynamic>() ?? {};
    final counts = <String, int>{};
    rawTech.forEach((k, v) {
      final n = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
      counts[k] = n;
    });

    // Optional tutorial
    Tutorial? tutorial;
    const tutorialKey = 'tutorial';
    if (json.containsKey(tutorialKey)) {
      tutorial = Tutorial.fromJson(json[tutorialKey]);
    }

    return SudokuModel(
      puzzle: json['puzzle'] as String,
      solution: json['solution'] as String,
      techniqueCounts: counts,
      id:
          (json['id'] as String?) ??
          _computeIdFromPuzzle(json['puzzle'] as String),
      tutorial: tutorial,
    );
  }

  // Compute difficulty based on technique usage
  Difficulty get difficulty {
    // Singles only => Trivial
    // Any Pairs/Triples/Quads or Locked Candidates => Easy
    // Any X/XY/W-Wing => Medium
    bool has(String name) => (techniqueCounts[name] ?? 0) > 0;
    final singles = {'Naked Single', 'Hidden Single'};
    final setsOrLocked = {
      'Naked Pair',
      'Naked Triple',
      'Naked Quad',
      'Hidden Pair',
      'Hidden Triple',
      'Hidden Quad',
      'Locked Candidates (Pointing)',
      'Locked Candidates (Claiming)',
    };
    final wings = {'X-Wing', 'XY-Wing', 'W-Wing'};

    final keys = techniqueCounts.keys.toSet();
    final onlySingles = keys.isNotEmpty && keys.difference(singles).isEmpty;
    final usedSetsOrLocked = setsOrLocked.any(has);
    final usedWings = wings.any(has);

    if (usedWings) return Difficulty.medium;
    if (usedSetsOrLocked) return Difficulty.easy;
    if (onlySingles) return Difficulty.trivial;
    // Fallback: if empty or unknown techniques, classify as easy by default
    return Difficulty.easy;
  }

  Map<String, dynamic> toData() => {
    'id': id,
    'puzzle': puzzle,
    'solution': solution,
    'techniques': techniqueCounts,
    if (tutorial != null) 'tutorial': tutorial,
  };

  // Deterministic 6-char Base62 ID from puzzle string
  static String computeIdFromPuzzle(String puzzle) =>
      _computeIdFromPuzzle(puzzle);
  static String _computeIdFromPuzzle(String puzzle) {
    // FNV-1a 64-bit
    const int fnvOffset = 0xcbf29ce484222325; // 1469598103934665603
    const int fnvPrime = 0x100000001b3; // 1099511628211
    const int mask64 = 0xFFFFFFFFFFFFFFFF;
    int h = fnvOffset;
    for (final codeUnit in puzzle.codeUnits) {
      h ^= codeUnit & 0xFF;
      h = (h * fnvPrime) & mask64;
    }
    return _base62(h, 6);
  }

  static const String _alphabet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  static String _base62(int value, int len) {
    final base = _alphabet.length;
    final buf = List<String>.filled(len, '0');
    var v = value & 0x7FFFFFFFFFFFFFFF; // ensure non-negative
    for (int i = len - 1; i >= 0; i--) {
      buf[i] = _alphabet[v % base];
      v ~/= base;
    }
    return buf.join();
  }
}
