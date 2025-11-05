import 'package:auto_sudoku/ui/widgets/strategy_category_popup_menu.dart';
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
        // IconButton(
        //   tooltip: board.isNoteMode ? 'Disable Notes' : 'Enable Notes',
        //   isSelected: board.isNoteMode,
        //   style: toolStyle,
        //   onPressed: isEnabled ? board.requestToggleNodeMode : null,
        //   icon: const Icon(Icons.edit_outlined),
        //   selectedIcon: const Icon(Icons.edit),
        // ),
        StrategyPopupMenuButton(
          currentValue: board.strategyCategory,
          onSelected: board.requestStrategyCategory,
          enabled: isEnabled && board.allowRequestHint,
        ),
        // PopupMenuButton(
        //   itemBuilder: (BuildContext context) => <PopupMenuEntry<StrategyType>>[
        //     const PopupMenuItem<StrategyType>(
        //       value: StrategyType.nakedPair,
        //       child: Row(
        //         spacing: 12,
        //         children: [
        //           Icon(Icons.auto_awesome_motion_rounded),
        //           Text("Naked"),
        //         ],
        //       ),
        //     ),
        //     const PopupMenuItem<StrategyType>(
        //       value: StrategyType.pointing,
        //       child: Row(
        //         spacing: 12,
        //         children: [Icon(Icons.arrow_forward), Text("Pointing")],
        //       ),
        //     ),
        //     // Add more PopupMenuItem widgets for other options if needed
        //   ],
        //   enabled: isEnabled && board.allowRequestHint,
        //   tooltip: 'Technique',
        //   style: toolStyle,
        //   icon: const Icon(Icons.auto_fix_high_outlined),
        //   onSelected: (strategy) {
        //     board.requestInteractive({strategy});
        //   },
        // ),
      ],
    );

    return Row(children: [leftControls, const Spacer(), toolButtons]);
  }
}
