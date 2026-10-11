import 'dart:async';

import 'package:auto_sudoku/state/lesson_progress.dart';
import 'package:auto_sudoku/state/strategy_progress.dart';
import 'package:auto_sudoku/ui/widgets/background_orb.dart';
import 'package:auto_sudoku_solver/data/sudoku_model.dart';
import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/widgets/sudoku_grid.dart';
import 'package:provider/provider.dart';
import 'package:auto_sudoku/ui/widgets/tutorial_overlay.dart';

class SudokuHomePage extends StatelessWidget {
  final Future<SudokuModel> future;
  const SudokuHomePage({super.key, required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SudokuModel>(
      future: future,
      builder: (context, snapshot) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<SudokuBoardState>(
              create: (context) {
                final board = SudokuBoardState();
                board.strategyProgress = context.read<StrategyProgress>();
                board.onPuzzleWon = (puzzle) {
                  unawaited(
                    context.read<LessonProgress>().setIsDone(puzzle.id),
                  );
                };
                future
                    .then((model) {
                      board.showNotes =
                          model.tutorial?.overrideShowNotes ?? board.showNotes;
                      board.requestInitPuzzle(model);
                    })
                    .catchError((error, stackTrace) {
                      board.requestInitPuzzle(null, error: error.toString());
                    });
                return board;
              },
            ),
            if (snapshot.data?.tutorial != null)
              ChangeNotifierProvider<TutorialController>(
                create: (_) =>
                    TutorialController(tutorial: snapshot.data!.tutorial!),
              ),
          ],
          child: Builder(
            builder: (context) {
              final board = context.watch<SudokuBoardState>();
              final theme = Theme.of(context);

              board.onBuild(context);

              return Scaffold(
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  titleSpacing: 24,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Auto Sudoku'),
                      Text(
                        board.difficulty,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: board.allowReset() ? board.resetBoard : null,
                        onLongPress: board.allowReset()
                            ? board.completeBoardForDebug
                            : null,
                      ),
                    ),
                  ],
                ),
                body: _buildBody(context, board),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SudokuBoardState board) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget content =
        board.buildBodyOverride(context) ?? _buildPuzzleContent(context, board);
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          top: -72,
          right: -20,
          child: BackgroundOrb(color: colorScheme.primary, size: 220),
        ),
        Positioned(
          bottom: -80,
          left: -60,
          child: BackgroundOrb(
            color: colorScheme.secondaryContainer,
            size: 260,
          ),
        ),
        SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            child: content,
          ),
        ),
        // Overlay panel floats above the controls/action bar.
        TutorialPanel(), // Hides when no tutorial controlle present
      ],
    );
  }

  Widget _buildPuzzleContent(BuildContext context, SudokuBoardState board) {
    return ConstrainedBox(
      key: const ValueKey('puzzle'),
      constraints: const BoxConstraints(maxWidth: 1120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(child: _buildBoardCard(context)),
          _buildControlsCard(context, board),
        ],
      ),
    );
  }

  Widget _buildBoardCard(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: const Stack(
        fit: StackFit.expand,
        children: [SudokuGrid(), GridMaskOverlay()],
      ),
    );
  }

  Widget _buildControlsCard(BuildContext context, SudokuBoardState board) {
    Widget bottomBar = board.buildBottomBar();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: Padding(padding: const EdgeInsets.all(24.0), child: bottomBar),
    );
  }
}
