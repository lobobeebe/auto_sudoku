import 'dart:convert';
import 'dart:io';

import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

void main(List<String> args) {
  String inPath = 'sudoku_output.json';

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--in' && i + 1 < args.length) {
      inPath = args[++i];
    }
  }

  // Setup solver
  Solver solver = Solver(settings: SolverSettings.all());

  // Read JSON array from file
  final file = File(inPath);
  final List<dynamic> puzzleList = jsonDecode(file.readAsStringSync());
  final sudokuModels = puzzleList.map((str) => SudokuModel.fromJson(str));

  for (SudokuModel model in sudokuModels) {
    Sudoku s = Sudoku.fromString(model.puzzle);
    SolveResult result = solver.solveLogical(s);

    if (!result.solved) {
      print("Stuck on puzzle: ${model.toData()}");
    }
  }
}
