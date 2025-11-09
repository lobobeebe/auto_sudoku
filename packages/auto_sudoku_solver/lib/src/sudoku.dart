import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

class Sudoku {
  static const size = 9;
  static const numIndices = size * size;
  static const box = 3;

  // 0 = empty; 1..9 = placed value
  final List<int> _values; // length 81
  // 9-bit candidate mask; bit d-1 set => note d present
  final List<int> _notesMask; // length 81

  /// Create a Sudoku from 81 values (row-major). 0 means empty.
  /// If [notes] is omitted, candidate masks are auto-computed.
  Sudoku(List<int> values, {List<Set<int>>? notes})
    : assert(values.length == numIndices, 'Grid must have $numIndices cells'),
      _values = List<int>.from(values),
      _notesMask = List<int>.filled(numIndices, 0) {
    if (notes != null) {
      if (notes.length != numIndices) {
        throw ArgumentError('Notes length must be $numIndices');
      }
      for (var i = 0; i < numIndices; i++) {
        var mask = 0;
        for (final d in notes[i]) {
          if (d < 1 || d > 9) {
            throw ArgumentError('Notes can only contain digits 1-9');
          }
          mask |= (1 << (d - 1));
        }
        _notesMask[i] = mask;
      }
    } else {
      _resetNotes();
    }
  }

  Sudoku._(this._values, this._notesMask);

  factory Sudoku.empty() => Sudoku(List.filled(81, 0));

  Sudoku clone() =>
      Sudoku._(List<int>.from(_values), List<int>.from(_notesMask));

  void overwrite(Sudoku other) {
    for (int i = 0; i < 81; ++i) {
      _values[i] = other._values[i];
      _notesMask[i] = other._notesMask[i];
    }
  }

  /// Apply a solver/teaching Hint to this Sudoku in-place.
  ///
  /// - Places digits from [hint.placements] (index -> digit),
  ///   clearing notes in that cell and removing that digit from all peers.
  /// - Removes candidates from [hint.eliminations] (index -> set of digits).
  ///
  /// Returns `true` if any change was applied; `false` if it was a no-op.
  /// Apply a solver/teaching Hint to this Sudoku in-place.
  /// Returns the list of cell indices that changed (value placed or notes removed).
  List<int> applyHint(Hint hint) {
    final changed = <int>{};

    // 1) Apply placements first
    if (hint.placements.isNotEmpty) {
      for (final entry in hint.placements.entries) {
        final i = entry.key;
        final d = entry.value;
        if (!isValidIndex(i)) continue;
        if (!isValidDigit(d)) continue;

        final beforeVal = valueAt(i);
        final beforeMask = notesMaskAt(i);

        if (isEmpty(i) && isValidPlacement(i, d)) {
          if (setValue(i, d)) {
            changed.add(i);
            // Clear peers' candidate d
            for (final p in peersOf(i)) {
              if (setNote(p, d, false)) changed.add(p);
            }
          }
        } else if (beforeVal == d && beforeMask != 0) {
          resetNotes(i);
          changed.add(i);
        }
      }
    }

    // 2) Apply candidate eliminations
    if (hint.eliminations.isNotEmpty) {
      for (final entry in hint.eliminations.entries) {
        final i = entry.key;
        if (!isValidIndex(i)) continue;
        if (!isEmpty(i)) continue;
        for (final d in entry.value) {
          if (!isValidDigit(d)) continue;
          if (setNote(i, d, false)) changed.add(i);
        }
      }
    }

    return changed.toList(growable: false);
  }

  // --- indexing helpers ---
  int get rLen => size;
  int get cLen => size;
  List<int> get grid => _values;
  int idx(int r, int c) => r * size + c;
  int rowOf(int i) => i ~/ size;
  int colOf(int i) => i % size;
  int boxOf(int i) {
    final r = rowOf(i), c = colOf(i);
    return (r ~/ box) * box + (c ~/ box);
  }

  // --- accessors ---
  int valueAt(int i) => _values[i];
  int notesMaskAt(int i) => _notesMask[i];
  bool isEmpty(int i) => _values[i] == 0;
  bool hasNote(int i, int d) {
    if (!isValidIndex(i) || !isValidDigit(d)) return false;
    return (_notesMask[i] & (1 << (d - 1))) != 0;
  }

  /// Returns the number of active notes (bits set to 1) for cell [i].
  int numNotesAt(int i) {
    var m = _notesMask[i], c = 0;
    while (m != 0) {
      m &= (m - 1); // clear least significant set bit
      c++;
    }
    return c;
  }

  // --- mutations ---
  bool setValue(int i, int v) {
    if (v < 0 || v > 9) {
      throw ArgumentError('Value must be 0..9 (0 = empty)');
    }
    if (_values[i] == v) return false;

    _values[i] = v;
    if (v != 0) _notesMask[i] = 0; // placing a value clears notes
    return true;
  }

  void resetValue(int i) {
    _values[i] = 0;
  }

  void resetNotes(int i) {
    _notesMask[i] = 0;
  }

  /// Set or clear a note digit [d] (1..9) for cell [i].
  bool setNote(int i, int d, bool on) {
    if (d < 1 || d > 9) {
      throw ArgumentError('Notes can only contain digits 1-9');
    }
    final bit = 1 << (d - 1);
    final next = on ? (_notesMask[i] | bit) : (_notesMask[i] & ~bit);
    if (next == _notesMask[i]) return false;
    _notesMask[i] = next;
    return true;
  }

  Set<int> notesSet(int i) {
    final result = <int>{};
    var mask = _notesMask[i];
    for (var d = 1; d <= size; d++) {
      if ((mask & (1 << (d - 1))) != 0) {
        result.add(d);
      }
    }
    return result;
  }

  // --- iteration helpers ---
  Iterable<int> rowIndices(int r) sync* {
    for (var c = 0; c < size; c++) {
      yield idx(r, c);
    }
  }

  Iterable<int> colIndices(int c) sync* {
    for (var r = 0; r < size; r++) {
      yield idx(r, c);
    }
  }

  Iterable<int> boxIndices(int b) sync* {
    final br = (b ~/ box) * box;
    final bc = (b % box) * box;
    for (var dr = 0; dr < box; dr++) {
      for (var dc = 0; dc < box; dc++) {
        yield idx(br + dr, bc + dc);
      }
    }
  }

  Set<int> peersOf(int i) {
    final r = rowOf(i), c = colOf(i), b = boxOf(i);
    final peers = <int>{};
    peers.addAll(rowIndices(r));
    peers.addAll(colIndices(c));
    peers.addAll(boxIndices(b));
    peers.remove(i);
    return peers;
  }

  /// Remove candidate [val] from all peers of cell [i].
  List<int> removeFromPeers(int i, int val) {
    List<int> mutatedIndices = [];

    for (final p in peersOf(i)) {
      if (setNote(p, val, false)) {
        mutatedIndices.add(p);
      }
    }

    return mutatedIndices;
  }

  bool isValidPlacement(int i, int val) {
    if (val == 0) return true;
    for (final p in peersOf(i)) {
      if (_values[p] == val) return false;
    }
    return true;
  }

  bool get isSolved => isGridSolved(_values);

  bool get hasEmptyGrids => _values.any((value) => value == 0);

  List<int> bivalIndices() {
    final bivals = <int>[];
    for (var i = 0; i < numIndices; i++) {
      if (isEmpty(i) && numNotesAt(i) == 2) bivals.add(i);
    }
    return bivals;
  }

  void _resetNotes() {
    for (var i = 0; i < numIndices; i++) {
      if (_values[i] != 0) {
        _notesMask[i] = 0;
        continue;
      }
      var mask = 0;
      for (var d = 1; d <= size; ++d) {
        if (isValidPlacement(i, d)) {
          mask |= (1 << (d - 1));
        }
      }
      _notesMask[i] = mask;
    }
  }

  bool equals(Sudoku other) => gridEquals(_values, other._values);

  static bool gridEquals(List<int> lhs, List<int> rhs) {
    if (identical(lhs, rhs)) return true;
    if (lhs.length != rhs.length) return false;
    for (var i = 0; i < lhs.length; i++) {
      if (lhs[i] != rhs[i]) return false;
    }
    return true;
  }

  static bool isGridSolved(List<int> grid) => grid.every((v) => v != 0);

  static bool isValidIndex(int index) => index >= 0 && index <= numIndices;
  static bool isValidDigit(int digit) => digit >= 1 && digit <= 9;
}
