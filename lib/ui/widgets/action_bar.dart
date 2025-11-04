import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/utils/feedback.dart';
import 'package:provider/provider.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final board = context.watch<SudokuBoardState>();
    final isEnabled = board.allowControls;
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
          onPressed: isEnabled && board.allowUndo ? board.requestUndo : null,
          icon: const Icon(Icons.undo_rounded),
        ),
        IconButton.filledTonal(
          tooltip: 'Hint',
          onPressed: isEnabled && board.allowRequestHint
              ? () {
                  if (!board.requestNewHint()) {
                    showFeedback(context, 'No logical hint available.');
                  }
                }
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
          tooltip: board.isNoteMode ? 'Disable Notes' : 'Enable Notes',
          isSelected: board.isNoteMode,
          style: toolStyle,
          onPressed: isEnabled ? board.requestToggleNodeMode : null,
          icon: const Icon(Icons.edit_outlined),
          selectedIcon: const Icon(Icons.edit),
        ),
        PopupMenuButton(
          itemBuilder: (BuildContext context) => <PopupMenuEntry<StrategyType>>[
            const PopupMenuItem<StrategyType>(
              value: StrategyType.nakedPair,
              child: Row(
                spacing: 12,
                children: [
                  Icon(Icons.auto_awesome_motion_rounded),
                  Text("Naked"),
                ],
              ),
            ),
            const PopupMenuItem<StrategyType>(
              value: StrategyType.pointing,
              child: Row(
                spacing: 12,
                children: [Icon(Icons.arrow_forward), Text("Pointing")],
              ),
            ),
            // Add more PopupMenuItem widgets for other options if needed
          ],
          enabled: isEnabled && board.allowRequestHint,
          tooltip: 'Technique',
          style: toolStyle,
          icon: const Icon(Icons.auto_fix_high_outlined),
          onSelected: (strategy) {
            board.requestInteractive({strategy});
          },
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [leftControls, const Spacer(), toolButtons]),
    );
  }
}
