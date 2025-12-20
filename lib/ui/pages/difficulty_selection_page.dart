import 'package:auto_sudoku/data/puzzle_repository.dart';
import 'package:auto_sudoku/state/lesson_progress.dart';
import 'package:auto_sudoku/ui/pages/sudoku_home_page.dart';
import 'package:auto_sudoku/ui/widgets/background_orb.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DifficultySelectionPage extends StatefulWidget {
  const DifficultySelectionPage({super.key});

  @override
  State<DifficultySelectionPage> createState() =>
      _DifficultySelectionPageState();
}

class _DifficultySelectionPageState extends State<DifficultySelectionPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  final List<_DifficultyOption> _options = [
    _DifficultyOption(
      difficulty: Difficulty.trivial,
      title: 'Trivial',
      description: 'Singles-only puzzles to get you comfy with the basics.',
      icon: Icons.sentiment_satisfied_alt_rounded,
      strategies: [StrategyType.hiddenSingle, StrategyType.openSingle],
    ),
    _DifficultyOption(
      difficulty: Difficulty.easy,
      title: 'Easy',
      description: 'Perfect for warming up and learning the basics.',
      icon: Icons.wb_sunny_rounded,
      strategies: [
        StrategyType.openPair,
        StrategyType.hiddenPair,
        StrategyType.openTriple,
        StrategyType.hiddenTriple,
        StrategyType.openQuad,
        StrategyType.hiddenQuad,
        StrategyType.pointing,
        StrategyType.claiming,
      ],
    ),
    _DifficultyOption(
      difficulty: Difficulty.medium,
      title: 'Medium',
      description: 'A balanced challenge to keep you thinking.',
      icon: Icons.auto_awesome_rounded,
      strategies: [StrategyType.xWing, StrategyType.xyWing, StrategyType.wWing],
    ),
    _DifficultyOption(
      difficulty: Difficulty.hard,
      title: 'Hard',
      description: 'For seasoned solvers seeking a serious puzzle.',
      icon: Icons.bolt_rounded,
      enabled: false,
      strategies: [
        StrategyType.skyscraper,
        StrategyType.twoStringKite,
        StrategyType.turbotFish,
        StrategyType.uniqueRectangle,
        StrategyType.bug,
        StrategyType.remotePairs,
        StrategyType.xyChain,
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = context.watch<LessonProgress>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.35),
                    colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: BackgroundOrb(color: colorScheme.primary, size: 220),
          ),
          Positioned(
            bottom: -60,
            left: -20,
            child: BackgroundOrb(color: colorScheme.tertiary, size: 180),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton.filled(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Choose Your Challenge',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Select a difficulty to tailor the next puzzle to your mood.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        final option = _options[index];
                        final unlocked = _isUnlocked(index, progress);
                        final description = _descriptionText(
                          index,
                          progress,
                          option,
                        );
                        final curved = CurvedAnimation(
                          parent: _controller,
                          curve: Interval(
                            index * 0.12,
                            (0.55 + index * 0.18).clamp(0.0, 1.0),
                            curve: Curves.easeOutCubic,
                          ),
                        );
                        return FadeTransition(
                          opacity: curved,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(curved),
                            child: _DifficultyCard(
                              option: option,
                              unlocked: unlocked,
                              description: description,
                              onTap: () => _handleDifficultyTap(option),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pushGameWithLoader(Future<SudokuModel> Function() loader) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: SudokuHomePage(future: loader()),
            ),
          );
        },
      ),
    );
  }

  void _launchGame(Difficulty difficulty) {
    final repo = context.read<PuzzleRepository>();
    _pushGameWithLoader(() => repo.loadRandomPuzzleByDifficulty(difficulty));
  }

  Future<SudokuModel> _loadLessonPuzzle(String lessonId) {
    final repo = context.read<PuzzleRepository>();
    return repo.loadPuzzleById(lessonId);
  }

  String? _nextIncompleteLessonId(_DifficultyOption option) {
    final progress = context.read<LessonProgress>();
    return progress.getNextLessonByDifficulty(option.difficulty);
  }

  void _handleDifficultyTap(_DifficultyOption option) {
    final lessonId = _nextIncompleteLessonId(option);
    if (lessonId != null) {
      _pushGameWithLoader(() => _loadLessonPuzzle(lessonId));
      return;
    }
    _launchGame(option.difficulty);
  }

  bool _isUnlocked(int index, LessonProgress progress) {
    final option = _options[index];
    if (!option.enabled) return false;
    if (index == 0) return true;

    final previous = _options[index - 1];
    final nextLessonOfPreviousDiff = progress.getNextLessonByDifficulty(
      previous.difficulty,
    );
    return nextLessonOfPreviousDiff == null;
  }

  String _descriptionText(
    int index,
    LessonProgress progress,
    _DifficultyOption option,
  ) {
    if (!option.enabled) {
      return '${option.title} is coming soon.';
    }

    if (_isUnlocked(index, progress)) {
      return option.description;
    }

    final previous = _options[index - 1];
    final completed = progress.getNumLessonsCompleted(previous.difficulty);
    final required = progress.getNumLessonsRequired(previous.difficulty);
    return '($completed/$required) Complete $required ${previous.title} puzzles to unlock.';
  }
}

class _DifficultyCard extends StatefulWidget {
  final _DifficultyOption option;
  final bool unlocked;
  final String description;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.option,
    required this.unlocked,
    required this.description,
    required this.onTap,
  });

  @override
  State<_DifficultyCard> createState() => _DifficultyCardState();
}

class _DifficultyCardState extends State<_DifficultyCard> {
  bool _isPressed = false;

  void _showInfoDialog() {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${widget.option.title} details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.option.description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled = widget.unlocked;
    final comingSoon = !widget.option.enabled;

    return GestureDetector(
      onTapDown: (_) {
        if (enabled) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (enabled) {
          widget.onTap();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                colorScheme.surfaceContainerLowest.withAlpha(
                  enabled ? 255 : 50,
                ),
                colorScheme.surfaceContainerHigh.withAlpha(enabled ? 255 : 50),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: colorScheme.primary.withValues(
                      alpha: enabled ? 0.1 : .05,
                    ),
                  ),
                  child: Icon(
                    comingSoon ? Icons.lock : widget.option.icon,
                    color: colorScheme.primary.withAlpha(enabled ? 255 : 50),
                    size: 34,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.option.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: enabled ? null : theme.disabledColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.info_outline_rounded,
                              color: enabled
                                  ? colorScheme.primary
                                  : theme.disabledColor,
                              size: 20,
                            ),
                            tooltip: 'View ${widget.option.title} info',
                            onPressed: enabled ? _showInfoDialog : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        comingSoon ? 'Coming soon...' : widget.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: enabled
                              ? colorScheme.onSurfaceVariant
                              : theme.disabledColor,
                        ),
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: enabled
                      ? colorScheme.onSurfaceVariant
                      : theme.disabledColor,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyOption {
  final Difficulty difficulty;
  final String title;
  final String description;
  final IconData icon;
  final bool enabled;
  final List<StrategyType> strategies;

  const _DifficultyOption({
    required this.difficulty,
    required this.title,
    required this.description,
    required this.icon,
    required this.strategies,
    this.enabled = true,
  });
}
