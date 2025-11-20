// import 'package:auto_sudoku/data/shared_prefs.dart';
import 'package:auto_sudoku/data/lesson.dart';
import 'package:auto_sudoku/data/lessons.dart';
import 'package:flutter/material.dart';
import 'package:auto_sudoku/ui/pages/lesson_track_page.dart';
import 'package:auto_sudoku/state/lesson_progress.dart';
import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

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
  final AnimationController controller;
  final ScrollController scrollController;

  const _JourneyTrack({
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
        final lesson = Lessons.all[index];
        final alignLeft = index.isEven; // Zig-zag left / right

        final curved = CurvedAnimation(
          parent: controller,
          curve: Interval(
            (index * 0.10).clamp(0.0, 1.0),
            (0.55 + index * 0.16).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        );
        // Shared provider is above; compute status using the multi-lesson API
        final progress = context.watch<LessonProgress>();
        final status = !progress.isPrereqDone(lesson)
            ? LessonStatus.locked
            : (progress.isDone(lesson)
                  ? LessonStatus.completed
                  : LessonStatus.inProgress);
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
                  child: Builder(
                    builder: (innerCtx) => _LessonNode(
                      lesson: lesson,
                      alignLeft: alignLeft,
                      color: _paletteForIndex(colors, index),
                      onTap: () => _openLessonTrack(innerCtx, lesson),
                      status: status,
                    ),
                  ),
                ),

                if (alignLeft) const Spacer(),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 22),
      itemCount: Lessons.all.length,
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
  final Lesson lesson;
  final bool alignLeft;
  final Color color;
  final VoidCallback onTap;
  final LessonStatus status;

  const _LessonNode({
    required this.lesson,
    required this.alignLeft,
    required this.color,
    required this.onTap,
    required this.status,
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

    final locked = status == LessonStatus.locked;
    final comingSoon = status == LessonStatus.comingSoon;
    final completed = status == LessonStatus.completed;

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
                      lesson.shortDesc,
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

void _openLessonTrack(BuildContext context, Lesson lesson) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (innerCtxt, animation, secondaryAnimation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        // Re-use the existing LessonProgress created above this node
        final progress = context.read<LessonProgress>();
        return ChangeNotifierProvider<LessonProgress>.value(
          value: progress,
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: LessonTrackPage(lesson: lesson),
            ),
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
