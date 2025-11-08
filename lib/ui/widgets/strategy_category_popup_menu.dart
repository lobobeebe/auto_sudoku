import 'package:flutter/material.dart';

/// Categories shown in the popup.
enum StrategyCategory { nakedHidden, locked, wings, coloring, advanced }

extension StrategyCategoryX on StrategyCategory {
  String get label => switch (this) {
    StrategyCategory.nakedHidden => 'Naked/Hidden',
    StrategyCategory.locked => 'Locked',
    StrategyCategory.wings => 'Wings',
    StrategyCategory.coloring => 'Coloring',
    StrategyCategory.advanced => 'Advanced',
  };

  IconData get icon => switch (this) {
    StrategyCategory.nakedHidden => Icons.auto_awesome_mosaic_rounded,
    StrategyCategory.locked => Icons.lock_rounded,
    StrategyCategory.wings => Icons.auto_awesome_rounded,
    StrategyCategory.coloring => Icons.palette_rounded,
    StrategyCategory.advanced => Icons.rocket_launch_rounded,
  };
}

/// 1) Drop-in button that behaves like PopupMenuButton<StrategyCategory>.
/// Use this when you already have a button/icon and just want a popup on tap.
class StrategyPopupMenuButton extends StatelessWidget {
  const StrategyPopupMenuButton({
    super.key,
    this.currentValue,
    this.onSelected,
    this.onCanceled,
    this.icon,
    this.enabled,
    this.tooltip = 'Select strategy category',
    this.items = const [
      StrategyCategory.nakedHidden,
      StrategyCategory.locked,
      StrategyCategory.wings,
      // StrategyCategory.coloring,
      // StrategyCategory.advanced,
    ],
    this.shape,
  });

  final StrategyCategory? currentValue;
  final ValueChanged<StrategyCategory>? onSelected;
  final VoidCallback? onCanceled;
  final Icon? icon;
  final bool? enabled;
  final String tooltip;
  final List<StrategyCategory> items;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = currentValue;
    final isEnabled = (enabled ?? true) && onSelected != null;

    return PopupMenuButton<StrategyCategory>(
      tooltip: tooltip,
      initialValue: currentValue,
      enabled: isEnabled,
      onSelected: onSelected,
      onCanceled: onCanceled,
      elevation: 8,
      color: scheme.surfaceContainerHighest,
      shape:
          shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: scheme.outlineVariant.withOpacity(.35)),
          ),
      itemBuilder: (context) => [
        for (final c in items)
          PopupMenuItem<StrategyCategory>(
            value: c,
            child: Row(
              children: [
                Icon(c.icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(
                  c.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
      child: IconButton.filledTonal(onPressed: () {}, icon: icon ?? SizedBox()),
      // child: selected != null
      //     ? _SelectedCategoryChip(category: selected, isEnabled: isEnabled)
      //     : (icon ??
      //           Icon(
      //             Icons.tune_rounded,
      //             color: scheme.primaryContainer,
      //             size: 22,
      //           )),
    );
  }
}

/// Small utility to compute an anchor rect from a widget context.
RelativeRect menuPositionFor(BuildContext context) {
  final box = context.findRenderObject() as RenderBox;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
  final target = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  return RelativeRect.fromRect(target, Offset.zero & overlay.size);
}

class _SelectedCategoryChip extends StatelessWidget {
  const _SelectedCategoryChip({
    required this.category,
    required this.isEnabled,
  });
  final StrategyCategory category;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = isEnabled
        ? scheme.primaryContainer
        : theme.disabledColor.withOpacity(0.1);
    final fg = isEnabled
        ? scheme.onSurfaceVariant
        : scheme.onSurface.withOpacity(0.46);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 24, color: fg),
          // const SizedBox(width: 8),
          // Text(
          //   category.label,
          //   style: TextStyle(
          //     fontWeight: FontWeight.w600,
          //     fontSize: 14,
          //     color: fg,
          //   ),
          // ),
        ],
      ),
    );
  }
}
