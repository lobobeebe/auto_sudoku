import 'package:auto_sudoku/state/sudoku_board_state.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StrategySettingsPage extends StatefulWidget {
  const StrategySettingsPage({super.key});

  @override
  State<StrategySettingsPage> createState() => _StrategySettingsPageState();
}

class _StrategySettingsPageState extends State<StrategySettingsPage> {
  late bool _enabled;
  late Set<StrategyType> _selected;

  @override
  void initState() {
    super.initState();
    // Try to read from an existing board if available, otherwise from storage.
    SudokuBoardState? board;
    try {
      board = context.read<SudokuBoardState>();
    } catch (_) {}
    if (board != null) {
      _enabled = board.autoStrategyOverrideEnabled;
      _selected = {...board.autoAllowedStrategies};
    } else {
      _enabled = false;
      _selected = {};
      _loadFromStorage();
    }
  }

  void _applyToBoard() {
    SudokuBoardState? board;
    try {
      board = context.read<SudokuBoardState>();
    } catch (_) {}
    if (board != null) {
      board.setAutoStrategiesEnabled(_enabled);
      board.updateAutoAllowedStrategies(_selected);
    } else {
      // Persist directly if no board in context
      _saveToStorage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Solver Strategies'),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _enabled = false;
                // When disabled, UI reflects defaults
                _selected = _defaultStrategies();
              });
              _applyToBoard();
            },
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Card(
            child: SwitchListTile.adaptive(
              title: const Text('Enable custom auto-solver strategies'),
              subtitle: const Text(
                'When enabled, automatic solving uses only selected techniques.',
              ),
              value: _enabled,
              onChanged: (v) {
                setState(() => _enabled = v);
                _applyToBoard();
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: _buildStrategyToggles(theme),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilledButton.icon(
              onPressed: () {
                _applyToBoard();
                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Apply'),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Close'),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Note: Tutorial steps override strategy settings while active.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStrategyToggles(ThemeData theme) {
    // Present a curated order matching solver.strategyOrder
    final strategies = <(String, StrategyType)>[
      ('Naked Single', StrategyType.nakedSingle),
      ('Hidden Single', StrategyType.hiddenSingle),
      ('Naked Pair', StrategyType.nakedPair),
      ('Naked Triple', StrategyType.nakedTriple),
      ('Naked Quad', StrategyType.nakedQuad),
      ('Locked Candidates (Claiming)', StrategyType.claiming),
      ('Locked Candidates (Pointing)', StrategyType.pointing),
      ('Hidden Pair', StrategyType.hiddenPair),
      ('Hidden Triple', StrategyType.hiddenTriple),
      ('Hidden Quad', StrategyType.hiddenQuad),
      ('X-Wing', StrategyType.xWing),
      ('XY-Wing', StrategyType.xyWing),
      ('W-Wing', StrategyType.wWing),
    ];

    return [
      for (final entry in strategies)
        CheckboxListTile(
          title: Text(entry.$1),
          value: _selected.contains(entry.$2),
          onChanged: _enabled
              ? (v) {
                  setState(() {
                    if (v == true) {
                      _selected.add(entry.$2);
                    } else {
                      _selected.remove(entry.$2);
                    }
                  });
                  _applyToBoard();
                }
              : null,
        ),
    ];
  }

  // --- Persistence when no board present -----------------------------------
  static const _prefsKeyEnabled = 'solver_override_enabled';
  static const _prefsKeyAllowed = 'solver_allowed_strategies';

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_prefsKeyEnabled) ?? false;
      final list = prefs.getStringList(_prefsKeyAllowed);
      Set<StrategyType> strategies = _defaultStrategies();
      if (list != null) {
        final indices = list
            .map((s) => int.tryParse(s))
            .whereType<int>()
            .where((i) => i >= 0 && i < StrategyType.values.length)
            .toList();
        strategies = {for (final i in indices) StrategyType.values[i]};
      }
      setState(() {
        _enabled = enabled;
        _selected = strategies;
      });
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyEnabled, _enabled);
      final list = _selected.map((e) => e.index.toString()).toList();
      await prefs.setStringList(_prefsKeyAllowed, list);
    } catch (_) {}
  }

  Set<StrategyType> _defaultStrategies() => const {
        StrategyType.nakedSingle,
        StrategyType.nakedPair,
        StrategyType.nakedTriple,
        StrategyType.nakedQuad,
        StrategyType.hiddenSingle,
        StrategyType.hiddenPair,
        StrategyType.hiddenTriple,
        StrategyType.hiddenQuad,
        StrategyType.pointing,
        StrategyType.claiming,
        StrategyType.xWing,
        StrategyType.xyWing,
        StrategyType.wWing,
      };
}
