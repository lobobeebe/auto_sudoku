import 'package:auto_sudoku/state/board_mode.dart';
import 'package:auto_sudoku/ui/widgets/error_panel.dart';
import 'package:flutter/material.dart';

class ErrorMode extends BoardMode {
  final String? error;
  const ErrorMode(super.board, this.error);

  @override
  String get name => "Error";

  @override
  Widget? buildBodyOverride(BuildContext context) => ErrorPanel(
    key: const ValueKey('error'),
    message: error ?? "Unknown Error",
    onReturn: () => Navigator.pop(context),
  );

  @override
  bool allowUndo() => false;

  @override
  bool allowRequestHint() => false;

  @override
  bool allowControls() => false;
}
