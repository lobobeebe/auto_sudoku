import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/utils/feedback.dart';
import 'package:auto_sudoku/ui/widgets/action_bar.dart';
import 'package:auto_sudoku/ui/widgets/hint_steps_panel.dart';
import 'package:auto_sudoku/ui/widgets/number_pad.dart';
import 'package:auto_sudoku/ui/widgets/sudoku_grid.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:provider/provider.dart';

class SudokuHomePage extends StatefulWidget {
  const SudokuHomePage({super.key});

  @override
  State<SudokuHomePage> createState() => _SudokuHomePageState();
}

class _SudokuHomePageState extends State<SudokuHomePage> {
  final Solver _solver = Solver();
  GameStatus? _lastGameStatus;
  String? _lastError;

  @override
  Widget build(BuildContext context) {
    final board = context.watch<SudokuBoardState>();
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final horizontalPadding = shortestSide < 600 ? 16.0 : 32.0;
    final isLoading = board.isLoading;

    _maybeShowEndDialog(board.status);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(children: [const Text('Auto Sudoku')]),

        actions: [
          IconButton(
            tooltip: 'Reset Board',
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : board.resetBoard,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, board, horizontalPadding)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SudokuBoardState board,
    double horizontalPadding,
  ) {
    if (board.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final error = board.error;
    if (error != _lastError) {
      _lastError = error;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We hit a snag while loading puzzles.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error ?? "Null Error",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Return'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: const SudokuGrid()),
          SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Controls (base layer)
                Column(
                  key: const ValueKey('controls'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ActionBar(onHintRequested: _handleHintRequest),
                    const SizedBox(height: 12),
                    NumberPad(),
                  ],
                ),

                // Hint panel (top layer)
                if (board.hint != null)
                  Positioned.fill(
                    child: HintStepsPanel(
                      key: const ValueKey('hintPanel'),
                      hint: board.hint!,
                      onSkip: _handleHintSkip,
                      onApply: _handleHintApply,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _maybeShowEndDialog(GameStatus status) {
    _lastGameStatus ??= status;

    if (_lastGameStatus != status) {
      _lastGameStatus = status;

      if (status != GameStatus.playing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showResultDialog(status);
        });
      }
    }
  }

  Future<void> _showResultDialog(GameStatus status) async {
    final isWin = status == GameStatus.won;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(
                isWin
                    ? Icons.emoji_events_rounded
                    : Icons.error_outline_rounded,
                color: isWin ? colorScheme.primary : colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(isWin ? 'Puzzle Complete!' : 'Incorrect Move'),
            ],
          ),
          content: Text(
            isWin
                ? 'Great job! You solved the puzzle.'
                : 'That entry conflicts with the solution. Try again or exit to the menu.',
            style: textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Review'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleHintRequest() async {
    final board = context.read<SudokuBoardState>();
    final sudoku = Sudoku(board.toValueList(), notes: board.toNotesList());
    final hint = _solver.nextHint(sudoku);

    if (hint == null) {
      showFeedback(context, 'No logical hint available.');
      return;
    }

    board.deselectCell();
    board.setHint(hint);
  }

  void _handleHintSkip() {
    final board = context.read<SudokuBoardState>();
    board.clearHint();
  }

  void _handleHintApply() {
    final board = context.read<SudokuBoardState>();
    final applied = board.applyCurrentHint();
    if (!applied) {
      board.clearHint();
      showFeedback(context, 'Unable to apply hint.');
    }
  }
}
