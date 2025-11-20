import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/utils/feedback.dart';
import 'package:provider/provider.dart';
import 'package:auto_sudoku/ui/widgets/tutorial_overlay.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final board = context.watch<SudokuBoardState>();
    // If a tutorial is active, enable only when the step allows it.
    // Provider might not be present; fall back to enabled.
    TutorialController? tutorial = TutorialController.of(context);
    final tutorialAllows =
        ((tutorial?.isDone ?? true) ||
        (tutorial?.current.enableActionBar ?? true));
    final isEnabled = board.allowControls && tutorialAllows;

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
                    showToast(context, Text('No logical hint available.'));
                  }
                }
              : null,
          icon: const Icon(Icons.question_mark),
        ),
      ],
    );

    return Row(children: [leftControls, const Spacer()]);
  }
}
