import 'package:auto_sudoku_solver/src/sudoku_tool.dart';

enum StrategyUsed {
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
  aic;

  Difficulty getDifficulty() => difficultyMap[this] ?? Difficulty.impossible;

  String toString() {
    switch (this) {
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
    }
  }
}

const Map<StrategyUsed, Difficulty> difficultyMap = {
  StrategyUsed.nakedSingle: Difficulty.trivial,
  StrategyUsed.hiddenSingle: Difficulty.trivial,
  StrategyUsed.nakedPair: Difficulty.easy,
  StrategyUsed.nakedTriple: Difficulty.easy,
  StrategyUsed.nakedQuad: Difficulty.easy,
  StrategyUsed.pointing: Difficulty.easy,
  StrategyUsed.claiming: Difficulty.easy,
  StrategyUsed.hiddenPair: Difficulty.easy,
  StrategyUsed.hiddenTriple: Difficulty.easy,
  StrategyUsed.hiddenQuad: Difficulty.easy,
  StrategyUsed.xWing: Difficulty.medium,
  StrategyUsed.xyWing: Difficulty.medium,
  StrategyUsed.coloring: Difficulty.medium,
  StrategyUsed.swordfish: Difficulty.medium,
  StrategyUsed.skyscraper: Difficulty.hard,
  StrategyUsed.twoStringKite: Difficulty.hard,
  StrategyUsed.turbotFish: Difficulty.hard,
  StrategyUsed.xyzWing: Difficulty.hard,
  StrategyUsed.wWing: Difficulty.hard,
  StrategyUsed.uniqueRectangle: Difficulty.hard,
  StrategyUsed.bug: Difficulty.hard,
  StrategyUsed.remotePairs: Difficulty.hard,
  StrategyUsed.xyChain: Difficulty.hard,
  StrategyUsed.als: Difficulty.hard,
  StrategyUsed.alsXyWing: Difficulty.hard,
  StrategyUsed.aic: Difficulty.hard,
};
