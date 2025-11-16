import 'package:flutter/material.dart';

class ResultDialog extends StatelessWidget {
  final bool isWin;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final BuildContext parentContext;

  const ResultDialog({
    super.key,
    required this.isWin,
    required this.colorScheme,
    required this.textTheme,
    required this.parentContext,
  });

  static Future<void> show(BuildContext context, bool isWin) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ResultDialog(
        isWin: isWin,
        colorScheme: colorScheme,
        textTheme: textTheme,
        parentContext: context,
      ),
    );
  }

  @override
  Widget build(BuildContext dialogContext) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(
            isWin ? Icons.emoji_events_rounded : Icons.error_outline_rounded,
            color: isWin ? colorScheme.primary : colorScheme.error,
          ),
          const SizedBox(width: 12),
          Text(isWin ? 'Puzzle Complete!' : 'Incorrect Move'),
        ],
      ),
      content: Text(
        isWin
            ? 'Great job! You solved the puzzle.'
            : 'That entry conflicts with the solution. Undo the move or exit to the menu.',
        style: textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Review'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            // Pop the puzzle page and return whether the puzzle was won
            Navigator.of(parentContext).pop(isWin);
          },
          child: const Text('Exit'),
        ),
      ],
    );
  }
}
