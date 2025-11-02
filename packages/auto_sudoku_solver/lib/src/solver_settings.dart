class SolverSettings {
  final bool allowHiddenSingles;
  final bool allowLocked;
  final bool allowPairs;
  final bool allowTriples;
  final bool allowQuads;
  final bool allowHiddenSubsets;
  final bool allowXWing;
  final bool allowXYWing;
  final bool allowColoring;
  final bool allowSwordfish;
  final bool allowSkyscraper;
  final bool allowTwoStringKite;
  final bool allowTurbotFish;
  final bool allowXYZWing;
  final bool allowWWing;
  final bool allowUR;
  final bool allowBUG;
  final bool allowRemotePairs;
  final bool allowXYChain;
  final bool allowALS;
  final bool allowALSXYWing;
  final bool allowAIC;

  const SolverSettings({
    this.allowHiddenSingles = true,
    this.allowLocked = true,
    this.allowPairs = true,
    this.allowTriples = true,
    this.allowQuads = true,
    this.allowHiddenSubsets = true,
    this.allowXWing = true,
    this.allowXYWing = true,
    this.allowColoring = true,
    this.allowSwordfish = true,
    this.allowSkyscraper = true,
    this.allowTwoStringKite = true,
    this.allowTurbotFish = true,
    this.allowXYZWing = true,
    this.allowWWing = true,
    this.allowUR = true,
    this.allowBUG = true,
    this.allowRemotePairs = true,
    this.allowXYChain = true,
    this.allowALS = true,
    this.allowALSXYWing = true,
    this.allowAIC = true,
  });

  const SolverSettings.off({
    bool allowHiddenSingles = false,
    bool allowLocked = false,
    bool allowPairs = false,
    bool allowTriples = false,
    bool allowQuads = false,
    bool allowHiddenSubsets = false,
    bool allowXWing = false,
    bool allowXYWing = false,
    bool allowColoring = false,
    bool allowSwordfish = false,
    bool allowSkyscraper = false,
    bool allowTwoStringKite = false,
    bool allowTurbotFish = false,
    bool allowXYZWing = false,
    bool allowWWing = false,
    bool allowUR = false,
    bool allowBUG = false,
    bool allowRemotePairs = false,
    bool allowXYChain = false,
    bool allowALS = false,
    bool allowALSXYWing = false,
    bool allowAIC = false,
  }) : this(
         allowHiddenSingles: allowHiddenSingles,
         allowLocked: allowLocked,
         allowPairs: allowPairs,
         allowTriples: allowTriples,
         allowQuads: allowQuads,
         allowHiddenSubsets: allowHiddenSubsets,
         allowXWing: allowXWing,
         allowXYWing: allowXYWing,
         allowColoring: allowColoring,
         allowSwordfish: allowSwordfish,
         allowSkyscraper: allowSkyscraper,
         allowTwoStringKite: allowTwoStringKite,
         allowTurbotFish: allowTurbotFish,
         allowXYZWing: allowXYZWing,
         allowWWing: allowWWing,
         allowUR: allowUR,
         allowBUG: allowBUG,
         allowRemotePairs: allowRemotePairs,
         allowXYChain: allowXYChain,
         allowALS: allowALS,
         allowALSXYWing: allowALSXYWing,
         allowAIC: allowAIC,
       );
}
