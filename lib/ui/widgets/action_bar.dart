import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/utils/feedback.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart' as solver;
import 'package:provider/provider.dart';

class ActionBar extends StatelessWidget {
  static final solver.Solver _solver = solver.Solver();

  const ActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final board = context.watch<SudokuBoardState>();
    final isEnabled = !board.isAnimatingSingles;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 12,
      children: [
        _DifficultyInfo(difficulty: board.difficulty),
        SizedBox(width: 16),
        IconButton.filledTonal(
          tooltip: 'Undo last move',
          onPressed: isEnabled && board.canUndo
              ? () {
                  final undone = board.undo();
                  if (!undone) {
                    showFeedback(context, 'Nothing left to undo.');
                  }
                }
              : null,
          icon: const Icon(Icons.undo_rounded),
        ),
        IconButton.filledTonal(
          tooltip: "Hint",
          onPressed: isEnabled && board.status == GameStatus.playing
              ? () => onHintPressed(context)
              : null,
          icon: const Icon(Icons.question_mark),
        ),
        Tooltip(
          message: board.noteMode ? "Disable Notes" : "Enable Notes",
          child: Switch(
            value: board.noteMode,
            activeThumbColor: colorScheme.onPrimary,
            activeTrackColor: colorScheme.primary,
            inactiveThumbColor: colorScheme.onSurface,
            inactiveTrackColor: colorScheme.surfaceContainerHigh,
            onChanged: (_) => isEnabled ? board.toggleNoteMode() : null,
            // Define the thumb icon based on the switch state
            thumbIcon: WidgetStateProperty.resolveWith<Icon?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return const Icon(Icons.edit_rounded); // Icon when switch is ON
              }
              return const Icon(
                Icons.edit_off_rounded,
              ); // Icon when switch is OFF
            }),
          ),
        ),
      ],
    );
  }

  void onHintPressed(BuildContext context) {
    final board = context.read<SudokuBoardState>();
    final sudoku = solver.Sudoku(
      board.toValueList(),
      notes: board.toNotesList(),
    );
    final hint = _solver.nextHint(sudoku, allowTriples: true, allowXWing: true);
    final messenger = ScaffoldMessenger.of(context);

    if (hint == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No logical hint available.')),
      );
      return;
    }

    final applied = board.applyHint(hint);
    if (!applied) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Solver could not apply a move.')),
      );
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(hint.description)));
  }
}

class _DifficultyInfo extends StatelessWidget {
  final String difficulty;

  const _DifficultyInfo({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primaryContainer.withValues(alpha: 0.28),
          ),
          child: Icon(
            Icons.speed_rounded,
            size: 26,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          difficulty,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
