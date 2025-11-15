import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/pages/sudoku_home_page.dart';
import 'package:auto_sudoku/ui/widgets/tutorial_overlay.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LessonNakedSinglesPage extends StatefulWidget {
  final SudokuModel model;
  const LessonNakedSinglesPage({super.key, required this.model});

  @override
  State<LessonNakedSinglesPage> createState() => _LessonNakedSinglesPageState();
}

class _LessonNakedSinglesPageState extends State<LessonNakedSinglesPage> {
  bool _showTutorial = true;
  TutorialController? _controller;

  @override
  Widget build(BuildContext context) {
    _controller ??= TutorialController(
      steps: const [
        TutorialStep(
          maskRows: {0, 1, 2, 3, 4, 5, 6, 7, 8},
          title: 'What are those smaller numbers?',
          body:
              "Those numbers are called candidates — the possible values for each empty cell. We'll use them to learn a new strategy called 'Naked Singles'.",
        ),
        TutorialStep(
          maskRows: {5},
          title: 'Hidden vs Naked Singles',
          selectedIndices: {46},
          body:
              'We\'ve already learned that Hidden Singles say "A 6 can\'t go anywhere else in this unit, so it must go here."',
        ),
        TutorialStep(
          maskRows: {2},
          maskBoxes: {1},
          maskCols: {4},
          selectedIndices: {22},
          title: 'Hidden vs Naked Singles',
          body:
              'Now we\'ll learn that Naked Singles say "Nothing except a 6 can go here because every other digit is blocked in this cell."',
        ),
        TutorialStep(
          maskRows: {2},
          maskBoxes: {1},
          maskCols: {4},
          selectedIndices: {},
          advanceOnIndices: {22},
          tappableIndices: {22},
          preventGridTaps: false,
          solverSettings: SolverSettings(allowed: {StrategyType.nakedSingle}),
          title: 'Naked Singles',
          body:
              'A Naked Single can be found quickly by findng a cell with only one candidate, like this one! Go ahead and tap the cell with the Naked Single 6 now!',
        ),

        TutorialStep(
          maskRows: {2},
          maskBoxes: {1},
          maskCols: {4},
          title: 'How to use candidates',
          body:
              "As you place numbers, candidates shrink automatically by removing impossible digits from peers. Use the left arrow button to replay the last move to see the difference once or twice before moving to the next step.",
        ),
        TutorialStep(
          centerDialog: true,
          title: 'Your turn',
          body:
              "Complete the puzzle by looking around the grid for any cell showing a single candidate and fill it in. Happy tapping!",
          solverSettings: SolverSettings(allowed: {StrategyType.nakedSingle}),
        ),
      ],
      onDone: () => setState(() => _showTutorial = false),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SudokuBoardState>(
          create: (_) {
            final board = SudokuBoardState(
              showNotes: true,
              autoFinish: false,
              autoSingle: false,
            );
            board.requestInitPuzzle(widget.model);
            // Constrain unit solver to Naked Singles during lesson by default
            board.applyTutorialSolverSettings(
              const SolverSettings(allowed: {StrategyType.nakedSingle}),
            );
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
