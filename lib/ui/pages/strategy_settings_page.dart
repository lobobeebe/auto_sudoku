import 'package:auto_sudoku/state/strategy_progress.dart';
import 'package:auto_sudoku/ui/widgets/background_orb.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StrategySettingsPage extends StatefulWidget {
  const StrategySettingsPage({super.key});

  @override
  State<StrategySettingsPage> createState() => _StrategySettingsPageState();
}

class _StrategySettingsPageState extends State<StrategySettingsPage> {
  late final StrategyProgress _progress;

  @override
  void initState() {
    super.initState();
    _progress = context.read<StrategyProgress>();
  }

  @override
  void dispose() {
    // Clear "New" badges once the player has seen them.
    _progress.markAllSeen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = context.watch<StrategyProgress>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.35),
                    colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: BackgroundOrb(color: colorScheme.primary, size: 220),
          ),
          Positioned(
            bottom: -60,
            left: -20,
            child: BackgroundOrb(color: colorScheme.tertiary, size: 180),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Row(
                        children: [
                          IconButton.filled(
                            tooltip: 'Back',
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Auto-Solve Settings',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        children: [
                          _MasterCard(progress: progress),
                          const SizedBox(height: 8),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: progress.masterEnabled ? 1 : 0.5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final difficulty in Difficulty.values)
                                  _DifficultySection(
                                    difficulty: difficulty,
                                    progress: progress,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton.icon(
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: const Text('Reset progress'),
                              onPressed: () => _confirmReset(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'All strategies will be locked again and your move counts '
          'cleared. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _progress.resetAll();
    }
  }
}

class _MasterCard extends StatelessWidget {
  final StrategyProgress progress;

  const _MasterCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = StrategyType.values.length;
    final unlocked = progress.unlockedCount;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Auto-solve',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Switch(
                  value: progress.masterEnabled,
                  onChanged: progress.setMasterEnabled,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Let the app play the moves you have mastered. Spot a strategy '
              '${StrategyProgress.unlockThreshold} times yourself to unlock '
              'it.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: unlocked / total,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$unlocked of $total unlocked',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultySection extends StatelessWidget {
  final Difficulty difficulty;
  final StrategyProgress progress;

  const _DifficultySection({required this.difficulty, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final types = StrategyType.values
        .where((t) => t.getDifficulty() == difficulty)
        .toList();
    if (types.isEmpty) return const SizedBox.shrink();

    final label = difficulty.name.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
          child: Semantics(
            header: true,
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          color: colorScheme.surface,
          child: Column(
            children: [
              for (var i = 0; i < types.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                _StrategyRow(type: types[i], progress: progress),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StrategyRow extends StatelessWidget {
  final StrategyType type;
  final StrategyProgress progress;

  const _StrategyRow({required this.type, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unlocked = progress.isUnlocked(type);
    final count = progress.countOf(type);
    const threshold = StrategyProgress.unlockThreshold;

    if (!unlocked) {
      return Semantics(
        label: '$type, locked, $count of $threshold moves',
        button: true,
        excludeSemantics: true,
        onTap: () => _showLockedSheet(context),
        child: InkWell(
          onTap: () => _showLockedSheet(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.toString(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: count / threshold,
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$count / $threshold',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MergeSemantics(
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          children: [
            Flexible(child: Text(type.toString())),
            if (progress.isNew(type)) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'New',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        value: progress.isEnabled(type),
        onChanged: (v) => progress.setEnabled(type, v),
      ),
    );
  }

  void _showLockedSheet(BuildContext context) {
    final theme = Theme.of(context);
    final count = progress.countOf(type);
    const threshold = StrategyProgress.unlockThreshold;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Spot this strategy yourself by tapping its tiles '
                '${threshold - count} more '
                '${threshold - count == 1 ? 'time' : 'times'} to unlock '
                'auto-solve for it. Moves from the Hint button don\'t count.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
