import 'package:flutter/material.dart';
import 'package:auto_sudoku/data/sudoku_model.dart';
import 'package:auto_sudoku/ui/pages/lesson_sudoku_page.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

class LearningJourneyPage extends StatefulWidget {
  const LearningJourneyPage({super.key});

  @override
  State<LearningJourneyPage> createState() => _LearningJourneyPageState();
}

class _LearningJourneyPageState extends State<LearningJourneyPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  final ScrollController _scrollController = ScrollController();

  final List<_Lesson> _lessons = const [
    _Lesson(
      title: 'Auto Sudoku Basics',
      icon: Icons.grid_on_rounded,
      description: 'Understand how numbers fit in rows and columns.',
      status: LessonStatus.completed,
      colorIndex: 0,
    ),
    _Lesson(
      title: 'Hidden Singles',
      icon: Icons.visibility_rounded,
      description: 'Find the only place a number can go.',
      status: LessonStatus.inProgress,
      colorIndex: 1,
    ),
    _Lesson(
      title: 'Units & Candidates',
      icon: Icons.extension_rounded,
      description: 'Learn units and pencil candidates.',
      status: LessonStatus.inProgress,
      progress: 0.4,
      colorIndex: 2,
    ),
    _Lesson(
      title: 'Naked Singles',
      icon: Icons.looks_one_rounded,
      description: 'Spot cells with only one possible value.',
      status: LessonStatus.locked,
      colorIndex: 3,
    ),
    _Lesson(
      title: 'Locked Candidates',
      icon: Icons.lock_rounded,
      description: 'Reduce possibilities using locked candidate rules.',
      status: LessonStatus.locked,
      colorIndex: 4,
    ),
    _Lesson(
      title: 'Pairs & Triples',
      icon: Icons.all_inclusive_rounded,
      description: 'Use naked/hidden pairs and triples to advance.',
      status: LessonStatus.locked,
      colorIndex: 5,
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

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
                    colors.primaryContainer.withValues(alpha: 0.35),
                    colors.surface,
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
            child: _BlurOrb(color: colors.primary, size: 220),
          ),
          Positioned(
            bottom: -60,
            left: -20,
            child: _BlurOrb(color: colors.tertiary, size: 180),
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
                        'Learning Journey',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Master Sudoku step by step. Complete lessons to unlock the next.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _JourneyTrack(
                      lessons: _lessons,
                      controller: _controller,
                      scrollController: _scrollController,
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
}

class _JourneyTrack extends StatelessWidget {
  final List<_Lesson> lessons;
  final AnimationController controller;
  final ScrollController scrollController;

  const _JourneyTrack({
    required this.lessons,
    required this.controller,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView.separated(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32, top: 12),
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        final alignLeft = index.isEven; // Zig-zag left / right
        final curved = CurvedAnimation(
          parent: controller,
          curve: Interval(
            (index * 0.10).clamp(0.0, 1.0),
            (0.55 + index * 0.16).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(alignLeft ? -0.05 : 0.05, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: Row(
              children: [
                if (!alignLeft) const Spacer(),
                Flexible(
                  flex: 14,
                  child: _LessonNode(
                    lesson: lesson,
                    alignLeft: alignLeft,
                    color: _paletteForIndex(colors, lesson.colorIndex),
                    onTap: () {
                      if (index == 0) {
                        _openLesson1(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${lesson.title}" coming soon'),
                          ),
                        );
                      }
                    },
                  ),
                ),
                if (alignLeft) const Spacer(),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 22),
      itemCount: lessons.length,
    );
  }

  Color _paletteForIndex(ColorScheme colors, int i) {
    final options = <Color>[
      colors.primary,
      colors.secondary,
      colors.tertiary,
      colors.error,
      colors.primaryContainer,
      colors.secondaryContainer,
    ];
    return options[i % options.length];
  }
}

class _LessonNode extends StatelessWidget {
  final _Lesson lesson;
  final bool alignLeft;
  final Color color;
  final VoidCallback onTap;

  const _LessonNode({
    required this.lesson,
    required this.alignLeft,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final bgGradient = LinearGradient(
      colors: [
        color.withValues(alpha: 0.12),
        colors.surfaceContainerHighest.withValues(alpha: 0.75),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final locked = lesson.status == LessonStatus.locked;
    final comingSoon = lesson.status == LessonStatus.comingSoon;
    final inProgress = lesson.status == LessonStatus.inProgress;
    final completed = lesson.status == LessonStatus.completed;

    return InkWell(
      onTap: (locked || comingSoon) ? null : onTap,
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: bgGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14),
                  border: Border.all(
                    color: color.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(lesson.icon, size: 28, color: color),
                    if (inProgress)
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          value: lesson.progress,
                          strokeWidth: 3,
                          color: color,
                          backgroundColor: colors.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    if (completed)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: colors.secondary,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            lesson.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: (locked || comingSoon)
                                  ? theme.disabledColor
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lesson.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: (locked || comingSoon)
                            ? theme.disabledColor
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                locked
                    ? Icons.lock_rounded
                    : comingSoon
                    ? Icons.schedule
                    : Icons.chevron_right_rounded,
                color: (locked || comingSoon)
                    ? theme.disabledColor
                    : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openLesson1(BuildContext context) {
  const puzzle =
      '000250001900730208000109400002576804749813652508942300097605000300497006600380000';
  const solution =
      '476258931915734268283169475132576894749813652568942317897625143321497586654381729';

  final model = SudokuModel(
    puzzle: puzzle,
    solution: solution,
    difficulty: Difficulty.easy,
    techniques: const ['Naked Single', 'Hidden Single'],
  );

  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, animation, secondaryAnimation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: LessonSudokuPage(model: model, showUnitTutorialOnOpen: true),
          ),
        );
      },
    ),
  );
}

class _BlurOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _BlurOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.25),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: size * 0.6,
            spreadRadius: size * 0.18,
          ),
        ],
      ),
    );
  }
}

enum LessonStatus { completed, inProgress, locked, comingSoon }

class _Lesson {
  final String title;
  final String description;
  final IconData icon;
  final LessonStatus status;
  final double progress; // 0..1 if inProgress
  final int colorIndex;

  const _Lesson({
    required this.title,
    required this.icon,
    required this.description,
    required this.status,
    this.progress = 0.0,
    this.colorIndex = 0,
  });
}
