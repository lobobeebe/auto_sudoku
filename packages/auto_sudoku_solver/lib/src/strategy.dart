enum StrategyUsed {
  none,
  nakedSingle,
  hiddenSingle,
  // Locked Candidates
  pointing,
  claiming,
  // Subsets
  nakedPair,
  hiddenPair,
  nakedTriple,
  hiddenTriple,
  nakedQuad,
  hiddenQuad,
  // Fish & Wings
  xWing,
  xyWing,
  swordfish,
  xyzWing,
  wWing,
  // Chain/Graph & Uniqueness
  coloring,
  skyscraper,
  twoStringKite,
  turbotFish,
  uniqueRectangle,
  bug,
  remotePairs,
  xyChain,
  // ALS & AIC
  als,
  alsXyWing,
  aic,
}

const List<StrategyUsed> strategyDifficultyOrder = [
  StrategyUsed.nakedSingle,
  StrategyUsed.hiddenSingle,
  StrategyUsed.pointing,
  StrategyUsed.claiming,
  StrategyUsed.nakedPair,
  StrategyUsed.hiddenPair,
  StrategyUsed.nakedTriple,
  StrategyUsed.hiddenTriple,
  StrategyUsed.nakedQuad,
  StrategyUsed.hiddenQuad,
  StrategyUsed.xWing,
  StrategyUsed.xyWing,
  StrategyUsed.coloring,
  StrategyUsed.swordfish,
  StrategyUsed.skyscraper,
  StrategyUsed.twoStringKite,
  StrategyUsed.turbotFish,
  StrategyUsed.xyzWing,
  StrategyUsed.wWing,
  StrategyUsed.uniqueRectangle,
  StrategyUsed.bug,
  StrategyUsed.remotePairs,
  StrategyUsed.xyChain,
  StrategyUsed.als,
  StrategyUsed.alsXyWing,
  StrategyUsed.aic,
];

int strategyDifficultyIndex(StrategyUsed s) =>
    strategyDifficultyOrder.indexOf(s);

String techniqueLabel(StrategyUsed s) {
  switch (s) {
    case StrategyUsed.nakedSingle:
      return 'Naked Single';
    case StrategyUsed.hiddenSingle:
      return 'Hidden Single';
    case StrategyUsed.pointing:
      return 'Locked Candidates (Pointing)';
    case StrategyUsed.claiming:
      return 'Locked Candidates (Claiming)';
    case StrategyUsed.nakedPair:
      return 'Naked Pair';
    case StrategyUsed.hiddenPair:
      return 'Hidden Pair';
    case StrategyUsed.nakedTriple:
      return 'Naked Triple';
    case StrategyUsed.hiddenTriple:
      return 'Hidden Triple';
    case StrategyUsed.nakedQuad:
      return 'Naked Quad';
    case StrategyUsed.hiddenQuad:
      return 'Hidden Quad';
    case StrategyUsed.xWing:
      return 'X-Wing';
    case StrategyUsed.xyWing:
      return 'XY-Wing';
    case StrategyUsed.swordfish:
      return 'Swordfish';
    case StrategyUsed.xyzWing:
      return 'XYZ-Wing';
    case StrategyUsed.wWing:
      return 'W-Wing';
    case StrategyUsed.coloring:
      return 'Simple Coloring';
    case StrategyUsed.skyscraper:
      return 'Skyscraper';
    case StrategyUsed.twoStringKite:
      return 'Two-String Kite';
    case StrategyUsed.turbotFish:
      return 'Turbot Fish';
    case StrategyUsed.uniqueRectangle:
      return 'Unique Rectangle';
    case StrategyUsed.bug:
      return 'BUG (Bivalue Universal Grave)';
    case StrategyUsed.remotePairs:
      return 'Remote Pairs';
    case StrategyUsed.xyChain:
      return 'XY-Chain';
    case StrategyUsed.als:
      return 'ALS (Almost Locked Set)';
    case StrategyUsed.alsXyWing:
      return 'ALS XY-Wing';
    case StrategyUsed.aic:
      return 'AIC (Alternating Inference Chain)';
    case StrategyUsed.none:
      return 'None';
  }
}
