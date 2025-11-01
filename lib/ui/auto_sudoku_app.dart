import 'package:flutter/material.dart';

import 'package:auto_sudoku/ui/pages/home_screen.dart';

class AutoSudokuApp extends StatelessWidget {
  const AutoSudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    );

    return MaterialApp(
      title: 'Auto Sudoku',
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(
          displayColor: baseTheme.colorScheme.onSurface,
          bodyColor: baseTheme.colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: baseTheme.colorScheme.surface,
      ),
      home: HomeScreen(),
    );
  }
}
