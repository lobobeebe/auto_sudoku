import 'package:auto_sudoku/ui/widgets/background_orb.dart';
import 'package:flutter/material.dart';

import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/widgets/sudoku_grid.dart';
import 'package:provider/provider.dart';

class SudokuHomePage extends StatelessWidget {
  final Widget? tutorialOverlay;
  // Full-width panel shown as an overlay at the bottom, above the Action Bar
  final Widget? tutorialPanelOverlay;

  const SudokuHomePage({
    super.key,
    this.tutorialOverlay,
    this.tutorialPanelOverlay,
  });

  @override
  Widget build(BuildContext context) {
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
            child: IconButton.filledTonal(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: board.allowReset() ? board.resetBoard : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(context, board),
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
        if (tutorialPanelOverlay != null)
          // Overlay panel floats above the controls/action bar
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: tutorialPanelOverlay!,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          const SudokuGrid(),
          if (tutorialOverlay != null) tutorialOverlay!,
        ],
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
