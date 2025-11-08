import 'package:auto_sudoku/data/sudoku_model.dart';
import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/pages/sudoku_home_page.dart';
import 'package:auto_sudoku/ui/widgets/tutorial_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LessonSudokuPage extends StatefulWidget {
  final SudokuModel model;
  final bool showUnitTutorialOnOpen;

  const LessonSudokuPage({
    super.key,
    required this.model,
    this.showUnitTutorialOnOpen = true,
  });

  @override
  State<LessonSudokuPage> createState() => _LessonSudokuPageState();
}

class _LessonSudokuPageState extends State<LessonSudokuPage> {
  bool _showTutorial = true;
  TutorialController? _controller;
  @override
  void initState() {
    super.initState();
    _showTutorial = widget.showUnitTutorialOnOpen;
  }

  @override
  Widget build(BuildContext context) {
    _controller ??= TutorialController(
      steps: const [
        TutorialStep(
          title: 'What is a Unit?',
          body:
              "A unit is a row, a column, or a 3×3 box. Each unit must contain the digits 1–9 exactly once without repeats.",
        ),
        TutorialStep(
          rows: {4},
          title: 'Rows',
          body:
              'Each row is a unit. The numbers 1–9 may only appear once across the row.',
        ),
        TutorialStep(
          cols: {3},
          title: 'Columns',
          body:
              'Each column is also a unit. The numbers 1–9 may only appear once vertically.',
        ),
        TutorialStep(
          boxes: {4},
          title: '3×3 Boxes',
          body:
              'Each 3×3 box is a unit. Make sure each digit 1–9 appears exactly once within each box.',
        ),
      ],
      onDone: () => setState(() => _showTutorial = false),
    );
    return ChangeNotifierProvider<SudokuBoardState>(
      create: (_) {
        final board = SudokuBoardState(showNotes: false);
        board.requestInitPuzzle(widget.model);
        return board;
      },
      child: SudokuHomePage(
        tutorialOverlay: _showTutorial && _controller != null
            ? GridMaskOverlay(controller: _controller!)
            : null,
        tutorialPanelOverlay: _showTutorial && _controller != null
            ? TutorialPanel(controller: _controller!)
            : null,
      ),
    );
  }
}
