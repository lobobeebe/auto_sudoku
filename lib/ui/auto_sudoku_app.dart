import 'package:auto_sudoku/data/puzzle_repository.dart';
import 'package:auto_sudoku/state/lesson_progress.dart';
import 'package:auto_sudoku/state/strategy_progress.dart';
import 'package:auto_sudoku/ui/pages/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AutoSudokuApp extends StatelessWidget {
  const AutoSudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PuzzleRepository>(
          create: (_) => PuzzleRepository()..preload(),
        ),
        ChangeNotifierProvider<LessonProgress>(
          create: (_) => LessonProgress()..loadAll(),
        ),
        ChangeNotifierProvider<StrategyProgress>(
          create: (_) => StrategyProgress()..loadAll(),
        ),
      ],
      child: MaterialApp(
        title: 'Auto Sudoku',
        theme: baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(
            displayColor: baseTheme.colorScheme.onSurface,
            bodyColor: baseTheme.colorScheme.onSurface,
          ),
          scaffoldBackgroundColor: baseTheme.colorScheme.surface,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
