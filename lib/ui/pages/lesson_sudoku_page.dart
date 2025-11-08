import 'package:auto_sudoku/data/sudoku_model.dart';
import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/pages/sudoku_home_page.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
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
          title: 'Welcome to Sudoku!',
          body:
              "Fill the grid so every \"Unit\" contains 1–9 without repeats. No math degree required - Auto Sudoku makes it simple! Let's get started!",
          centerDialog: true,
        ),
        TutorialStep(
          maskRows: {4},
          maskCols: {3},
          maskBoxes: {4},
          title: 'What is a Unit?',
          body:
              "A unit is a row, a column, or a 3×3 box. Each unit must contain the digits 1–9 exactly once without repeats.",
        ),
        TutorialStep(
          maskRows: {4},
          title: 'Rows',
          body:
              'Each row is a unit. The numbers 1–9 may only appear once across the row.',
        ),
        TutorialStep(
          maskCols: {3},
          title: 'Columns',
          body:
              'Each column is also a unit. The numbers 1–9 may only appear once vertically.',
        ),
        TutorialStep(
          maskBoxes: {4},
          title: '3×3 Boxes',
          body:
              'Each 3×3 box is a unit. Make sure each digit 1–9 appears exactly once within each box.',
        ),
        TutorialStep(
          title: 'Selection Tip',
          body:
              'When you select a filled-in cell, the cells that cannot contain that value are softly greyed out. It helps your eyes focus where that number could go. Give it a shot!',
          // Allow selection anywhere on the grid for this step
          maskRows: {0, 1, 2, 3, 4, 5, 6, 7, 8},
          preventGridTaps: false,
        ),
        // Hidden Single mini-lesson
        TutorialStep(
          title: 'Tap a 2',
          body:
              'Tap any cell that already contains a 2. We\'ll use it to spot something sneaky.',
          expectSelectValue: 2,
          selectedIndices: {},
          maskIndices: {3, 15, 29, 44, 50, 64},
          preventGridTaps: false,
        ),
        TutorialStep(
          maskBoxes: {0},
          title: 'Hidden Single',
          body:
              "Spot the standout? Only one cell stays lit in this box—that's a hidden single. 2s in other boxes block the rest, so this 3×3 box has exactly one home for the 2.",
        ),
        TutorialStep(
          maskIndices: {18},
          preventGridTaps: false,
          title: 'Auto Hidden Single',
          body:
              "See it? Tap the lone cell and Auto Sudoku fills it instantly — quick, easy, satisfying. Give it a tap!",
          solverSettings: SolverSettings(allowed: {StrategyType.hiddenSingle}),
        ),
        TutorialStep(
          preventGridTaps: false,
          title: 'Complete the Puzzle!',
          body:
              "Hidden Singles are just the beginning! Use them to finish this puzzle. Pro tip: tap filled cells to gray out the rest and spot more singles.",
          solverSettings: SolverSettings(allowed: {StrategyType.hiddenSingle}),
          maskRows: {0, 1, 2, 3, 4, 5, 6, 7, 8},
        ),
      ],
      onDone: () {
        // Restore default solver behavior once tutorial finishes
        final board = context.read<SudokuBoardState>();
        board.applyTutorialSolverSettings(SolverSettings.all());
        setState(() => _showTutorial = false);
      },
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SudokuBoardState>(
          create: (_) {
            final board = SudokuBoardState(
              showNotes: false,
              autoFinish: false,
              autoSingle: false,
            );
            board.requestInitPuzzle(widget.model);
            return board;
          },
        ),
        if (_controller != null)
          ChangeNotifierProvider<TutorialController>.value(value: _controller!),
      ],
      child: SudokuHomePage(
        tutorialOverlay: _showTutorial && _controller != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  GridMaskOverlay(controller: _controller!),
                  CenterDialogOverlay(controller: _controller!),
                ],
              )
            : null,
        tutorialPanelOverlay: _showTutorial && _controller != null
            ? AnimatedBuilder(
                animation: _controller!,
                builder: (context, _) => _controller!.current.centerDialog
                    ? const SizedBox.shrink()
                    : TutorialPanel(controller: _controller!),
              )
            : null,
      ),
    );
  }
}
