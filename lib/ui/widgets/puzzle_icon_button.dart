import 'package:flutter/material.dart';

enum PuzzleIconState { completed, current, locked }

class PuzzleIconButton extends StatelessWidget {
  final int number;
  final PuzzleIconState state;
  final VoidCallback? onTap;
  final double size;

  const PuzzleIconButton({
    super.key,
    required this.number,
    required this.state,
    this.onTap,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Color bg;
    Color fg;
    Color border;
    IconData? overlayIcon;
    Color? overlayColor;

    switch (state) {
      case PuzzleIconState.completed:
        bg = Colors.greenAccent;
        fg = Colors.green;
        border = Colors.green.withValues(alpha: 0.35);
        overlayIcon = Icons.check_rounded;
        overlayColor = colors.onSurface.withValues(alpha: 0.18);
        break;
      case PuzzleIconState.current:
        bg = colors.primaryContainer;
        fg = colors.onPrimaryContainer;
        border = colors.primary.withValues(alpha: 0.22);
        break;
      case PuzzleIconState.locked:
        bg = colors.surfaceContainerHigh;
        fg = colors.onSurfaceVariant;
        border = colors.outlineVariant.withValues(alpha: 0.30);
        overlayIcon = Icons.lock_rounded;
        overlayColor = colors.onSurface.withValues(alpha: 0.14);
        break;
    }

    final isDisabled = state == PuzzleIconState.locked || onTap == null;

    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [bg, bg.withValues(alpha: 0.82)],
                radius: 0.92,
                center: const Alignment(-0.2, -0.2),
              ),
              border: Border.all(color: border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  number.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                if (overlayIcon != null)
                  IgnorePointer(
                    child: Icon(
                      overlayIcon,
                      size: size * 0.74,
                      color: overlayColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: 'Puzzle $number ${state == PuzzleIconState.locked ? "locked" : ""}'
          .trim(),
      child: Tooltip(
        message: 'Puzzle $number',
        child: button,
      ),
    );
  }
}
