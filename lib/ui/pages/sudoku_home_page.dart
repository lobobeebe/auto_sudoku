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

  @override
  Widget build(BuildContext context) {
    final board = context.watch<SudokuBoardState>();
    final theme = Theme.of(context);

    _maybeShowEndDialog(board);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
        title: const Text('Auto Sudoku'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: board.isLoading ? null : board.resetBoard,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(context, board),
    );
  }

  Widget _buildBody(BuildContext context, SudokuBoardState board) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget content;
    if (board.isLoading) {
      content = const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator.adaptive(),
      );
    } else if (board.error != null) {
      content = _ErrorPanel(
        key: const ValueKey('error'),
        message: board.error!,
        onReturn: () => Navigator.pop(context),
      );
    } else {
      content = _buildPuzzleContent(context, board);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          top: -72,
          right: -20,
          child: _BackgroundOrb(color: colorScheme.primary, size: 220),
        ),
        Positioned(
          bottom: -80,
          left: -60,
          child: _BackgroundOrb(
            color: colorScheme.secondaryContainer,
            size: 260,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              child: content,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPuzzleContent(BuildContext context, SudokuBoardState board) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          key: const ValueKey('puzzle'),
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildBoardCard(context)),
              const SizedBox(height: 24),
              _buildControlsCard(context, board),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBoardCard(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: const SudokuGrid(),
    );
  }

  Widget _buildControlsCard(BuildContext context, SudokuBoardState board) {
    final colorScheme = Theme.of(context).colorScheme;
    final hint = board.hint;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: colorScheme.surface.withValues(alpha: 0.94),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: hint == null ? 1 : 0.2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ActionBar(onHintRequested: _handleHintRequest),
                const SizedBox(height: 20),
                const NumberPad(),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: child,
                ),
              );
            },
            child: hint == null
                ? const SizedBox.shrink()
                : HintStepsPanel(
                    key: const ValueKey('hintPanel'),
                    hint: hint,
                    onSkip: _handleHintSkip,
                    onApply: _handleHintApply,
                  ),
          ),
        ],
      ),
    );
  }

  void _maybeShowEndDialog(SudokuBoardState board) {
    final status = board.status;
    _lastGameStatus ??= status;

    if (_lastGameStatus != status) {
      _lastGameStatus = status;

      if (status != GameStatus.playing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showResultDialog(board);
        });
      }
    }
  }

  Future<void> _showResultDialog(SudokuBoardState board) async {
    final isWin = board.status == GameStatus.won;
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
                : 'That entry conflicts with the solution. Undo the move or exit to the menu.',
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

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onReturn;

  const _ErrorPanel({super.key, required this.message, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sentiment_dissatisfied_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'We hit a snag while loading puzzles.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: onReturn, child: const Text('Return')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _BackgroundOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: size * 0.6,
            spreadRadius: size * 0.18,
          ),
        ],
      ),
    );
  }
}
