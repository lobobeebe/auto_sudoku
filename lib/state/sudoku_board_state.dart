import 'dart:async';
import 'dart:collection';

import 'package:auto_sudoku/data/puzzle_repository.dart';
import 'package:auto_sudoku/data/sudoku_puzzle.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart' as solver;
import 'package:flutter/foundation.dart';

enum GameStatus { playing, won, lost }

enum CellColoring { none, colorA, colorB }

enum ColoringBrush { colorA, colorB, eraser }

class SudokuCell {
  final int? value;
  final Set<int> notes;
  final bool isGiven;
  final CellColoring coloring;

  SudokuCell({
    this.value,
    Set<int>? notes,
    this.isGiven = false,
    this.coloring = CellColoring.none,
  }) : notes = notes != null ? Set<int>.from(notes) : <int>{};

  SudokuCell withValue(int? newValue) => SudokuCell(
    value: newValue,
    notes: const <int>{},
    isGiven: isGiven,
    coloring: coloring,
  );

  SudokuCell withNotes(Set<int> newNotes) => SudokuCell(
    value: value,
    notes: newNotes,
    isGiven: isGiven,
    coloring: coloring,
  );

  SudokuCell withColoring(CellColoring newColoring) => SudokuCell(
    value: value,
    notes: notes,
    isGiven: isGiven,
    coloring: newColoring,
  );
}

class SudokuBoardState extends ChangeNotifier {
  static const int size = 9;

  final List<SudokuCell> _cells = List.generate(
    size * size,
    (_) => SudokuCell(),
  );
  SudokuPuzzle? _currentPuzzle;
  int? _selectedIndex;
  bool _noteMode = false;
  bool _colorMode = false;
  ColoringBrush _coloringBrush = ColoringBrush.colorA;
  Set<int>? _colorAPeersCache;
  Set<int>? _colorBPeersCache;
  bool _linksMode = false;
  int? _linksDigit;
  int? _linkStartIndex;
  final List<LinkSegment> _linkSegments = <LinkSegment>[];

  bool _isAnimatingSingles = false;
  bool _pendingAutoSingles = false;
  int? _autoFillHighlightIndex;
  final Duration _autoFillStepDelay = const Duration(milliseconds: 160);
  final List<_BoardSnapshot> _history = <_BoardSnapshot>[];
  bool _isDisposed = false;

  bool _isLoading = true;
  String? _error;
  solver.Hint? _hint;
  GameStatus _status = GameStatus.playing;
  PuzzleRepository repo;

  SudokuBoardState({required this.repo});

  void _emitChange() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  SudokuPuzzle? get currentPuzzle => _currentPuzzle;
  int? get selectedIndex => _selectedIndex;
  int? get selectedRow =>
      _selectedIndex != null ? _selectedIndex! ~/ size : null;
  int? get selectedCol =>
      _selectedIndex != null ? _selectedIndex! % size : null;
  int? get selectedValue =>
      _selectedIndex != null ? _cells[_selectedIndex!].value : null;
  bool get noteMode => _noteMode;
  bool get coloringMode => _colorMode;
  ColoringBrush get coloringBrush => _coloringBrush;
  bool get hasColoringMarks =>
      _cells.any((cell) => cell.coloring != CellColoring.none);
  Set<int> get colorAPeerIndices =>
      _colorAPeersCache ??= _collectColorPeers(CellColoring.colorA);
  Set<int> get colorBPeerIndices =>
      _colorBPeersCache ??= _collectColorPeers(CellColoring.colorB);
  Set<int> get colorMixedPeerIndices {
    final mixed = <int>{};
    final aPeers = colorAPeerIndices;
    final bPeers = colorBPeerIndices;
    for (final index in aPeers) {
      if (bPeers.contains(index)) {
        mixed.add(index);
      }
    }
    return mixed;
  }

  bool get linksMode => _linksMode;
  int? get linksDigit => _linksDigit;
  int? get linkStartIndex => _linkStartIndex;
  List<LinkSegment> get linkSegments =>
      List<LinkSegment>.unmodifiable(_linkSegments);
  bool get isAnimatingSingles => _isAnimatingSingles;
  int? get autoFillHighlightIndex => _autoFillHighlightIndex;
  bool get canUndo => _history.isNotEmpty;
  GameStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;
  solver.Hint? get hint => _hint;
  String get difficulty => _currentPuzzle?.difficulty.toString() ?? 'Unknown';
  List<String> get techniques => _currentPuzzle?.techniques ?? const [];

  /// Returns the current board values as a flat list with zero for blanks.
  List<int> toValueList() =>
      List<int>.generate(_cells.length, (index) => _cells[index].value ?? 0);

  /// Returns a deep copy of the current cell notes for each position.
  List<Set<int>> toNotesList() => List<Set<int>>.generate(
    _cells.length,
    (index) => Set<int>.from(_cells[index].notes),
  );

  void setHint(solver.Hint? hint) {
    _hint = hint;
    _emitChange();
  }

  bool applyCurrentHint() {
    final currentHint = _hint;
    if (currentHint == null || _isAnimatingSingles) {
      return false;
    }
    final snapshot = _makeSnapshot();
    final mutated = _applyHintToBoard(
      currentHint,
      triggerAutomation: true,
      emitChange: true,
    );
    if (!mutated) {
      return false;
    }
    _history.add(snapshot);
    _hint = null;
    return true;
  }

  bool canPlaceDigit(int digit) {
    final idx = _selectedIndex;
    if (idx == null || digit < 1 || digit > size) {
      return true;
    }
    final cell = _cells[idx];
    if (cell.isGiven) {
      return false;
    }
    if (cell.value == digit) {
      return true;
    }
    final row = idx ~/ size;
    final col = idx % size;
    for (var c = 0; c < size; c++) {
      if (c == col) continue;
      if (_cells[_index(row, c)].value == digit) {
        return false;
      }
    }
    for (var r = 0; r < size; r++) {
      if (r == row) continue;
      if (_cells[_index(r, col)].value == digit) {
        return false;
      }
    }
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (var r = startRow; r < startRow + 3; r++) {
      for (var c = startCol; c < startCol + 3; c++) {
        final index = _index(r, c);
        if (index == idx) continue;
        if (_cells[index].value == digit) {
          return false;
        }
      }
    }
    return true;
  }

  bool isDigitSolved(int digit) {
    if (digit < 1 || digit > size) {
      return false;
    }
    var count = 0;
    for (final cell in _cells) {
      if (cell.value == digit) {
        count++;
      }
    }
    return count >= size;
  }

  SudokuCell cellAt(int row, int col) => _cells[_index(row, col)];

  Future<void> init({solver.Difficulty? difficulty}) async {
    _isLoading = true;
    _error = null;
    _emitChange();

    try {
      final puzzle = difficulty == null
          ? await repo.loadRandomPuzzle()
          : await repo.loadRandomPuzzleByDifficulty(difficulty);
      _initFromPuzzle(puzzle);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _emitChange();
    }
  }

  void _initFromPuzzle(SudokuPuzzle puzzle) {
    clearHint();
    _currentPuzzle = puzzle;
    _selectedIndex = null;
    _noteMode = false;
    _colorMode = false;
    _coloringBrush = ColoringBrush.colorA;
    _linksMode = false;
    _linksDigit = null;
    _linkStartIndex = null;
    _linkSegments.clear();
    _isAnimatingSingles = false;
    _pendingAutoSingles = false;
    _autoFillHighlightIndex = null;
    _history.clear();
    _status = GameStatus.playing;

    for (var index = 0; index < _cells.length; index++) {
      final char = puzzle.puzzle[index];
      final parsed = int.tryParse(char);
      final value = parsed == null || parsed == 0 ? null : parsed;
      _cells[index] = value != null
          ? SudokuCell(value: value, notes: const <int>{}, isGiven: true)
          : SudokuCell();
    }

    _invalidateColoringCaches();
    fillAllNotes(notify: false);
    _emitChange();
    _scheduleAutoSingles();
  }

  void toggleNoteMode() {
    if (_isAnimatingSingles) {
      return;
    }

    _noteMode = !_noteMode;
    if (_noteMode && _colorMode) {
      _colorMode = false;
    }
    if (_noteMode && _linksMode) {
      _linksMode = false;
      _clearLinks(resetDigit: true);
    }
    _emitChange();
  }

  void toggleColorMode() {
    if (_isAnimatingSingles) {
      return;
    }
    _colorMode = !_colorMode;
    if (_colorMode && _noteMode) {
      _noteMode = false;
    }
    if (_colorMode && _linksMode) {
      _linksMode = false;
      _clearLinks(resetDigit: true);
    }
    _emitChange();
  }

  void toggleLinksMode() {
    if (_isAnimatingSingles) {
      return;
    }
    _linksMode = !_linksMode;
    if (_linksMode) {
      if (_noteMode) _noteMode = false;
      if (_colorMode) _colorMode = false;
      if (_selectedIndex != null && _linksDigit != null) {
        _updateLinkSegmentsFrom(_selectedIndex!);
      }
    } else {
      _clearLinks(resetDigit: true);
    }
    _emitChange();
  }

  void setLinksDigit(int digit) {
    if (digit < 1 || digit > 9) {
      return;
    }
    if (_linksDigit == digit) {
      _linksDigit = null;
      _clearLinks(resetDigit: false);
      _emitChange();
      return;
    }
    _linksDigit = digit;
    if (_linksMode && _selectedIndex != null) {
      _updateLinkSegmentsFrom(_selectedIndex!);
    } else {
      _clearLinks(resetDigit: false);
    }
    _emitChange();
  }

  void clearLinks() {
    _clearLinks(resetDigit: false);
    _emitChange();
  }

  bool isColorPeer(CellColoring color, int index) {
    switch (color) {
      case CellColoring.colorA:
        return colorAPeerIndices.contains(index);
      case CellColoring.colorB:
        return colorBPeerIndices.contains(index);
      case CellColoring.none:
        return false;
    }
  }

  void setColoringBrush(ColoringBrush brush) {
    if (_coloringBrush == brush) {
      return;
    }
    _coloringBrush = brush;
    _emitChange();
  }

  void clearColoringMarks() {
    if (_isAnimatingSingles) {
      return;
    }
    var hasChange = false;
    for (var i = 0; i < _cells.length; i++) {
      final cell = _cells[i];
      if (cell.coloring == CellColoring.none) {
        continue;
      }
      if (!hasChange) {
        _pushSnapshot();
        hasChange = true;
      }
      _cells[i] = cell.withColoring(CellColoring.none);
    }
    if (hasChange) {
      _invalidateColoringCaches();
      _emitChange();
    }
  }

  void deselectCell() {
    _selectedIndex = null;
    if (_linksMode) {
      _clearLinks(resetDigit: false);
    }
    _emitChange();
  }

  void selectCell(int row, int col) {
    if (_isAnimatingSingles) {
      return;
    }
    final index = _index(row, col);

    if (_linksMode) {
      if (_selectedIndex == index) {
        _selectedIndex = null;
        _clearLinks(resetDigit: false);
      } else {
        _selectedIndex = index;
        _updateLinkSegmentsFrom(index);
      }
      _emitChange();
      return;
    }

    if (_colorMode) {
      final cell = _cells[index];
      final currentColoring = cell.coloring;
      final targetColoring = switch (_coloringBrush) {
        ColoringBrush.colorA => CellColoring.colorA,
        ColoringBrush.colorB => CellColoring.colorB,
        ColoringBrush.eraser => CellColoring.none,
      };

      CellColoring nextColoring;
      if (_coloringBrush == ColoringBrush.eraser) {
        if (currentColoring == CellColoring.none) {
          _selectedIndex = index;
          _emitChange();
          return;
        }
        nextColoring = CellColoring.none;
      } else if (currentColoring == targetColoring) {
        nextColoring = CellColoring.none;
      } else {
        nextColoring = targetColoring;
      }

      if (nextColoring != currentColoring) {
        _pushSnapshot();
        _cells[index] = cell.withColoring(nextColoring);
        _invalidateColoringCaches();
      }
      _selectedIndex = index;
      _emitChange();
      return;
    }

    if (_selectedIndex == index) {
      _selectedIndex = null;
    } else {
      _selectedIndex = index;
    }
    _emitChange();
  }

  bool enterDigit(int digit) {
    if (_isAnimatingSingles) {
      return false;
    }
    final idx = _selectedIndex;
    if (idx == null || digit < 1 || digit > 9) {
      return false;
    }
    final cell = _cells[idx];
    if (cell.isGiven) {
      return false;
    }

    if (_noteMode) {
      if (cell.value != null) {
        return false;
      }
      final updatedNotes = {...cell.notes};
      if (updatedNotes.contains(digit)) {
        updatedNotes.remove(digit);
      } else {
        updatedNotes.add(digit);
      }
      final wasChanged = !_setsEqual(updatedNotes, cell.notes);
      if (!wasChanged) {
        return false;
      }
      clearHint();
      _pushSnapshot();
      _cells[idx] = cell.withNotes(updatedNotes);
      _status = GameStatus.playing;
      _scheduleAutoSingles();
      _emitChange();
      return true;
    }

    clearHint();
    _pushSnapshot();
    if (cell.value == digit) {
      _cells[idx] = SudokuCell(
        value: null,
        notes: const <int>{},
        isGiven: cell.isGiven,
        coloring: cell.coloring,
      );
      _restoreNotesAround(idx, digit);
      final row = idx ~/ size;
      final col = idx % size;
      final candidates = _candidatesFor(row, col);
      _cells[idx] = _cells[idx].withNotes(candidates);
      _status = GameStatus.playing;
      _scheduleAutoSingles();
      _emitChange();
      return true;
    }

    final solutionDigit = _currentPuzzle != null
        ? int.tryParse(_currentPuzzle!.solution[idx])
        : null;

    _cells[idx] = cell.withValue(digit);

    if (solutionDigit != null && solutionDigit != digit) {
      _status = GameStatus.lost;
      _pendingAutoSingles = false;
      _autoFillHighlightIndex = null;
      _emitChange();
      return true;
    }

    _status = GameStatus.playing;
    _pruneNotesAround(idx, digit);
    _scheduleAutoSingles();
    _evaluateCompletion();
    if (_linksMode) {
      if (_linksDigit != null && _selectedIndex != null) {
        _updateLinkSegmentsFrom(_selectedIndex!);
      } else {
        _clearLinks(resetDigit: false);
      }
    }
    _emitChange();
    return true;
  }

  bool fillAllNotes({bool notify = true}) {
    var changed = false;
    for (var index = 0; index < _cells.length; index++) {
      final cell = _cells[index];
      if (cell.value != null) {
        if (cell.notes.isNotEmpty) {
          _cells[index] = cell.withNotes(const <int>{});
          changed = true;
        }
        continue;
      }

      final row = index ~/ size;
      final col = index % size;
      final candidates = _candidatesFor(row, col);
      if (_setsEqual(cell.notes, candidates)) {
        continue;
      }
      _cells[index] = cell.withNotes(candidates);
      changed = true;
    }
    if (changed && notify) {
      _emitChange();
    }
    return changed;
  }

  void _scheduleAutoSingles() {
    if (_isAnimatingSingles) {
      _pendingAutoSingles = true;
      return;
    }
    final nextSingle = _findNextSingle();
    if (nextSingle == null) {
      _pendingAutoSingles = false;
      final previousStatus = _status;
      _evaluateCompletion();
      if (_status != previousStatus) {
        _emitChange();
      }
      return;
    }
    _pendingAutoSingles = false;
    unawaited(_runAutoSingles(nextSingle));
  }

  Future<void> _runAutoSingles(MapEntry<int, int> initialSingle) async {
    if (_isAnimatingSingles) {
      _pendingAutoSingles = true;
      return;
    }

    clearHint();
    _isAnimatingSingles = true;
    _emitChange();

    MapEntry<int, int>? current = initialSingle;
    while (current != null) {
      final index = current.key;
      final value = current.value;
      final cell = _cells[index];

      if (cell.value == null && !cell.isGiven) {
        _cells[index] = cell.withValue(value);
        _pruneNotesAround(index, value);
        _autoFillHighlightIndex = index;
        _emitChange();
      }

      await Future.delayed(_autoFillStepDelay);
      current = _findNextSingle();
    }

    _evaluateCompletion();
    _autoFillHighlightIndex = null;
    _isAnimatingSingles = false;
    if (_linksMode) {
      if (_linksDigit != null && _selectedIndex != null) {
        _updateLinkSegmentsFrom(_selectedIndex!);
      } else {
        _clearLinks(resetDigit: false);
      }
    }
    _emitChange();

    if (_pendingAutoSingles) {
      _pendingAutoSingles = false;
      _scheduleAutoSingles();
    }
  }

  MapEntry<int, int>? _findNextSingle() {
    MapEntry<int, int>? best;
    final candidatesCache = <int, Set<int>>{};

    Set<int> candidatesForIndex(int index) {
      final cached = candidatesCache[index];
      if (cached != null) {
        return cached;
      }
      final cell = _cells[index];
      if (cell.notes.isNotEmpty) {
        final notes = <int>{...cell.notes};
        candidatesCache[index] = notes;
        return notes;
      }
      final row = index ~/ size;
      final col = index % size;
      final computed = _candidatesFor(row, col);
      candidatesCache[index] = computed;
      return computed;
    }

    for (var index = 0; index < _cells.length; index++) {
      final cell = _cells[index];
      if (cell.value != null) {
        continue;
      }
      final candidates = candidatesForIndex(index);
      if (candidates.length == 1) {
        final value = candidates.first;
        if (best == null || index < best.key) {
          best = MapEntry(index, value);
        }
      }
    }

    if (best != null) {
      return best;
    }

    MapEntry<int, int>? hiddenBest;

    void inspect(List<int> indices) {
      final counts = <int, int>{};
      final locations = <int, int>{};
      for (final index in indices) {
        final cell = _cells[index];
        if (cell.value != null) {
          continue;
        }
        final candidates = candidatesForIndex(index);
        for (final candidate in candidates) {
          counts[candidate] = (counts[candidate] ?? 0) + 1;
          locations[candidate] = index;
        }
      }
      for (final entry in counts.entries) {
        if (entry.value == 1) {
          final index = locations[entry.key]!;
          if (hiddenBest == null || index < hiddenBest!.key) {
            hiddenBest = MapEntry(index, entry.key);
          }
        }
      }
    }

    for (var row = 0; row < size; row++) {
      inspect([for (var col = 0; col < size; col++) _index(row, col)]);
    }

    for (var col = 0; col < size; col++) {
      inspect([for (var row = 0; row < size; row++) _index(row, col)]);
    }

    for (var boxRow = 0; boxRow < size; boxRow += 3) {
      for (var boxCol = 0; boxCol < size; boxCol += 3) {
        final indices = <int>[];
        for (var r = boxRow; r < boxRow + 3; r++) {
          for (var c = boxCol; c < boxCol + 3; c++) {
            indices.add(_index(r, c));
          }
        }
        inspect(indices);
      }
    }

    return hiddenBest;
  }

  void _invalidateColoringCaches() {
    _colorAPeersCache = null;
    _colorBPeersCache = null;
  }

  void _clearLinks({bool resetDigit = false}) {
    _linkSegments.clear();
    _linkStartIndex = null;
    if (resetDigit) {
      _linksDigit = null;
    }
  }

  Set<int> digitsAvailableForLinks() {
    final sets = _buildCandidateSets();
    final digits = <int>{};
    for (final set in sets) {
      digits.addAll(set);
    }
    return digits;
  }

  List<Set<int>> _buildCandidateSets() {
    final notesList = toNotesList();
    final hasAnyNotes = notesList.any((set) => set.isNotEmpty);
    return List<Set<int>>.generate(_cells.length, (index) {
      final cell = _cells[index];
      if (cell.value != null) {
        return <int>{};
      }
      if (hasAnyNotes && notesList[index].isNotEmpty) {
        return _filterNotes(index, notesList[index]);
      }
      if (!hasAnyNotes) {
        final row = index ~/ size;
        final col = index % size;
        return _candidatesFor(row, col);
      }
      return <int>{};
    });
  }

  Set<int> _filterNotes(int index, Set<int> notes) {
    final valid = <int>{};
    for (final digit in notes) {
      if (_isPlacementValid(index, digit)) {
        valid.add(digit);
      }
    }
    return valid;
  }

  bool _isPlacementValid(int index, int digit) {
    if (digit < 1 || digit > size) {
      return false;
    }
    final row = index ~/ size;
    final col = index % size;
    for (var c = 0; c < size; c++) {
      if (c == col) continue;
      if (_cells[_index(row, c)].value == digit) {
        return false;
      }
    }
    for (var r = 0; r < size; r++) {
      if (r == row) continue;
      if (_cells[_index(r, col)].value == digit) {
        return false;
      }
    }
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (var r = startRow; r < startRow + 3; r++) {
      for (var c = startCol; c < startCol + 3; c++) {
        final idx = _index(r, c);
        if (idx == index) continue;
        if (_cells[idx].value == digit) {
          return false;
        }
      }
    }
    return true;
  }

  void _updateLinkSegmentsFrom(int index) {
    if (!_linksMode) {
      return;
    }
    _linkStartIndex = index;
    final digit = _linksDigit;
    final candidateSets = _buildCandidateSets();
    if (digit == null || !candidateSets[index].contains(digit)) {
      _linkSegments.clear();
      return;
    }

    final graph = _buildStrongLinkGraph(digit, candidateSets);
    final visited = <int>{index};
    final queue = Queue<(int, bool)>();
    queue.add((index, true));
    _linkSegments.clear();

    while (queue.isNotEmpty) {
      final (node, usePrimaryColor) = queue.removeFirst();
      final neighbors = graph[node];
      if (neighbors == null) continue;
      for (final neighbor in neighbors) {
        if (visited.contains(neighbor)) continue;
        visited.add(neighbor);
        queue.add((neighbor, !usePrimaryColor));
        _linkSegments.add(
          LinkSegment(
            fromIndex: node,
            toIndex: neighbor,
            usePrimaryColor: usePrimaryColor,
          ),
        );
      }
    }
  }

  Map<int, Set<int>> _buildStrongLinkGraph(int digit, List<Set<int>> sets) {
    final graph = <int, Set<int>>{};

    void addEdge(int a, int b) {
      graph.putIfAbsent(a, () => <int>{}).add(b);
      graph.putIfAbsent(b, () => <int>{}).add(a);
    }

    for (var row = 0; row < size; row++) {
      final indices = <int>[];
      for (var col = 0; col < size; col++) {
        final index = _index(row, col);
        if (sets[index].contains(digit)) {
          indices.add(index);
        }
      }
      if (indices.length == 2) {
        addEdge(indices[0], indices[1]);
      }
    }

    for (var col = 0; col < size; col++) {
      final indices = <int>[];
      for (var row = 0; row < size; row++) {
        final index = _index(row, col);
        if (sets[index].contains(digit)) {
          indices.add(index);
        }
      }
      if (indices.length == 2) {
        addEdge(indices[0], indices[1]);
      }
    }

    for (var boxRow = 0; boxRow < size; boxRow += 3) {
      for (var boxCol = 0; boxCol < size; boxCol += 3) {
        final indices = <int>[];
        for (var r = boxRow; r < boxRow + 3; r++) {
          for (var c = boxCol; c < boxCol + 3; c++) {
            final index = _index(r, c);
            if (sets[index].contains(digit)) {
              indices.add(index);
            }
          }
        }
        if (indices.length == 2) {
          addEdge(indices[0], indices[1]);
        }
      }
    }

    return graph;
  }

  Set<int> _collectColorPeers(CellColoring color) {
    final peers = <int>{};
    for (var index = 0; index < _cells.length; index++) {
      if (_cells[index].coloring != color) {
        continue;
      }
      final row = index ~/ size;
      final col = index % size;
      for (var c = 0; c < size; c++) {
        final peer = _index(row, c);
        if (peer != index) {
          peers.add(peer);
        }
      }
      for (var r = 0; r < size; r++) {
        final peer = _index(r, col);
        if (peer != index) {
          peers.add(peer);
        }
      }
      final startRow = (row ~/ 3) * 3;
      final startCol = (col ~/ 3) * 3;
      for (var r = startRow; r < startRow + 3; r++) {
        for (var c = startCol; c < startCol + 3; c++) {
          final peer = _index(r, c);
          if (peer != index) {
            peers.add(peer);
          }
        }
      }
    }
    return peers;
  }

  int _index(int row, int col) => row * size + col;

  Set<int> _candidatesFor(int row, int col) {
    final used = <int>{};
    for (var c = 0; c < size; c++) {
      final value = _cells[_index(row, c)].value;
      if (value != null) {
        used.add(value);
      }
    }
    for (var r = 0; r < size; r++) {
      final value = _cells[_index(r, col)].value;
      if (value != null) {
        used.add(value);
      }
    }
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (var r = startRow; r < startRow + 3; r++) {
      for (var c = startCol; c < startCol + 3; c++) {
        final value = _cells[_index(r, c)].value;
        if (value != null) {
          used.add(value);
        }
      }
    }

    return {
      for (var candidate = 1; candidate <= 9; candidate++)
        if (!used.contains(candidate)) candidate,
    };
  }

  void _pruneNotesAround(int index, [int? value]) {
    final target = value ?? _cells[index].value;
    if (target == null) {
      return;
    }
    final row = index ~/ size;
    final col = index % size;

    for (var c = 0; c < size; c++) {
      final peer = _index(row, c);
      if (peer != index) {
        _removeNote(peer, target);
      }
    }
    for (var r = 0; r < size; r++) {
      final peer = _index(r, col);
      if (peer != index) {
        _removeNote(peer, target);
      }
    }
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (var r = startRow; r < startRow + 3; r++) {
      for (var c = startCol; c < startCol + 3; c++) {
        final peer = _index(r, c);
        if (peer != index) {
          _removeNote(peer, target);
        }
      }
    }
  }

  void _removeNote(int index, int note) {
    final cell = _cells[index];
    if (cell.value != null || !cell.notes.contains(note)) {
      return;
    }
    final updated = {...cell.notes}..remove(note);
    _cells[index] = cell.withNotes(updated);
  }

  bool _setsEqual(Set<int> a, Set<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final value in a) {
      if (!b.contains(value)) {
        return false;
      }
    }
    return true;
  }

  void _restoreNotesAround(int index, int value) {
    final row = index ~/ size;
    final col = index % size;

    for (var c = 0; c < size; c++) {
      final peer = _index(row, c);
      if (peer != index) {
        _addNoteIfCandidate(peer, value);
      }
    }
    for (var r = 0; r < size; r++) {
      final peer = _index(r, col);
      if (peer != index) {
        _addNoteIfCandidate(peer, value);
      }
    }
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (var r = startRow; r < startRow + 3; r++) {
      for (var c = startCol; c < startCol + 3; c++) {
        final peer = _index(r, c);
        if (peer != index) {
          _addNoteIfCandidate(peer, value);
        }
      }
    }
  }

  void _addNoteIfCandidate(int index, int value) {
    final cell = _cells[index];
    if (cell.value != null || cell.isGiven) {
      return;
    }
    final row = index ~/ size;
    final col = index % size;
    final candidates = _candidatesFor(row, col);
    if (!candidates.contains(value)) {
      return;
    }
    if (cell.notes.contains(value)) {
      return;
    }
    final updated = {...cell.notes}..add(value);
    _cells[index] = cell.withNotes(updated);
  }

  @override
  void dispose() {
    _pendingAutoSingles = false;
    _isAnimatingSingles = false;
    _autoFillHighlightIndex = null;
    _isDisposed = true;
    super.dispose();
  }

  void resetBoard() {
    if (_currentPuzzle == null) {
      return;
    }
    _initFromPuzzle(_currentPuzzle!);
  }

  bool undo() {
    if (_isAnimatingSingles || _history.isEmpty) {
      return false;
    }
    clearHint();
    final snapshot = _history.removeLast();
    for (var i = 0; i < _cells.length; i++) {
      _cells[i] = snapshot.cells[i];
    }
    _invalidateColoringCaches();
    _selectedIndex = snapshot.selectedIndex;
    _status = snapshot.status;
    _pendingAutoSingles = false;
    _autoFillHighlightIndex = null;
    if (_linksMode && _linksDigit != null && _selectedIndex != null) {
      _updateLinkSegmentsFrom(_selectedIndex!);
    } else {
      _clearLinks(resetDigit: false);
    }
    _emitChange();
    return true;
  }

  void _pushSnapshot() {
    _history.add(_makeSnapshot());
  }

  void _evaluateCompletion() {
    if (_status == GameStatus.lost || _currentPuzzle == null) {
      return;
    }
    for (final cell in _cells) {
      if (cell.value == null) {
        return;
      }
    }
    final solution = _currentPuzzle!.solution;
    for (var index = 0; index < _cells.length; index++) {
      final expected = int.tryParse(solution[index]);
      if (expected == null || _cells[index].value != expected) {
        return;
      }
    }
    _status = GameStatus.won;
  }

  void clearHint() {
    _hint = null;
    _emitChange();
  }

  _BoardSnapshot _makeSnapshot() {
    final cellsCopy = List<SudokuCell>.generate(_cells.length, (index) {
      final cell = _cells[index];
      return SudokuCell(
        value: cell.value,
        notes: cell.notes,
        isGiven: cell.isGiven,
        coloring: cell.coloring,
      );
    });
    return _BoardSnapshot(
      cells: cellsCopy,
      selectedIndex: _selectedIndex,
      status: _status,
    );
  }

  bool _applyHintToBoard(
    solver.Hint hint, {
    required bool triggerAutomation,
    required bool emitChange,
  }) {
    var mutated = false;

    for (final (index, digit) in hint.placements) {
      if (index < 0 || index >= _cells.length) continue;
      final cell = _cells[index];
      if (cell.isGiven || cell.value == digit) continue;
      _cells[index] = cell.withValue(digit);
      _pruneNotesAround(index, digit);
      mutated = true;
    }

    for (final (index, digit) in hint.eliminations) {
      if (index < 0 || index >= _cells.length) continue;
      final cell = _cells[index];
      if (cell.value != null || !cell.notes.contains(digit)) continue;
      final updatedNotes = {...cell.notes}..remove(digit);
      _cells[index] = cell.withNotes(updatedNotes);
      mutated = true;
    }

    if (!mutated) return false;

    _status = GameStatus.playing;
    if (triggerAutomation) {
      _scheduleAutoSingles();
      _evaluateCompletion();
    }
    if (_linksMode) {
      if (_linksDigit != null && _selectedIndex != null) {
        _updateLinkSegmentsFrom(_selectedIndex!);
      } else {
        _clearLinks(resetDigit: false);
      }
    }
    if (emitChange) _emitChange();
    return true;
  }
}

class _BoardSnapshot {
  _BoardSnapshot({
    required this.cells,
    required this.selectedIndex,
    required this.status,
  });

  final List<SudokuCell> cells;
  final int? selectedIndex;
  final GameStatus status;
}

class LinkSegment {
  final int fromIndex;
  final int toIndex;
  final bool usePrimaryColor;

  const LinkSegment({
    required this.fromIndex,
    required this.toIndex,
    required this.usePrimaryColor,
  });
}
