import 'card.dart';
import 'player_position.dart';

class Player {
  final String id;
  final PlayerPosition position;

  double stack;
  List<Card> holeCards;

  bool isActive;
  bool hasFolded;

  Player({
    required this.id,
    required this.position,
    required this.stack,
    List<Card>? holeCards,
    this.isActive = true,
    this.hasFolded = false,
  }) : holeCards = List.unmodifiable(holeCards ?? const []);

  bool get isAllIn => stack <= 0;

  void setHoleCards(List<Card> cards) {
    if (cards.length > 2) {
      throw ArgumentError(
        'Un giocatore di Texas Hold\'em può avere al massimo 2 carte.',
      );
    }

    holeCards = List.unmodifiable(cards);
  }

  void clearHoleCards() {
    holeCards = const [];
  }

  void fold() {
    hasFolded = true;
    isActive = false;
  }

  void resetForNewHand() {
    holeCards = const [];
    isActive = true;
    hasFolded = false;
  }

  @override
  String toString() {
    return 'Player('
        'id: $id, '
        'position: ${position.label}, '
        'stack: $stack, '
        'holeCards: $holeCards, '
        'isActive: $isActive, '
        'hasFolded: $hasFolded'
        ')';
  }
}