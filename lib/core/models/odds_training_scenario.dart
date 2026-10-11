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


  bool get hasPlayableTopPair {
    if (holeCards.length != 2 || boardCards.isEmpty) {
      return false;
    }

    final highestBoard = boardCards
       .map((c) => c.rank.index)
        .reduce((a, b) => a > b ? a : b);

    final matching = holeCards.where(
      (h) =>
          h.rank.index == highestBoard &&
          boardCards.any((b) => b.rank == h.rank),
    );

    if (matching.isEmpty) return false;

    final kicker = holeCards.firstWhere(
      (h) => h.rank.index != highestBoard,
      orElse: () => holeCards.first,
    );

    final boardHasPair = boardCards.any(
      (c) =>
          boardCards.where((b) => b.rank == c.rank).length >= 2,
    );

    final threeSuited = CardSuit.values.any(
      (suit) =>
          boardCards.where((c) => c.suit == suit).length >= 3,
    );

    return kicker.rank.index >= 9 &&
        !boardHasPair &&
        !threeSuited;
  }

  bool get hasPlayableTwoPair {
    if (holeCards.length != 2) return false;

    if (holeCards[0].rank == holeCards[1].rank) {
      return false;
    }

    final bothPaired = holeCards.every(
      (h) => boardCards.any((b) => b.rank == h.rank),
    );

    if (!bothPaired) return false;

    final threeSuited = CardSuit.values.any(
      (suit) =>
          boardCards.where((c) => c.suit == suit).length >= 3,
    );

    return !threeSuited;
  }


  bool get isCallCorrect {
    // Mani gia' forti su board sufficientemente sicuri.
    if (isDominantMadeHand) return true;

    // Top pair con buon kicker e doppia coppia personale:
    // giocabili contro puntate non eccessive.
    if (hasPlayableTopPair || hasPlayableTwoPair) {
      if (betSize.potMultiplier <= 0.75) {
        return true;
      }
    }

    // Per le altre situazioni usiamo soltanto outs interi,
    // regola del 4/2 e tabella pot odds.
    if (outs <= 0) return false;

    return estimatedEquity >= betSize.requiredEquity;
  }
}