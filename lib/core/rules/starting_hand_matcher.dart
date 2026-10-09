import '../models/card.dart';
import 'starting_hand.dart';

class StartingHandMatcher {
  const StartingHandMatcher._();

  static StartingHand fromCards(
    Card firstCard,
    Card secondCard,
  ) {
    final highCard = _getHighCard(firstCard, secondCard);
    final lowCard = _getLowCard(firstCard, secondCard);

    final type = _getHandType(
      firstCard,
      secondCard,
      highCard,
      lowCard,
    );

    return StartingHand(
      highRank: highCard.rank,
      lowRank: lowCard.rank,
      type: type,
    );
  }

  static bool matches(
    Card firstCard,
    Card secondCard,
    StartingHand startingHand,
  ) {
    final actualHand = fromCards(
      firstCard,
      secondCard,
    );

    return actualHand == startingHand;
  }

  static Card _getHighCard(
    Card firstCard,
    Card secondCard,
  ) {
    if (firstCard.rank.index >= secondCard.rank.index) {
      return firstCard;
    }

    return secondCard;
  }

  static Card _getLowCard(
    Card firstCard,
    Card secondCard,
  ) {
    if (firstCard.rank.index <= secondCard.rank.index) {
      return firstCard;
    }

    return secondCard;
  }

  static StartingHandType _getHandType(
    Card firstCard,
    Card secondCard,
    Card highCard,
    Card lowCard,
  ) {
    if (highCard.rank == lowCard.rank) {
      return StartingHandType.pair;
    }

    if (firstCard.suit == secondCard.suit) {
      return StartingHandType.suited;
    }

    return StartingHandType.offsuit;
  }
}