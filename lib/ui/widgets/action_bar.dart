import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/utils/feedback.dart';
import 'package:provider/provider.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({super.key, this.onHintRequested});

  final Future<void> Function()? onHintRequested;

  @override
  Widget build(BuildContext context) {
    final board = context.watch<SudokuBoardState>();
    final isEnabled = !board.isAnimatingSingles && board.hint == null;
    final colorScheme = Theme.of(context).colorScheme;

    final toolStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
        }
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.surfaceContainerHigh;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary;
        }
        return colorScheme.onSurfaceVariant;
      }),
    );

    final leftControls = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
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
          tooltip: 'Hint',
          onPressed:
              isEnabled &&
                  board.status == GameStatus.playing &&
                  onHintRequested != null
              ? () => onHintRequested!.call()
              : null,
          icon: const Icon(Icons.question_mark),
        ),
      ],
    );

    final toolButtons = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        IconButton(
          tooltip: board.noteMode ? 'Disable Notes' : 'Enable Notes',
          isSelected: board.noteMode,
          style: toolStyle,
          onPressed: isEnabled ? board.toggleNoteMode : null,
          icon: const Icon(Icons.edit_outlined),
          selectedIcon: const Icon(Icons.edit),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [leftControls, const Spacer(), toolButtons]),
    );
  }
}
