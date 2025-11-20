import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';

class TutorialStep {
  final Set<int> maskRows;
  final Set<int> maskCols;
  final Set<int> maskBoxes;
  final Set<int> cells; // indices 0..80
  final String title;
  final String body;
  // When true, show a centered dialog and do not
  // highlight any specific grid region for this step.
  final bool centerDialog;
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

  const TutorialStep({
    this.maskRows = const {},
    this.maskCols = const {},
    this.maskBoxes = const {},
    this.cells = const {},
    required this.title,
    required this.body,
    this.centerDialog = false,
    this.advanceOnValue,
    this.enableActionBar = false,
    this.selectedIndices,
    this.solverSettings,
    this.preventGridTaps = true,
    this.maskIndices,
    this.advanceOnIndices,
    this.tappableIndices,
  });

  bool get hasAnyAllow =>
      (maskIndices != null && maskIndices!.isNotEmpty) ||
      maskRows.isNotEmpty ||
      maskCols.isNotEmpty ||
      maskBoxes.isNotEmpty ||
      cells.isNotEmpty;

  // Deserialize a step from JSON.
  // Supported keys:
  // - title, body, centerDialog, enableActionBar, preventGridTaps
  // - maskRows, maskCols, maskBoxes, cells, maskIndices, selectedIndices,
  //   advanceOnIndices, tappableIndices (all arrays of ints)
  // - advanceOnValue (int)
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

    return TutorialStep(
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      centerDialog: json['centerDialog'] == true,
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
      selectedIndices: set(json['selectedIndices']),
      advanceOnIndices: set(json['advanceOnIndices']).isEmpty
          ? null
          : set(json['advanceOnIndices']),
      tappableIndices: set(json['tappableIndices']).isEmpty
          ? null
          : set(json['tappableIndices']),
      solverSettings: solverSettings,
    );
  }
}
