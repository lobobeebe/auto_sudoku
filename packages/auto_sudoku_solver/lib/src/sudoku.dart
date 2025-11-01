class Sudoku {
  static const size = 9;
  static const box = 3;
  final List<int> cells; // length 81, 0 empty else 1..9
  final List<Set<int>>? notes; // optional per-cell candidate notes

  Sudoku(List<int> values, {List<Set<int>>? notes})
    : cells = List<int>.from(values),
      notes = notes == null ? null : _cloneNotes(_validateNotes(notes)) {
    if (cells.length != 81) throw ArgumentError('Grid must have 81 cells');
    if (this.notes != null && this.notes!.length != 81) {
      throw ArgumentError('Notes must have 81 entries');
    }
  }

  Sudoku.clone(Sudoku other)
    : cells = List<int>.from(other.cells),
      notes = other.notes == null ? null : _cloneNotes(other.notes!);

  int get rLen => size;
  int get cLen => size;
  int idx(int r, int c) => r * size + c;
  int rowOf(int i) => i ~/ size;
  int colOf(int i) => i % size;
  int boxOf(int i) {
    final r = rowOf(i), c = colOf(i);
    return (r ~/ box) * box + (c ~/ box);
  }

  Iterable<int> rowIndices(int r) sync* {
    for (var c = 0; c < size; c++) yield idx(r, c);
  }

  Iterable<int> colIndices(int c) sync* {
    for (var r = 0; r < size; r++) yield idx(r, c);
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

  bool isValidPlacement(int i, int val) {
    if (val == 0) return true;
    for (final p in peersOf(i)) {
      if (cells[p] == val) return false;
    }
    return true;
  }

  bool get isSolved => cells.every((v) => v != 0);

  Set<int>? notesAt(int i) => notes?[i];

  static List<Set<int>> _cloneNotes(List<Set<int>> source) =>
      List<Set<int>>.generate(
        source.length,
        (index) => Set<int>.from(source[index]),
      );

  static List<Set<int>> _validateNotes(List<Set<int>> notes) {
    if (notes.length != 81) {
      throw ArgumentError('Notes must have 81 entries');
    }
    for (var i = 0; i < notes.length; i++) {
      final set = notes[i];
      for (final d in set) {
        if (d < 1 || d > 9) {
          throw ArgumentError('Notes can only contain digits 1-9');
        }
      }
    }
    return notes;
  }
}
