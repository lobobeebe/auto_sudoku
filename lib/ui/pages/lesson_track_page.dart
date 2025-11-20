import 'package:auto_sudoku/data/puzzle_repository.dart';
import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku/ui/pages/learning_journey_page.dart';
import 'package:auto_sudoku/ui/pages/sudoku_home_page.dart';
import 'package:auto_sudoku/ui/widgets/puzzle_icon_button.dart';
import 'package:auto_sudoku/ui/widgets/tutorial_overlay.dart';
import 'package:auto_sudoku/ui/widgets/background_orb.dart';
import 'package:auto_sudoku/ui/widgets/common_container.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonTrackPage extends StatefulWidget {
  final Lesson lesson;

  const LessonTrackPage({super.key, required this.lesson});

  @override
  State<LessonTrackPage> createState() => _LessonTrackPageState();
}

class _LessonTrackPageState extends State<LessonTrackPage> {
  late Future<List<SudokuModel>> _future;
  int _progress = 0; // number of puzzles completed

  @override
  void initState() {
    super.initState();
    _loadProgress();
    final repo = context.read<PuzzleRepository>();

    _future = repo.loadAssetFile(widget.lesson.path);
  }

  String get _prefsKey => '${_slug(widget.lesson.title)}_completed';

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _progress = prefs.getInt(_prefsKey) ?? 0);
  }

  Future<void> _saveProgress(int next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, next);
    setState(() => _progress = next);
  }

  static String _slug(String input) => input
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
      .replaceAll(RegExp(r"_+"), '_')
      .replaceAll(RegExp(r"^_+|_+$"), '');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
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
                      future: _future,
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
                                    _animatedIcon(i, puzzles[i]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildProgressChip(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(int index, SudokuModel model) {
    final completed = index < _progress;
    final isCurrent = index == _progress;
    final locked = index > _progress;

    final state = completed
        ? PuzzleIconState.completed
        : (isCurrent ? PuzzleIconState.current : PuzzleIconState.locked);

    return PuzzleIconButton(
      number: index + 1,
      state: state,
      onTap: locked ? null : () => _openPuzzle(index, model),
    );
  }

  Widget _animatedIcon(int index, SudokuModel model) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.90, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: _buildIcon(index, model),
    );
  }

  Widget _buildProgressChip(ThemeData theme) {
    final colors = theme.colorScheme;
    return Container(
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
            '$_progress/TODO',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPuzzle(int index, SudokuModel model) async {
    // If the model includes tutorial steps, construct a TutorialController
    // and provide it before opening the puzzle so SudokuHomePage can show it.
    final hasTutorial = model.tutorial != null && model.tutorial!.isNotEmpty;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<SudokuBoardState>(
                create: (_) =>
                    SudokuBoardState(showNotes: false, autoFinish: false)
                      ..requestInitPuzzle(model),
              ),
              if (hasTutorial)
                ChangeNotifierProvider<TutorialController>(
                  create: (_) => TutorialController(
                    steps: [
                      for (final m in model.tutorial!) TutorialStep.fromJson(m),
                    ],
                  ),
                ),
            ],
            child: const SudokuHomePage(),
          );
        },
      ),
    );
    if (result == true) {
      final next = (_progress >= index + 1) ? _progress : index + 1;
      await _saveProgress(next);
    }
  }
}

// Replaced list tile layout with icon grid inside CommonContainer
