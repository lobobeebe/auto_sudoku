import 'package:flutter/material.dart';

class PadButton extends StatelessWidget {
  const PadButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.height,
    this.padding,
    this.background,
    this.foreground,
    this.disabledBackground,
    this.borderRadius = 16,
    this.textStyle,
    this.isEnabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? background;
  final Color? foreground;
  final Color? disabledBackground;
  final double borderRadius;
  final TextStyle? textStyle;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final child = FilledButton(
      onPressed: isEnabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: disabledBackground,
        padding: padding,
        textStyle: textStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Text(label),
    );

    if (width == null && height == null) {
      return child;
    }

    return SizedBox(width: width, height: height, child: child);
  }
}
