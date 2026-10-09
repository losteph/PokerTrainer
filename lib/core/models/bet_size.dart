enum BetSizeCategory {
  potTenth('Pot / 10', 0.10, 9.0),
  potFifth('Pot / 5', 0.20, 14.0),
  potQuarter('Pot / 4', 0.25, 17.0),
  potThird('Pot / 3', 0.33, 20.0),
  potHalf('Pot / 2', 0.50, 25.0),
  twoThirdsPot('2/3 Pot', 0.66, 29.0),
  threeQuarterPot('3/4 Pot', 0.75, 30.0),
  potFull('Pot', 1.0, 39.0),
  twoPot('2x Pot', 2.0, 40.0),
  threePot('3x Pot', 3.0, 43.0),
  fourPot('4x Pot', 4.0, 45.0),
  fivePot('5x Pot', 5.0, 49.0),
  allIn('All-in', 6.0, 51.0);

  final String label;
  final double potMultiplier;
  final double requiredEquity;

  const BetSizeCategory(this.label, this.potMultiplier, this.requiredEquity);
}