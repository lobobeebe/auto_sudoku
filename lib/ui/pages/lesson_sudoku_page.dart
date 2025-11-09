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
              "Fill each row, column, and 3×3 box with 1–9—no repeats. No math degree needed; Auto Sudoku keeps it fun!",
          centerDialog: true,
        ),
        TutorialStep(
          maskRows: {4},
          maskCols: {3},
          maskBoxes: {4},
          title: 'What is a Unit?',
          body:
              "A unit is a row, column, or 3×3 box. Each must contain 1–9 exactly once—no repeats.",
        ),
        TutorialStep(
          maskRows: {4},
          title: 'Rows',
          body:
              'Each row is a unit. Digits 1–9 can appear only once across the row.',
        ),
        TutorialStep(
          maskCols: {3},
          title: 'Columns',
          body:
              'Each column is a unit. Digits 1–9 can appear only once vertically.',
        ),
        TutorialStep(
          maskBoxes: {4},
          title: '3×3 Boxes',
          body:
              'Each 3×3 box is a unit. Make sure digits 1–9 appear exactly once inside.',
        ),
        TutorialStep(
          title: 'Selection Tip',
          body:
              'Tap a filled cell and we softly gray out where that number can’t go — perfect for focusing your search. Give it a try!',
          // Allow selection anywhere on the grid for this step
          maskRows: {0, 1, 2, 3, 4, 5, 6, 7, 8},
          preventGridTaps: false,
        ),
        // Hidden Single mini-lesson
        TutorialStep(
          title: 'Tap a 2',
          body: 'Tap any filled 2 — we’ll use it to spot something sneaky.',
          advanceOnValue: 2,
          selectedIndices: {},
          maskIndices: {3, 15, 29, 44, 50, 64},
          preventGridTaps: false,
        ),
        TutorialStep(
          maskBoxes: {0},
          maskCols: {1, 2},
          maskRows: {0, 1},
          preventGridTaps: false,
          tappableIndices: {18},
          solverSettings: SolverSettings(allowed: {StrategyType.hiddenSingle}),
          advanceOnIndices: {18},
          title: 'Hidden Single',
          body:
              "Spot the standout? Only one cell stays lit in the top-left box — a hidden single. 2s in the lit rows and columns block the rest, so there’s exactly one home for the 2. Give it a tap!",
        ),
        TutorialStep(
          maskBoxes: {0},
          maskCols: {1, 2},
          maskRows: {0, 1},
          title: 'First Hidden Single Done!',
          body:
              "Nice job! We've filled in the 2 in this box - let's keep looking for more.",
        ),
        TutorialStep(
          maskRows: {8},
          preventGridTaps: false,
          title: 'Next Hidden Single',
          body: "Spot another lonely home for a 2 in this row? Give it a tap!",
          solverSettings: SolverSettings(allowed: {StrategyType.hiddenSingle}),
          advanceOnIndices: {79},
          tappableIndices: {79},
        ),
        TutorialStep(
          maskCols: {4},
          preventGridTaps: false,
          title: 'Last Hidden Single',
          body:
              "This column has one cozy spot left for a 2 — finish the set by tapping it!",
          solverSettings: SolverSettings(allowed: {StrategyType.hiddenSingle}),
          advanceOnIndices: {58},
          tappableIndices: {58},
        ),
        TutorialStep(
          preventGridTaps: false,
          centerDialog: true,
          title: 'Complete the Puzzle',
          body:
              "Hidden Singles are just the beginning! Use them to finish this puzzle. Pro tip: tap filled cells to gray out the rest and spot more singles.",
          solverSettings: SolverSettings(allowed: {StrategyType.hiddenSingle}),
        ),
      ],
      onDone: () {
        // Restore default solver behavior once tutorial finishes
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
