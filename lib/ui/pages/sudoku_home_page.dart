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
  bool _fabExpanded = false;

  @override
  Widget build(BuildContext context) {
    final board = context.watch<SudokuBoardState>();
    final theme = Theme.of(context);
    final bool fabDisabled =
        board.isLoading ||
        board.isAnimatingSingles ||
        board.isInteractiveModeActive;

    if (fabDisabled && _fabExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _fabExpanded = false;
        });
      });
    }

    _maybeShowEndDialog(board);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Auto Sudoku'),
            Text(
              board.difficulty,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
      floatingActionButton: _TechniqueFabMenu(
        expanded: _fabExpanded,
        disabled: fabDisabled,
        onToggle: fabDisabled ? null : _toggleFabMenu,
        onSelectNakedPair: fabDisabled ? null : _startNakedPairSelection,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hint = board.hint;
    final isTechniqueActive =
        board.interactiveMode != InteractiveSolveMode.none;

    Widget wrapCard({required Key key, required Widget child}) {
      return Container(
        key: key,
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
        child: child,
      );
    }

    late final Widget child;
    if (isTechniqueActive) {
      child = wrapCard(
        key: const ValueKey('technique'),
        child: _NakedPairSelectionCard(
          selectedIndices: board.interactiveSelection,
          targetCount: board.interactiveTargetCount,
          canConfirm: board.isInteractiveSelectionComplete,
          onCancel: _handleTechniqueCancel,
          onConfirm: _handleNakedPairConfirm,
        ),
      );
    } else if (hint != null) {
      child = wrapCard(
        key: const ValueKey('hintPanel'),
        child: HintStepsPanel(
          hint: hint,
          onSkip: _handleHintSkip,
          onApply: _handleHintApply,
        ),
      );
    } else {
      child = wrapCard(
        key: const ValueKey('controls'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionBar(onHintRequested: _handleHintRequest),
            const SizedBox(height: 20),
            const NumberPad(),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  void _toggleFabMenu() {
    setState(() {
      _fabExpanded = !_fabExpanded;
    });
  }

  void _startNakedPairSelection() {
    setState(() {
      _fabExpanded = false;
    });
    final board = context.read<SudokuBoardState>();
    board.beginNakedPairSelection();
  }

  void _handleTechniqueCancel() {
    context.read<SudokuBoardState>().cancelInteractiveMode();
  }

  Future<void> _handleNakedPairConfirm() async {
    final board = context.read<SudokuBoardState>();
    final result = board.applyNakedPairSelection();
    if (!result.success) {
      await _showNoNakedPairDialog();
      return;
    }

    final digits = result.digits;
    final techniqueLabel = digits.isEmpty
        ? 'Naked Pair'
        : 'Naked Pair ${digits.join(' & ')}';
    final removed = result.eliminations;
    final removalText = removed == 1
        ? 'Removed 1 candidate using $techniqueLabel.'
        : 'Removed $removed candidates using $techniqueLabel.';
    showFeedback(context, removalText);
  }

  Future<void> _showNoNakedPairDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text('No Naked Pair Found', style: textTheme.titleMedium),
            ],
          ),
          content: Text(
            'Those cells do not form a valid Naked Pair or no candidates can be removed. Try selecting a different combination.',
            style: textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
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

class _TechniqueFabMenu extends StatelessWidget {
  final bool expanded;
  final bool disabled;
  final VoidCallback? onToggle;
  final VoidCallback? onSelectNakedPair;

  const _TechniqueFabMenu({
    required this.expanded,
    required this.disabled,
    required this.onToggle,
    required this.onSelectNakedPair,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        expanded
            ? Padding(
                key: const ValueKey('technique-menu'),
                padding: const EdgeInsets.only(bottom: 12),
                child: _TechniqueMenuCard(onSelectNakedPair: onSelectNakedPair),
              )
            : const SizedBox.shrink(key: ValueKey('technique-menu-gap')),
        FloatingActionButton(
          heroTag: 'technique-fab',
          onPressed: (disabled || onToggle == null) ? null : onToggle,
          child: Icon(expanded ? Icons.close : Icons.add),
        ),
      ],
    );
  }
}

class _TechniqueMenuCard extends StatelessWidget {
  final VoidCallback? onSelectNakedPair;

  const _TechniqueMenuCard({required this.onSelectNakedPair});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.hardEdge,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: ListTile(
          leading: Icon(
            Icons.auto_awesome_motion_rounded,
            color: colorScheme.primary,
          ),
          title: const Text('Naked Pair'),
          onTap: onSelectNakedPair,
          enabled: onSelectNakedPair != null,
        ),
      ),
    );
  }
}

class _NakedPairSelectionCard extends StatelessWidget {
  final List<int> selectedIndices;
  final int targetCount;
  final bool canConfirm;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _NakedPairSelectionCard({
    required this.selectedIndices,
    required this.targetCount,
    required this.canConfirm,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final count = selectedIndices.length;
    final statusText = targetCount > 0
        ? '$count of $targetCount cells selected'
        : '$count cells selected';

    final chips = selectedIndices.take(targetCount).map((index) {
      final row = index ~/ SudokuBoardState.size + 1;
      final col = index % SudokuBoardState.size + 1;
      return Chip(
        label: Text('R$row C$col'),
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      );
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_motion_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Naked Pair',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              statusText,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (chips.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: chips)
        else
          Text(
            'Waiting for two cells...',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
            const Spacer(),
            FilledButton(
              onPressed: canConfirm ? onConfirm : null,
              child: const Text('Confirm'),
            ),
          ],
        ),
      ],
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
