import 'package:flutter/material.dart';

class _ToastHandle {
  final OverlayEntry entry;
  final AnimationController controller;
  _ToastHandle(this.entry, this.controller);
}

_ToastHandle? _activeToast;

void _dismissActiveToast() {
  final handle = _activeToast;
  if (handle != null) {
    handle.entry.remove();
    handle.controller.dispose();
  }
  _activeToast = null;
}

/// Shows a modern, animated toast near the bottom.
void showToast(
  BuildContext context,
  Widget content, {
  Duration duration = const Duration(milliseconds: 1600),
}) {
  _dismissActiveToast();

  final overlay = Overlay.of(context);

  // Use NavigatorState as a TickerProvider for vsync
  final vsync = Navigator.of(context);
  final animationController = AnimationController(
    vsync: vsync,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 180),
  );

  final curved = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  final entry = OverlayEntry(
    builder: (ctx) {
      final colors = Theme.of(ctx).colorScheme;
      return Positioned.fill(
        child: IgnorePointer(
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                // Offset below the AppBar (toolbar height) plus safe area
                // to avoid overlapping the top bar in pages that extend
                // body behind the AppBar.
                padding: EdgeInsets.only(
                  top: MediaQuery.of(ctx).padding.top + 12,
                ),
                child: FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: curved.drive(
                      Tween<Offset>(
                        begin: const Offset(0, -0.15),
                        end: Offset.zero,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: DefaultTextStyle(
                          style:
                              Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ) ??
                              const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                          child: content,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  final handle = _ToastHandle(entry, animationController);
  _activeToast = handle;
  animationController.forward();

  Future.delayed(duration, () async {
    // Only dismiss if this handle is still the active one
    if (identical(_activeToast, handle)) {
      try {
        await animationController.reverse();
      } catch (_) {}
      _dismissActiveToast();
    }
  });
}

void showHintToast(BuildContext context, String strategyName) {
  final colors = Theme.of(context).colorScheme;
  showToast(
    context,
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, color: colors.primary),
        const SizedBox(width: 10),
        Text(strategyName),
      ],
    ),
  );
}

void showUnlockToast(BuildContext context, String strategyName) {
  final colors = Theme.of(context).colorScheme;
  showToast(
    context,
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_open_rounded, color: colors.primary),
        const SizedBox(width: 10),
        Flexible(child: Text('$strategyName auto-solve unlocked!')),
      ],
    ),
    duration: const Duration(milliseconds: 2800),
  );
}
