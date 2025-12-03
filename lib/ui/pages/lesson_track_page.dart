import 'package:auto_sudoku/data/lesson.dart';
import 'package:auto_sudoku/data/puzzle_repository.dart';
import 'package:auto_sudoku/state/lesson_progress.dart';
import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/pages/sudoku_home_page.dart';
import 'package:auto_sudoku/ui/widgets/puzzle_icon_button.dart';
import 'package:auto_sudoku/ui/widgets/tutorial_overlay.dart';
import 'package:auto_sudoku/ui/widgets/background_orb.dart';
import 'package:auto_sudoku/ui/widgets/common_container.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class LessonTrackPage extends StatefulWidget {
  final Lesson lesson;
  const LessonTrackPage({super.key, required this.lesson});

  @override
  State<LessonTrackPage> createState() => _LessonTrackPageState();
}

class _LessonTrackPageState extends State<LessonTrackPage> {
  late final Future<List<SudokuModel>> _puzzleFuture;

  @override
  void initState() {
    super.initState();

    _puzzleFuture = context.read<PuzzleRepository>().loadAssetFile(
      widget.lesson.path,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Build the page content once. Provider must exist above this widget.
    final page = Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primaryContainer.withValues(alpha: 0.30),
                    colors.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -30,
            child: BackgroundOrb(color: colors.primary, size: 200),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: BackgroundOrb(color: colors.secondaryContainer, size: 220),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton.filled(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.lesson.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.lesson.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: FutureBuilder<List<SudokuModel>>(
                      future: _puzzleFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator.adaptive(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'Could not load lesson puzzles:\n${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.error,
                                ),
                              ),
                            ),
                          );
                        }
                        final puzzles = snapshot.data ?? const <SudokuModel>[];
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          context.read<LessonProgress>().setTotal(
                            widget.lesson,
                            puzzles.length,
                          );
                        });
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: CommonContainer(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 18,
                                runSpacing: 18,
                                children: [
                                  for (int i = 0; i < puzzles.length; i++)
                                    _animatedIcon(context, i, puzzles[i]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildProgressChip(context, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return page;
  }

  Widget _buildIcon(BuildContext context, int index, SudokuModel model) {
    final prog = context.watch<LessonProgress>().progressFor(widget.lesson);
    final completed = index < prog;
    final isCurrent = index == prog;
    final locked = index > prog;

    final state = completed
        ? PuzzleIconState.completed
        : (isCurrent ? PuzzleIconState.current : PuzzleIconState.locked);

    return PuzzleIconButton(
      number: index + 1,
      state: state,
      onTap: locked ? null : () => _openPuzzle(context, index, model),
    );
  }

  Widget _animatedIcon(BuildContext context, int index, SudokuModel model) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.90, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: _buildIcon(context, index, model),
    );
  }

  Widget _buildProgressChip(BuildContext context, ThemeData theme) {
    final colors = theme.colorScheme;
    final progress = context.watch<LessonProgress>().progressFor(widget.lesson);
    final total = context.watch<LessonProgress>().totalFor(widget.lesson);
    return InkWell(
      onLongPress: kDebugMode
          ? () async {
              await context.read<LessonProgress>().markAllCompleteForDebug(
                widget.lesson,
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              '$progress/$total',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPuzzle(
    BuildContext context,
    int index,
    SudokuModel model,
  ) async {
    // If the model includes tutorial steps, construct a TutorialController
    // and provide it before opening the puzzle so SudokuHomePage can show it.
    final hasTutorial = model.tutorial != null;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<SudokuBoardState>(
                create: (_) {
                  final state = SudokuBoardState(
                    showNotes:
                        widget.lesson.showNotes ??
                        model.tutorial?.overrideShowNotes,
                  );
                  state.requestInitPuzzle(model);

                  return state;
                },
              ),
              if (hasTutorial)
                ChangeNotifierProvider<TutorialController>(
                  create: (_) => TutorialController(tutorial: model.tutorial!),
                ),
            ],
            child: const SudokuHomePage(),
          );
        },
      ),
    );
    if (result == true) {
      await context.read<LessonProgress>().markSolvedIndex(
        widget.lesson,
        index,
      );
    }
  }
}

// Replaced list tile layout with icon grid inside CommonContainer
