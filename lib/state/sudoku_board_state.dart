import 'package:auto_sudoku/data/cell_view_model.dart';
import 'package:auto_sudoku/data/sudoku_model.dart';
import 'package:auto_sudoku/state/board_mode.dart';
import 'package:auto_sudoku/state/board_state/loading_state.dart';
import 'package:auto_sudoku/state/cell_state.dart';
import 'package:auto_sudoku/ui/theme/sudoku_theme.dart';
import 'package:auto_sudoku/ui/widgets/strategy_category_popup_menu.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';

enum GameResult { playing, won, lost }

class SudokuBoardState extends ChangeNotifier {
  static const int size = 9;
  final bool shouldAnimate = false;

  Sudoku _sudoku = Sudoku.empty();
  Sudoku get sudoku => _sudoku;
  final List<CellState> _cells = List.generate(size * size, (_) => CellState());
  SudokuModel? _currentPuzzle;

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

  StrategyCategory? strategyCategory = StrategyCategory.nakedHidden;

  SudokuModel? get currentPuzzle => _currentPuzzle;
  List<int> get selectedIndices => _selectedIndices;
  int? getRow(int index) => index ~/ size;
  int? getCol(int index) => index % size;
  int getBox(int row, int col) {
    final boxRow = row ~/ 3;
    final boxCol = col ~/ 3;
    return boxRow * 3 + boxCol;
  }

  int getIndex(int row, int col) => row * size + col;
  CellState cellAt(int index) => _cells[index];

  CellState? cellAtRC(int row, int col) {
    final index = getIndex(row, col);
    return cellAt(index);
  }

  List<int> get selectedValues =>
      selectedIndices.map((index) => _cells[index].value).toList();

  bool get allowControls => _mode.allowControls();
  bool get allowUndo => _mode.allowUndo() && _history.isNotEmpty;
  bool get allowRequestHint => _mode.allowRequestHint();
  bool get isNoteMode => _mode.isNoteMode();

  String get difficulty => _currentPuzzle?.difficulty.toString() ?? 'Unknown';

  void requestSelectCell(int row, int col) {
    _mode.onRequestSelectCell(row, col);
  }

  void requestClearHint() {
    _mode.onRequestClearHint();
  }

  bool requestNewHint() {
    if (_mode.allowRequestHint()) {
      final hint = _hintSolver.nextHint(_sudoku);

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

  void requestInitPuzzle(SudokuModel? puzzle, {String? error}) {
    _mode.onRequestInitPuzzle(puzzle, error);
  }

  void initPuzzle(SudokuModel puzzle) {
    _currentPuzzle = puzzle;
    _history.clear();

    // TODO - Should this be part of the puzzle object init?
    // Read in Given cells
    List<int> values = List.generate(81, (index) {
      final char = puzzle.puzzle[index];
      final parsed = int.tryParse(char);

      if (parsed == null) {
        throw ArgumentError("Cannot assigned $parsed to cell value");
      }

      return parsed;
    });

    _sudoku = Sudoku(values);
    _syncFromSudoku();
    emitChange();
  }
  // sudoku_board_state.dart

  void _syncFromSudoku({List<int>? mutatedIndices}) {
    if (mutatedIndices != null && mutatedIndices.isNotEmpty) {
      for (final i in mutatedIndices) {
        _cells[i].set(_sudoku.valueAt(i), _sudoku.notesMaskAt(i));
      }
    } else {
      for (var i = 0; i < 81; i++) {
        _cells[i].set(_sudoku.valueAt(i), _sudoku.notesMaskAt(i));
      }
    }
  }

  bool requestEnterDigit(int digit) {
    return _mode.onRequestEnterDigit(digit);
  }

  // Helper to determine if the current board has an available single
  Hint? nextSingle() {
    return _singleSolver.nextHint(_sudoku);
  }

  bool isDigitSelected(int digit) {
    return selectedValues.contains(digit);
  }

  bool isIndexSelected(int index) {
    return _selectedIndices.contains(index);
  }

  bool isPeersWithAnyMatching(int index) {
    final peers = getPeerIndices(index);

    for (final peer in peers) {
      if (!sudoku.isEmpty(peer) &&
          selectedValues.contains(sudoku.valueAt(peer))) {
        return true;
      }
    }

    return false;
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
    if (digit == 0) {
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
    _sudoku = snapshot.sudoku;
    _syncFromSudoku();
    emitChange(); // Undo Button
    return true;
  }

  void pushSnapshot({BoardSnapshot? snapshot}) {
    _history.add(snapshot ?? makeSnapshot());
  }

  bool canWinBySingles() {
    final result = _singleSolver.solveLogical(_sudoku.clone());

    return result.solved;
  }

  GameResult? evaluateResult() {
    if (_currentPuzzle == null) {
      return null;
    }

    // If any cell is unfilled, we are not yet complete
    for (final cell in _cells) {
      if (cell.value == 0) {
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

      if (_cells[index].value == 0) {
        hasEmptyCells = true;
      }
    }

    return hasEmptyCells ? null : GameResult.won;
  }

  BoardSnapshot makeSnapshot() {
    return BoardSnapshot(sudoku: _sudoku.clone());
  }

  bool applyHintToBoard(Hint hint) {
    final mutatedIndices = _sudoku.applyHint(hint);

    if (mutatedIndices.isNotEmpty) {
      _syncFromSudoku(mutatedIndices: mutatedIndices);
      return true;
    }

    return false;
  }
}

class BoardSnapshot {
  BoardSnapshot({required this.sudoku});

  final Sudoku sudoku;
}
