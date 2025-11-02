enum StrategyUsed {
  none,
  nakedSingle,
  hiddenSingle,
  // Pairs
  nakedPair,
  hiddenPair,
  //nakedPairRow,
  //hiddenPairRow,
  //nakedPairCol,
  //hiddenPairCol,
  //nakedPairBox,
  //hiddenPairBox,
  // Triples
  nakedTriple,
  hiddenTriple,
  // nakedTripleRow,
  // hiddenTripleRow,
  // nakedTripleCol,
  // hiddenTripleCol,
  // nakedTripleBox,
  // hiddenTripleBox,
  // Quads
  nakedQuad,
  hiddenQuad,
  // nakedQuadRow,
  // hiddenQuadRow,
  // nakedQuadCol,
  // hiddenQuadCol,
  // nakedQuadBox,
  // hiddenQuadBox,
  // Locked Candidates
  pointing,
  claiming,
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
  // StrategyUsed.nakedPairRow,
  // StrategyUsed.hiddenPairRow,
  // StrategyUsed.nakedPairCol,
  // StrategyUsed.hiddenPairCol,
  // StrategyUsed.nakedPairBox,
  // StrategyUsed.hiddenPairBox,
  StrategyUsed.nakedTriple,
  StrategyUsed.hiddenTriple,
  // StrategyUsed.nakedTripleRow,
  // StrategyUsed.hiddenTripleRow,
  // StrategyUsed.nakedTripleCol,
  // StrategyUsed.hiddenTripleCol,
  // StrategyUsed.nakedTripleBox,
  // StrategyUsed.hiddenTripleBox,
  StrategyUsed.nakedQuad,
  StrategyUsed.hiddenQuad,
  // StrategyUsed.nakedQuadRow,
  // StrategyUsed.hiddenQuadRow,
  // StrategyUsed.nakedQuadCol,
  // StrategyUsed.hiddenQuadCol,
  // StrategyUsed.nakedQuadBox,
  // StrategyUsed.hiddenQuadBox,
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
    // case StrategyUsed.nakedPairRow:
    //   return 'Naked Pair (Row)';
    // case StrategyUsed.hiddenPairRow:
    //   return 'Hidden Pair (Row)';
    // case StrategyUsed.nakedPairCol:
    //   return 'Naked Pair (Col)';
    // case StrategyUsed.hiddenPairCol:
    //   return 'Hidden Pair (Col)';
    // case StrategyUsed.nakedPairBox:
    //   return 'Naked Pair (Box)';
    // case StrategyUsed.hiddenPairBox:
    //   return 'Hidden Pair (Box)';
    case StrategyUsed.nakedTriple:
      return 'Naked Triple';
    case StrategyUsed.hiddenTriple:
      return 'Hidden Triple';
    // case StrategyUsed.nakedTripleRow:
    //   return 'Naked Triple (Row)';
    // case StrategyUsed.hiddenTripleRow:
    //   return 'Hidden Triple (Row)';
    // case StrategyUsed.nakedTripleCol:
    //   return 'Naked Triple (Col)';
    // case StrategyUsed.hiddenTripleCol:
    //   return 'Hidden Triple (Col)';
    // case StrategyUsed.nakedTripleBox:
    //   return 'Naked Triple (Box)';
    // case StrategyUsed.hiddenTripleBox:
    //   return 'Hidden Triple (Box)';
    case StrategyUsed.nakedQuad:
      return 'Naked Quad';
    case StrategyUsed.hiddenQuad:
      return 'Hidden Quad';
    // case StrategyUsed.nakedQuadRow:
    //   return 'Naked Quad (Row)';
    // case StrategyUsed.hiddenQuadRow:
    //   return 'Hidden Quad (Row)';
    // case StrategyUsed.nakedQuadCol:
    //   return 'Naked Quad (Col)';
    // case StrategyUsed.hiddenQuadCol:
    //   return 'Hidden Quad (Col)';
    // case StrategyUsed.nakedQuadBox:
    //   return 'Naked Quad (Box)';
    // case StrategyUsed.hiddenQuadBox:
    //   return 'Hidden Quad (Box)';
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
