class StrategicRangeDefinition {
  final List<String> notations;

  final bool allPairs;
  final bool allAces;
  final bool allSuited;

  const StrategicRangeDefinition({
    this.notations = const [],
    this.allPairs = false,
    this.allAces = false,
    this.allSuited = false,
  });
}