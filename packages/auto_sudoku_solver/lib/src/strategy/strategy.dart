import 'package:auto_sudoku_solver/src/sudoku_tool.dart';

enum StrategyType {
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

  @override
  String toString() {
    switch (this) {
      case StrategyType.nakedSingle:
        return 'Naked Single';
      case StrategyType.hiddenSingle:
        return 'Hidden Single';
      case StrategyType.pointing:
        return 'Locked Candidates (Pointing)';
      case StrategyType.claiming:
        return 'Locked Candidates (Claiming)';
      case StrategyType.nakedPair:
        return 'Naked Pair';
      case StrategyType.hiddenPair:
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
      case StrategyType.nakedTriple:
        return 'Naked Triple';
      case StrategyType.hiddenTriple:
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
      case StrategyType.nakedQuad:
        return 'Naked Quad';
      case StrategyType.hiddenQuad:
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
      case StrategyType.xWing:
        return 'X-Wing';
      case StrategyType.xyWing:
        return 'XY-Wing';
      case StrategyType.swordfish:
        return 'Swordfish';
      case StrategyType.xyzWing:
        return 'XYZ-Wing';
      case StrategyType.wWing:
        return 'W-Wing';
      case StrategyType.coloring:
        return 'Simple Coloring';
      case StrategyType.skyscraper:
        return 'Skyscraper';
      case StrategyType.twoStringKite:
        return 'Two-String Kite';
      case StrategyType.turbotFish:
        return 'Turbot Fish';
      case StrategyType.uniqueRectangle:
        return 'Unique Rectangle';
      case StrategyType.bug:
        return 'BUG (Bivalue Universal Grave)';
      case StrategyType.remotePairs:
        return 'Remote Pairs';
      case StrategyType.xyChain:
        return 'XY-Chain';
      case StrategyType.als:
        return 'ALS (Almost Locked Set)';
      case StrategyType.alsXyWing:
        return 'ALS XY-Wing';
      case StrategyType.aic:
        return 'AIC (Alternating Inference Chain)';
    }
  }
}

const Map<StrategyType, Difficulty> difficultyMap = {
  StrategyType.nakedSingle: Difficulty.trivial,
  StrategyType.hiddenSingle: Difficulty.trivial,
  StrategyType.nakedPair: Difficulty.easy,
  StrategyType.nakedTriple: Difficulty.easy,
  StrategyType.nakedQuad: Difficulty.easy,
  StrategyType.pointing: Difficulty.easy,
  StrategyType.claiming: Difficulty.easy,
  StrategyType.hiddenPair: Difficulty.easy,
  StrategyType.hiddenTriple: Difficulty.easy,
  StrategyType.hiddenQuad: Difficulty.easy,
  StrategyType.xWing: Difficulty.medium,
  StrategyType.xyWing: Difficulty.medium,
  StrategyType.coloring: Difficulty.medium,
  StrategyType.swordfish: Difficulty.medium,
  StrategyType.skyscraper: Difficulty.hard,
  StrategyType.twoStringKite: Difficulty.hard,
  StrategyType.turbotFish: Difficulty.hard,
  StrategyType.xyzWing: Difficulty.hard,
  StrategyType.wWing: Difficulty.hard,
  StrategyType.uniqueRectangle: Difficulty.hard,
  StrategyType.bug: Difficulty.hard,
  StrategyType.remotePairs: Difficulty.hard,
  StrategyType.xyChain: Difficulty.hard,
  StrategyType.als: Difficulty.hard,
  StrategyType.alsXyWing: Difficulty.hard,
  StrategyType.aic: Difficulty.hard,
};

abstract class Strategy {
  StrategyType get type;

  Difficulty get difficulty;

  @override
  String toString();

  Hint? findHint(Sudoku s);

  Hint? getHintFromClues(Sudoku s, List<int> indices);
}
