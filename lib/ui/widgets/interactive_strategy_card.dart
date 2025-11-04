import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InteractiveStrategyCard extends StatelessWidget {
  final StrategyType strategy;

  const InteractiveStrategyCard({super.key, required this.strategy});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          spacing: 12,
          children: [
            Icon(icon),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () {
                context.read<SudokuBoardState>().requestCancelInteractive();
              },
              icon: const Icon(Icons.close),
            ),
            IconButton.filled(
              onPressed: () {
                final board = context.read<SudokuBoardState>();
                Solver solver = Solver();
                final sudoku = Sudoku(
                  board.toValueList(),
                  notes: board.toNotesList(),
                );
                final hint = solver.getHintByClues(
                  sudoku,
                  board.selectedIndices,
                );
              },
              icon: const Icon(Icons.check),
            ),
          ],
        ),
      ],
    );
  }

  String get label => switch (strategy) {
    StrategyType.nakedPair => "Naked",
    _ => "Unknown",
  };

  IconData get icon => switch (strategy) {
    StrategyType.nakedPair => Icons.auto_awesome_motion_rounded,
    _ => Icons.question_mark_rounded,
  };
}
