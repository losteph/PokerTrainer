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
  final BetSizeCategory betSize;
  final double pot;
  final double callAmount;
  final double userStack; // <--- NUOVO: stack del giocatore
  final int playerCount;
  final OddsRuleMode mode;
  final bool isDominantMadeHand;

  const OddsTrainingScenario({
    required this.holeCards,
    required this.boardCards,
    required this.drawDescription,
    required this.outs,
    required this.betSize,
    required this.pot,
    required this.callAmount,
    required this.userStack,
    required this.playerCount,
    required this.mode,
    this.isDominantMadeHand = false,
  });

  bool get isAllIn => callAmount >= userStack || betSize == BetSizeCategory.allIn;

  double get estimatedEquity {
    if (isDominantMadeHand) return 100.0;
    if (mode == OddsRuleMode.ruleOf4) {
      final base = outs * 4.0;
      return outs >= 8 ? (base - 1.0) : base;
    } else {
      final base = outs * 2.0;
      return outs >= 8 ? (base + 1.0) : base;
    }
  }

  double get multiwayDiscount {
    if (playerCount >= 6 && playerCount <= 10) {
      return (playerCount - 5).toDouble();
    }
    return 0.0;
  }

  double get adjustedRequiredEquity {
    final finalReq = betSize.requiredEquity - multiwayDiscount;
    return finalReq < 0 ? 0.0 : finalReq;
  }

  bool get isCallCorrect {
    if (isDominantMadeHand) return true;
    if (outs == 0) return false;
    return estimatedEquity >= adjustedRequiredEquity;
  }
}