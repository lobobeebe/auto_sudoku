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
      selectedCellBackground = colorScheme.primary.withValues(alpha: .5),
      selectedCellTextColor = colorScheme.onPrimaryContainer,

      // Coloring mode
      coloringPrimary = Colors.green.shade400.withValues(alpha: 0.85),
      coloringPrimaryTextColor = Colors.black,
      coloringSecondary = Colors.red.shade400.withValues(alpha: 0.85),
      coloringSecondaryTextColor = Colors.white,
      coloringPrimaryPeerBackground = Colors.green.shade100.withValues(
        alpha: 0.6,
      ),
      coloringSecondaryPeerBackground = Colors.red.shade100.withValues(
        alpha: 0.6,
      ),
      coloringMixedPeerBackground = Color.lerp(
        Colors.green.shade100,
        Colors.red.shade100,
        0.5,
      )!.withValues(alpha: 0.62),

      // Peers
      peerCellBackground = Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.15),
        colorScheme.surface,
      ),

      // Notes (Default)
      noteDefaultColor = colorScheme.onSurfaceVariant,

      // Notes (Highlight)
      noteClueTextColor = Colors.blue,
      noteEliminationTextColor = Colors.red,
      noteHighlightTextColor = colorScheme.onPrimaryContainer,

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
  final Color autoFillHighlightBackground;
  final Color valueHighlightColor;
  final Color coloringPrimary;
  final Color coloringSecondary;
  final Color coloringPrimaryTextColor;
  final Color coloringSecondaryTextColor;
  final Color coloringPrimaryPeerBackground;
  final Color coloringSecondaryPeerBackground;
  final Color coloringMixedPeerBackground;

  final Color noteDefaultColor;
  final Color noteHighlightTextColor;
  final Color noteClueTextColor;
  final Color noteEliminationTextColor;

  final Color valueRegularTextColor;
  final Color givenCellTextColor;
  final Color numberPadBackground;
  final Color numberPadForeground;
  final TextStyle numberPadTextStyle;

  // Note appearance
  final double noteDefaultScale = 1.0;
  final double noteEmphasisScale = 1.25;
  final FontWeight noteEmphasisFontWeight = FontWeight.w600;

  static SudokuTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return SudokuTheme._(theme.colorScheme, theme.textTheme);
  }
}
