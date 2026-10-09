class BetEquityRule {
  final String betLabel;
  final double baseEquityPercent;

  const BetEquityRule(this.betLabel, this.baseEquityPercent);
}

class EquityService {
  /// Tabella esatta delle tue percentuali minime di Equity richieste per chiamare
  static const List<BetEquityRule> equityTable = [
    BetEquityRule('Pot / 10', 9.0),
    BetEquityRule('Pot / 5 (20%)', 14.0),
    BetEquityRule('Pot / 4 (25%)', 17.0),
    BetEquityRule('Pot / 3 (33%)', 20.0),
    BetEquityRule('Pot / 2 (50%)', 25.0),
    BetEquityRule('2 * Pot / 3 (66%)', 29.0),
    BetEquityRule('3 * Pot / 4 (75%)', 30.0),
    BetEquityRule('Pot intero (100%)', 39.0),
    BetEquityRule('2 * Pot (200%)', 40.0),
    BetEquityRule('3 * Pot', 43.0),
    BetEquityRule('4 * Pot', 45.0),
    BetEquityRule('5 * Pot', 49.0),
    BetEquityRule('All-In', 51.0),
  ];

  /// Calcola lo sconto in base al numero di giocatori:
  /// 6 giocatori -> -1%, 7 -> -2%, 8 -> -3%, 9 -> -4%, 10 -> -5%
  static double getDiscountPercent(int playerCount) {
    if (playerCount >= 6 && playerCount <= 10) {
      return (playerCount - 5).toDouble();
    }
    return 0.0;
  }

  /// Restituisce l'equity effettiva richiesta scontata
  static double getRequiredEquity(double baseEquity, int playerCount) {
    final discount = getDiscountPercent(playerCount);
    return (baseEquity - discount).clamp(0.0, 100.0);
  }
}