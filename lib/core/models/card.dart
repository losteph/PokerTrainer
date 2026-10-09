enum CardSuit {
  clubs,
  diamonds,
  hearts,
  spades,
}

enum CardRank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
}

class Card {
  final CardSuit suit;
  final CardRank rank;

  const Card({
    required this.suit,
    required this.rank,
  });

  String get symbol {
    final rankSymbol = switch (rank) {
      CardRank.two => '2',
      CardRank.three => '3',
      CardRank.four => '4',
      CardRank.five => '5',
      CardRank.six => '6',
      CardRank.seven => '7',
      CardRank.eight => '8',
      CardRank.nine => '9',
      CardRank.ten => 'T',
      CardRank.jack => 'J',
      CardRank.queen => 'Q',
      CardRank.king => 'K',
      CardRank.ace => 'A',
    };

    final suitSymbol = switch (suit) {
      CardSuit.clubs => '♣',
      CardSuit.diamonds => '♦',
      CardSuit.hearts => '♥',
      CardSuit.spades => '♠',
    };

    return '$rankSymbol$suitSymbol';
  }

  @override
  String toString() => symbol;

  @override
  bool operator ==(Object other) {
    return other is Card &&
        other.suit == suit &&
        other.rank == rank;
  }

  @override
  int get hashCode => Object.hash(suit, rank);
}