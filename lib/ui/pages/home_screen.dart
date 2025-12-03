import 'package:auto_sudoku/data/puzzle_repository.dart';
import 'package:auto_sudoku/state/lesson_progress.dart';
import 'package:auto_sudoku/ui/pages/difficulty_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:auto_sudoku/ui/utils/feedback.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final repository = context.watch<PuzzleRepository>();
    final isLoadingRepo = repository.isLoading && !repository.isLoaded;
    final hasError = repository.error != null && !repository.isLoaded;
    final errorMessage = repository.error;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primaryContainer, colorScheme.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 40,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onLongPress: () => _debugResetProgress(context),
                          child: Icon(
                            Icons.grid_view_rounded,
                            size: 64,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Auto Sudoku',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Relax, solve, and let smart notes assist you along the way.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Column(
                            children: [
                              if (isLoadingRepo)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: CircularProgressIndicator.adaptive(),
                                ),
                              if (hasError) ...[
                                Text(
                                  'We couldn\'t load puzzles just yet.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (errorMessage != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    errorMessage,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.error,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Try Again'),
                                  onPressed: () {
                                    repository.preload();
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Free Play'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            textStyle: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: repository.isLoaded
                              ? () => _openDifficultySelection(context)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _openDifficultySelection(BuildContext context) {
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
            child: const DifficultySelectionPage(),
          ),
        );
      },
    ),
  );
}

Future<void> _debugResetProgress(BuildContext context) async {
  if (!kDebugMode) return;

  context.read<LessonProgress>().resetAll();
  showToast(
    context,
    Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.restart_alt_rounded),
        SizedBox(width: 10),
        Text('Progress & Preferences reset.'),
      ],
    ),
  );
}
