import 'package:auto_sudoku/state/strategy_progress.dart';
import 'package:auto_sudoku_solver/auto_sudoku_solver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('everything starts locked and auto-solve has nothing to use', () {
    final progress = StrategyProgress();
    expect(progress.unlockedCount, 0);
    expect(progress.autoSolverSettings(), isNull);
  });

  test('unlocks exactly at the threshold and reports it once', () {
    final progress = StrategyProgress();
    for (var i = 1; i < StrategyProgress.unlockThreshold; i++) {
      expect(progress.record(StrategyType.openPair), isFalse);
    }
    expect(progress.isUnlocked(StrategyType.openPair), isFalse);
    expect(progress.record(StrategyType.openPair), isTrue);
    expect(progress.isUnlocked(StrategyType.openPair), isTrue);
    expect(progress.record(StrategyType.openPair), isFalse);
  });

  test('only unlocked, enabled strategies reach the solver', () {
    final progress = StrategyProgress();
    for (var i = 0; i < StrategyProgress.unlockThreshold; i++) {
      progress.record(StrategyType.openSingle);
      progress.record(StrategyType.hiddenSingle);
    }
    var settings = progress.autoSolverSettings()!;
    expect(settings.allows(StrategyType.openSingle), isTrue);
    expect(settings.allows(StrategyType.xWing), isFalse);

    progress.setEnabled(StrategyType.hiddenSingle, false);
    settings = progress.autoSolverSettings()!;
    expect(settings.allows(StrategyType.hiddenSingle), isFalse);

    progress.setMasterEnabled(false);
    expect(progress.autoSolverSettings(), isNull);
  });

  test('progress and preferences persist', () async {
    final first = StrategyProgress();
    for (var i = 0; i < StrategyProgress.unlockThreshold; i++) {
      first.record(StrategyType.openSingle);
    }
    first.setEnabled(StrategyType.openSingle, false);
    first.record(StrategyType.xWing);
    await Future<void>.delayed(Duration.zero);

    final second = StrategyProgress();
    await second.loadAll();
    expect(second.isUnlocked(StrategyType.openSingle), isTrue);
    expect(second.isEnabled(StrategyType.openSingle), isFalse);
    expect(second.countOf(StrategyType.xWing), 1);
  });

  test('resetAll relocks everything', () async {
    final progress = StrategyProgress();
    for (var i = 0; i < StrategyProgress.unlockThreshold; i++) {
      progress.record(StrategyType.openSingle);
    }
    await progress.resetAll();
    expect(progress.unlockedCount, 0);
  });
}
