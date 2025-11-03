import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InteractiveStrategyCard extends StatelessWidget {
  final Widget icon;
  final String label;

  const InteractiveStrategyCard({
    super.key,
    required this.icon,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          spacing: 12,
          children: [
            icon,
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () {
                context.read<SudokuBoardState>().cancelInteractiveMode();
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
                  board.interactiveSelection,
                );

                if (hint != null) {
                  board.setHint(hint);
                }
              },
              icon: const Icon(Icons.check),
            ),
          ],
        ),
      ],
    );
  }
}
