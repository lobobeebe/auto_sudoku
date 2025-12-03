import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

enum TutorialDialogAlignment { top, center, bottom }

class TutorialStep {
  final Set<int> maskRows;
  final Set<int> maskCols;
  final Set<int> maskBoxes;
  final Set<int> cells; // indices 0..80
  final String title;
  final String body;
  // Where to place the tutorial panel: top, center, or bottom
  // Defaults to center. Preferred over legacy [centerDialog].
  final TutorialDialogAlignment dialogAlignment;
  // If set, this step requires the user to tap a grid cell whose
  // filled-in value equals this digit; upon a valid tap, the tutorial
  // auto-advances. All other grid taps are blocked.
  final int? advanceOnValue;
  // Whether the Action Bar should be enabled during this step.
  // Defaults to false so controls are disabled unless explicitly allowed.
  final bool enableActionBar;
  // When not null, sets the current grid selection when the step becomes active.
  final Set<int>? selectedIndices;
  // When true, block all grid taps for this step regardless of highlights.
  // Defaults to true to keep the tutorial strictly guided unless opted out.
  final bool preventGridTaps;
  // Optional: explicit set of grid indices (0..80) to show/allow in the
  // mask overlay for this step. When provided, this takes precedence over
  // rows/cols/boxes/cells for visual holes and tap allowance.
  final Set<int>? maskIndices;
  // Optional: when provided, moving to the next step automatically if the
  // user taps any of these indices.
  final Set<int>? advanceOnIndices;
  // Optional: when provided, only these indices are allowed to be tapped,
  // even if the overlay/mask visually allows more. The overlay still
  // prevents taps; this list adds an extra restriction.
  final Set<int>? tappableIndices;
  // Optional per-step solver settings to apply on the board while
  // this step is active. If null, defaults to none (disable hints).
  final SolverSettings? solverSettings;
  // Optional: automatically advance to the next step when a hint with this
  // strategy is successfully applied.
  final StrategyType? advanceOnStrategy;
  // Optional: automatically apply hints on step entry using the given
  // strategy allowlist. Applied repeatedly until no more hints are found or
  // until [autoSolveMaxSteps] is reached.
  final Set<StrategyType>? autoSolveAllowed;

  const TutorialStep({
    this.maskRows = const {},
    this.maskCols = const {},
    this.maskBoxes = const {},
    this.cells = const {},
    required this.title,
    required this.body,
    this.dialogAlignment = TutorialDialogAlignment.bottom,
    this.advanceOnValue,
    this.enableActionBar = false,
    this.selectedIndices,
    this.solverSettings,
    this.preventGridTaps = true,
    this.maskIndices,
    this.advanceOnIndices,
    this.tappableIndices,
    this.advanceOnStrategy,
    this.autoSolveAllowed,
  });

  bool get hasAnyAllow =>
      (maskIndices != null && maskIndices!.isNotEmpty) ||
      maskRows.isNotEmpty ||
      maskCols.isNotEmpty ||
      maskBoxes.isNotEmpty ||
      cells.isNotEmpty;

  // Deserialize a step from JSON.
  // Supported keys:
  // - title, body, centerDialog (legacy), alignment/dialogAlignment ('top'|'center'|'bottom'), enableActionBar, preventGridTaps
  // - maskRows, maskCols, maskBoxes, cells, maskIndices, selectedIndices,
  //   advanceOnIndices, tappableIndices (all arrays of ints)
  // - advanceOnValue (int)
  // - advanceOnStrategy (string; StrategyType name or label)
  // - autoSolve: { allowed: [StrategyType names or labels], maxSteps: int }
  // - solver: { allowed: [StrategyType names or labels] }
  factory TutorialStep.fromJson(Map<String, dynamic> json) {
    Set<int> set(dynamic v) {
      final list = (v is List) ? v : const <dynamic>[];
      return list
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>()
          .toSet();
    }

    SolverSettings? solverSettings;
    final solver = json['solver'];
    if (solver is Map) {
      final allowedRaw = solver['allowed'];
      if (allowedRaw is List) {
        final allowed = <StrategyType>{};
        for (final item in allowedRaw) {
          final s = item.toString();
          // Match by enum name or toString label
          StrategyType? match;
          for (final t in StrategyType.values) {
            if (t.name.toLowerCase() == s.toLowerCase() ||
                t.toString().toLowerCase() == s.toLowerCase()) {
              match = t;
              break;
            }
          }
          if (match != null) allowed.add(match);
        }
        solverSettings = SolverSettings(allowed: allowed);
      }
    }

    StrategyType? parseStrategy(dynamic raw) {
      if (raw == null) return null;
      final s = raw.toString();
      for (final t in StrategyType.values) {
        if (t.name.toLowerCase() == s.toLowerCase() ||
            t.toString().toLowerCase() == s.toLowerCase()) {
          return t;
        }
      }
      return null;
    }

    // Parse auto-solve specification
    Set<StrategyType>? autoSolveAllowed;
    final autoSolve = json['autoSolve'];
    if (autoSolve is Map) {
      final allowedRaw = autoSolve['allowed'];
      if (allowedRaw is List) {
        final set = <StrategyType>{};
        for (final item in allowedRaw) {
          final t = parseStrategy(item);
          if (t != null) set.add(t);
        }
        if (set.isNotEmpty) autoSolveAllowed = set;
      }
    }

    // Map alignment. Prefer explicit alignment/dialogAlignment string.
    TutorialDialogAlignment alignment = TutorialDialogAlignment.bottom;
    String? alignRaw;
    if (json.containsKey('alignment')) {
      alignRaw = json['alignment']?.toString();
    }
    if (alignRaw != null) {
      switch (alignRaw.toLowerCase()) {
        case 'top':
          alignment = TutorialDialogAlignment.top;
          break;
        case 'bottom':
          alignment = TutorialDialogAlignment.bottom;
          break;
        case 'center':
        default:
          alignment = TutorialDialogAlignment.center;
      }
    }

    return TutorialStep(
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      dialogAlignment: alignment,
      enableActionBar: json['enableActionBar'] == true,
      preventGridTaps: json['preventGridTaps'] != false, // default true
      advanceOnValue: json['advanceOnValue'] is int
          ? json['advanceOnValue'] as int
          : int.tryParse(json['advanceOnValue']?.toString() ?? ''),
      maskRows: set(json['maskRows']),
      maskCols: set(json['maskCols']),
      maskBoxes: set(json['maskBoxes']),
      cells: set(json['cells']),
      maskIndices: set(json['maskIndices']).isEmpty
          ? null
          : set(json['maskIndices']),
      selectedIndices: json.containsKey('selectedIndices')
          ? set(json['selectedIndices'])
          : null,
      advanceOnIndices: set(json['advanceOnIndices']).isEmpty
          ? null
          : set(json['advanceOnIndices']),
      tappableIndices: set(json['tappableIndices']).isEmpty
          ? null
          : set(json['tappableIndices']),
      solverSettings: solverSettings,
      advanceOnStrategy: parseStrategy(json['advanceOnStrategy']),
      autoSolveAllowed: autoSolveAllowed,
    );
  }
}
