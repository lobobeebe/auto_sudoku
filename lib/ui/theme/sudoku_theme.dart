import 'package:flutter/material.dart';

class SudokuTheme {
  SudokuTheme._(this.colorScheme, this.textTheme)
    : boardSurface = colorScheme.surface,

      // Default Cells
      valueRegularTextColor = colorScheme.onSurface,
      givenCellTextColor = Color.alphaBlend(
        colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
        colorScheme.surface.withValues(alpha: 0.28),
      ),
      valueHighlightColor = colorScheme.onPrimaryContainer,

      // Matching Values
      matchingValueBackground = colorScheme.primaryContainer,

      // Selected
      selectedCellBackground = colorScheme.primaryContainer,
      selectedCellTextColor = colorScheme.onPrimaryContainer,

      // Peers
      peerCellBackground = Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.08),
        colorScheme.surface,
      ),

      // Notes (Default)
      noteDefaultColor = colorScheme.onSurfaceVariant,

      // Notes (Highlight)
      noteHighlightBackground = Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.08),
        colorScheme.surface,
      ),
      noteHighlightTextColor = colorScheme.onPrimaryContainer,
      noteHighlightRadius = BorderRadius.circular(4),

      // Auto-Fill Animations
      autoFillHighlightBackground = Color.alphaBlend(
        colorScheme.primaryContainer.withValues(alpha: 0.45),
        colorScheme.surface,
      ),

      // Number Pad
      numberPadBackground = colorScheme.primaryContainer,
      numberPadForeground = colorScheme.onPrimaryContainer,
      numberPadTextStyle = (textTheme.titleMedium ?? const TextStyle())
          .copyWith(fontWeight: FontWeight.w600);

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  final Color boardSurface;
  final Color peerCellBackground;
  final Color selectedCellBackground;
  final Color selectedCellTextColor;
  final Color matchingValueBackground;
  final Color noteHighlightBackground;
  final Color autoFillHighlightBackground;
  final Color valueHighlightColor;
  final Color noteHighlightTextColor;
  final Color noteDefaultColor;
  final Color valueRegularTextColor;
  final Color givenCellTextColor;
  final Color numberPadBackground;
  final Color numberPadForeground;
  final TextStyle numberPadTextStyle;
  final BorderRadius noteHighlightRadius;

  static SudokuTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return SudokuTheme._(theme.colorScheme, theme.textTheme);
  }
}
