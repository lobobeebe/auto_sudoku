import 'sudoku.dart';

class CandidateMap {
  final List<Set<int>> candidates;
  final bool usesProvidedNotes;
  CandidateMap._(this.candidates, this.usesProvidedNotes);
  bool get isNotesDriven => usesProvidedNotes;
  factory CandidateMap.fromBoard(Sudoku s) {
    final provided = s.notes;
    final cand = List.generate(81, (_) => <int>{});
    if (provided != null) {
      for (var i = 0; i < 81; i++) {
        if (s.cells[i] != 0) continue;
        final filtered = <int>{};
        for (final d in provided[i]) {
          if (d >= 1 && d <= 9 && s.isValidPlacement(i, d)) {
            filtered.add(d);
          }
        }
        cand[i] = filtered;
      }
      return CandidateMap._(cand, true);
    }
    for (var i = 0; i < 81; i++) {
      if (s.cells[i] == 0) {
        final ps = <int>{};
        for (var d = 1; d <= 9; d++) {
          if (s.isValidPlacement(i, d)) ps.add(d);
        }
        cand[i] = ps;
      }
    }
    return CandidateMap._(cand, false);
  }
  Set<int> operator [](int i) => candidates[i];
  void removeFromPeers(Sudoku s, int i, int val) {
    for (final p in s.peersOf(i)) {
      candidates[p].remove(val);
    }
  }
}
