import 'package:auto_sudoku/data/cell_view_model.dart';
import 'package:auto_sudoku/data/sudoku_puzzle_model.dart';
import 'package:auto_sudoku/state/board_mode.dart';
import 'package:auto_sudoku/state/board_state/loading_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:auto_sudoku/ui/widgets/strategy_category_popup_menu.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';

enum GameResult { playing, won, lost }

class SudokuCell {
  final int? value;
  final Set<int> notes;
  final bool isGiven;

  SudokuCell({this.value, Set<int>? notes, this.isGiven = false})
    : notes = notes != null ? Set<int>.from(notes) : <int>{};

  SudokuCell withValue(int? newValue) =>
      SudokuCell(value: newValue, notes: const <int>{}, isGiven: isGiven);

  SudokuCell withNotes(Set<int> newNotes) =>
      SudokuCell(value: value, notes: newNotes, isGiven: isGiven);
}

class SudokuBoardState extends ChangeNotifier {
  static const int size = 9;
  final bool shouldAnimate = false;

  final List<SudokuCell> _cells = List.generate(
    size * size,
    (_) => SudokuCell(),
  );
  SudokuPuzzleModel? _currentPuzzle;

  final List<BoardSnapshot> _history = <BoardSnapshot>[];
  bool _isDisposed = false;
  final List<int> _selectedIndices = [];

  late BoardMode _mode;
  bool _hasBoardModeBuilt = false;
  final Solver _hintSolver = Solver(settings: SolverSettings.all());

  // Solver for finding singles
  final Solver _singleSolver = Solver(
    settings: SolverSettings(allowed: {StrategyType.nakedSingle}),
  );

  SudokuBoardState() {
    _mode = LoadingMode(this);
  }

  void setMode(BoardMode next) {
    _mode.onExit();
    _mode = next;
    _hasBoardModeBuilt = false;
    _mode.onEnter();
    emitChange();
  }

  void emitChange() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  StrategyCategory? strategyCategory = StrategyCategory.naked;

  SudokuPuzzleModel? get currentPuzzle => _currentPuzzle;
  List<int> get selectedIndices => _selectedIndices;
  int? getRow(int index) => index ~/ size;
  int? getCol(int index) => index % size;
  int getBox(int row, int col) {
    final boxRow = row ~/ 3;
    final boxCol = col ~/ 3;
    return boxRow * 3 + boxCol;
  }

  int getIndex(int row, int col) => row * size + col;
  SudokuCell? getCellAtIndex(int index) {
    return _cells[index];
  }

  void setCellAtIndex(int index, SudokuCell cell) {
    _cells[index] = cell;
  }

  SudokuCell? getCellAt(int row, int col) {
    final index = getIndex(row, col);
    return getCellAtIndex(index);
  }

  List<int> get selectedValues =>
      selectedIndices.map((index) => _cells[index].value ?? 0).toList();

  bool get allowControls => _mode.allowControls();
  bool get allowUndo => _mode.allowUndo() && _history.isNotEmpty;
  bool get allowRequestHint => _mode.allowRequestHint();
  bool get isNoteMode => _mode.isNoteMode();

  String get difficulty => _currentPuzzle?.difficulty.toString() ?? 'Unknown';

  /// Returns the current board values as a flat list with zero for blanks.
  List<int> toValueList() =>
      List<int>.generate(_cells.length, (index) => _cells[index].value ?? 0);

  /// Returns a deep copy of the current cell notes for each position.
  List<Set<int>> toNotesList() => List<Set<int>>.generate(
    _cells.length,
    (index) => Set<int>.from(_cells[index].notes),
  );

  void requestSelectCell(int row, int col) {
    _mode.onRequestSelectCell(row, col);
  }

  void requestClearHint() {
    _mode.onRequestClearHint();
  }

  bool requestNewHint() {
    if (_mode.allowRequestHint()) {
      final sudoku = Sudoku(toValueList(), notes: toNotesList());
      final hint = _hintSolver.nextHint(sudoku);

      if (hint != null) {
        _mode.onRequestSetHint(hint);
        return true;
      }
    }

    return false;
  }

  void requestSetHint(Hint? hint) {
    if (hint == null) {
      requestClearHint();
      return;
    }
    _mode.onRequestSetHint(hint);
  }

  bool requestApplyCurrentHint() {
    return _mode.onRequestApplyCurrentHint();
  }

  void requestStrategyCategory(StrategyCategory category) {
    return _mode.onRequestStrategyCategory(category);
  }

  bool allowReset() => _mode.allowReset();

  void requestToggleNodeMode() => _mode.onRequestNoteMode();

  void requestInteractive(Set<StrategyType> types) =>
      _mode.onRequestInteractive(types);

  void requestCancelInteractive() => _mode.onRequestCancelInteractive();

  Widget? buildBodyOverride(BuildContext context) =>
      _mode.buildBodyOverride(context);

  void onBuild(BuildContext context) {
    if (!_hasBoardModeBuilt) {
      _mode.onFirstBuild(context);
      _hasBoardModeBuilt = true;
    }
  }

  Widget buildBottomBar() => _mode.buildBottomBar();

  CellViewModel buildCellViewModel(int index, SudokuTheme theme) =>
      _mode.buildCellViewModel(index, theme);

  bool canPressDigit(int digit) => _mode.canPressDigit(digit);

  bool canPlaceDigit(int? idx, int digit) {
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
      if (_cells[getIndex(row, c)].value == digit) {
        return false;
      }
    }
    for (var r = 0; r < size; r++) {
      if (r == row) continue;
      if (_cells[getIndex(r, col)].value == digit) {
        return false;
      }
    }
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (var r = startRow; r < startRow + 3; r++) {
      for (var c = startCol; c < startCol + 3; c++) {
        final index = getIndex(r, c);
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

  void requestInitPuzzle(SudokuPuzzleModel? puzzle, {String? error}) {
    _mode.onRequestInitPuzzle(puzzle, error);
  }

  void initPuzzle(SudokuPuzzleModel puzzle) {
    _currentPuzzle = puzzle;
    _history.clear();

    // TODO - Should this be part of the puzzle object init?
    // Read in Given cells
    for (var index = 0; index < _cells.length; index++) {
      final char = puzzle.puzzle[index];
      final parsed = int.tryParse(char);
      final value = parsed == null || parsed == 0 ? null : parsed;
      _cells[index] = value != null
          ? SudokuCell(value: value, notes: const <int>{}, isGiven: true)
          : SudokuCell();
    }

    // TODO - Should this be part of the puzzle object init?
    // Fill in all notes
    for (var index = 0; index < _cells.length; index++) {
      final cell = _cells[index];
      if (cell.value != null) {
        if (cell.notes.isNotEmpty) {
          _cells[index] = cell.withNotes(const <int>{});
        }
        continue;
      }

      final row = index ~/ size;
      final col = index % size;
      final candidates = _candidatesFor(row, col);
      _cells[index] = cell.withNotes(candidates);
    }
  }

  bool requestEnterDigit(int digit) {
    return _mode.onRequestEnterDigit(digit);
  }

  // Helper to determine if the current board has an available single
  Hint? nextSingle() {
    return _singleSolver.nextHint(Sudoku(toValueList(), notes: toNotesList()));
  }

  bool isDigitSelected(int digit) {
    return selectedValues.contains(digit);
  }

  bool isIndexSelected(int index) {
    return _selectedIndices.contains(index);
  }

  bool isPeerWithAnySelected(int index) {
    if (_selectedIndices.isEmpty) return false;
    return _selectedIndices.any(
      (selectedIndex) => arePeers(selectedIndex, index),
    );
  }

  bool isPeerWithAllSelected(int index) {
    if (_selectedIndices.isEmpty) return false;
    return _selectedIndices.every(
      (selectedIndex) => arePeers(selectedIndex, index),
    );
  }

  bool matchesAnySelected(int index) {
    if (index < 0 || index >= _cells.length) {
      return false;
    }

    final digit = _cells[index].value;
    if (digit == null) {
      return false;
    }

    return _selectedIndices.any(
      (selectedIndex) => _cells[selectedIndex].value == digit,
    );
  }

  bool arePeers(int lhsIndex, int rhsIndex) {
    final lhsRow = getRow(lhsIndex);
    final lhsCol = getCol(lhsIndex);

    final rhsRow = getRow(rhsIndex);
    final rhsCol = getCol(rhsIndex);

    if (lhsRow == null || lhsCol == null || rhsRow == null || rhsCol == null) {
      return false;
    }

    if (lhsRow == rhsRow || lhsCol == rhsCol) return true;

    final lhsBox = getBox(lhsRow, lhsCol);
    final rhsBox = getBox(rhsRow, rhsCol);

    return lhsBox == rhsBox;
  }

  Set<int> getPeerIndices(int index) {
    final Set<int> peerIndices = {};
    final row = getRow(index);
    final col = getCol(index);

    if (row == null || col == null) {
      return {};
    }

    // Same row
    for (var c = 0; c < size; c++) {
      if (c != col) {
        peerIndices.add(getIndex(row, c));
      }
    }

    // Same Column
    for (var r = 0; r < size; r++) {
      if (r != row) {
        peerIndices.add(getIndex(r, col));
      }
    }

    // Same Box
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (var r = startRow; r < startRow + 3; r++) {
      for (var c = startCol; c < startCol + 3; c++) {
        if (r != row || c != col) {
          peerIndices.add(getIndex(r, c));
        }
      }
    }

    return peerIndices;
  }

  Set<int> _candidatesFor(int row, int col) {
    final used = <int>{};
    for (var c = 0; c < size; c++) {
      final value = _cells[getIndex(row, c)].value;
      if (value != null) {
        used.add(value);
      }
    }
    for (var r = 0; r < size; r++) {
      final value = _cells[getIndex(r, col)].value;
      if (value != null) {
        used.add(value);
      }
    }
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (var r = startRow; r < startRow + 3; r++) {
      for (var c = startCol; c < startCol + 3; c++) {
        final value = _cells[getIndex(r, c)].value;
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

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void resetBoard() {
    if (_currentPuzzle == null) {
      return;
    }
    initPuzzle(_currentPuzzle!);
  }

  void requestUndo() {
    _mode.onRequestUndo();
  }

  bool undo() {
    if (_history.isEmpty) {
      return false;
    }

    final snapshot = _history.removeLast();
    for (var i = 0; i < _cells.length; i++) {
      _cells[i] = snapshot.cells[i];
    }
    emitChange();
    return true;
  }

  void pushSnapshot({BoardSnapshot? snapshot}) {
    _history.add(snapshot ?? makeSnapshot());
  }

  bool canWinBySingles() {
    final result = _singleSolver.solveLogical(
      Sudoku(toValueList(), notes: toNotesList()),
    );

    return result.solved;
  }

  GameResult? evaluateResult() {
    if (_currentPuzzle == null) {
      return null;
    }

    // If any cell is unfilled, we are not yet complete
    for (final cell in _cells) {
      if (cell.value == null) {
        return null;
      }
    }
    bool hasEmptyCells = false;
    // Evaluate against the solution
    final solution = _currentPuzzle!.solution;
    for (var index = 0; index < _cells.length; index++) {
      final expected = int.tryParse(solution[index]);
      if (expected == null || _cells[index].value != expected) {
        return GameResult.lost;
      }

      if (_cells[index].value == null) {
        hasEmptyCells = true;
      }
    }

    return hasEmptyCells ? null : GameResult.won;
  }

  BoardSnapshot makeSnapshot() {
    final cellsCopy = List<SudokuCell>.generate(_cells.length, (index) {
      final cell = _cells[index];
      return SudokuCell(
        value: cell.value,
        notes: cell.notes,
        isGiven: cell.isGiven,
      );
    });
    return BoardSnapshot(cells: cellsCopy);
  }

  bool applyHintToBoard(Hint hint) {
    var mutated = false;

    for (final entry in hint.placements.entries) {
      final index = entry.key;
      final digit = entry.value;

      if (index < 0 || index >= _cells.length) continue;
      final cell = _cells[index];
      if (cell.isGiven || cell.value == digit) continue;
      _cells[index] = cell.withValue(digit);
      pruneNotesAround(index, digit);
      mutated = true;
    }

    for (final entry in hint.eliminations.entries) {
      final index = entry.key;
      for (final digit in entry.value) {
        if (index < 0 || index >= _cells.length) continue;
        final cell = _cells[index];
        if (cell.value != null || !cell.notes.contains(digit)) continue;
        final updatedNotes = {...cell.notes}..remove(digit);
        _cells[index] = cell.withNotes(updatedNotes);
        mutated = true;
      }
    }

    return mutated;
  }

  void pruneNotesAround(int index, [int? value]) {
    final target = value ?? getCellAtIndex(index)?.value;
    if (target == null) {
      return;
    }
    final size = SudokuBoardState.size;
    final row = index ~/ size;
    final col = index % size;

    for (var c = 0; c < size; c++) {
      final peer = getIndex(row, c);
      if (peer != index) {
        _removeNote(peer, target);
      }
    }
    for (var r = 0; r < size; r++) {
      final peer = getIndex(r, col);
      if (peer != index) {
        _removeNote(peer, target);
      }
    }
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (var r = startRow; r < startRow + 3; r++) {
      for (var c = startCol; c < startCol + 3; c++) {
        final peer = getIndex(r, c);
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
}

class BoardSnapshot {
  BoardSnapshot({required this.cells});

  final List<SudokuCell> cells;
}
