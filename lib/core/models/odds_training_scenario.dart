import 'bet_size.dart';
import 'card.dart';

enum OddsRuleMode {
  ruleOf4('Regola del 4 (Flop - 2 carte)'),
  ruleOf2('Regola del 2 (Turn - 1 carta)');

  final String label;
  const OddsRuleMode(this.label);
}

class OddsTrainingScenario {
  final List<Card> holeCards;
  final List<Card> boardCards;
  final String drawDescription;
  final int outs;
  final double effectiveOuts;
  final BetSizeCategory betSize;
  final double pot;
  final double callAmount;
  final double userStack;
  final int playerCount;
  final OddsRuleMode mode;
  final bool isDominantMadeHand;

  const OddsTrainingScenario({
    required this.holeCards,
    required this.boardCards,
    required this.drawDescription,
    required this.outs,
    double? effectiveOuts,
    required this.betSize,
    required this.pot,
    required this.callAmount,
    required this.userStack,
    required this.playerCount,
    required this.mode,
    this.isDominantMadeHand = false,
  }) : effectiveOuts = effectiveOuts ?? 0.0;

  bool get isAllIn =>
      callAmount >= userStack ||
      betSize == BetSizeCategory.allIn;

  double get estimatedEquity {
    final outsValue = outs.toDouble();

    if (mode == OddsRuleMode.ruleOf4) {
      final base = outsValue * 4.0;
      return outsValue >= 8 ? base - 1.0 : base;
    }

    final base = outsValue * 2.0;
    return outsValue >= 8 ? base + 1.0 : base;
  }

  double get multiwayDiscount => 0.0;

  double get adjustedRequiredEquity =>
      betSize.requiredEquity;

  bool get isCallCorrect {
    return estimatedEquity >= betSize.requiredEquity;
  }
}