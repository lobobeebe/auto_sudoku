import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/utils/feedback.dart';
import 'package:provider/provider.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({super.key, this.onHintRequested});

  final Future<void> Function()? onHintRequested;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final board = context.watch<SudokuBoardState>();
    final isEnabled = !board.isAnimatingSingles && board.hint == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        spacing: 12,
        mainAxisAlignment: MainAxisAlignment.center,
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
          Expanded(child: SizedBox()),
          Tooltip(
            message: board.noteMode ? 'Disable Notes' : 'Enable Notes',
            child: Switch(
              value: board.noteMode,
              activeThumbColor: colorScheme.onPrimary,
              activeTrackColor: colorScheme.primary,
              inactiveThumbColor: colorScheme.onSurface,
              inactiveTrackColor: colorScheme.surfaceContainerHigh,
              onChanged: (_) => isEnabled ? board.toggleNoteMode() : null,
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return const Icon(Icons.edit_rounded);
                }
                return const Icon(Icons.edit_off_rounded);
              }),
            ),
          ),
        ],
      ),
    );
  }
}
