import 'dart:math';

import 'card.dart';

class Deck {
  final Random _random;

  List<Card> _cards = [];

  Deck({
    Random? random,
  }) : _random = random ?? Random() {
    reset();
  }

  List<Card> get cards => List.unmodifiable(_cards);

  int get remainingCards => _cards.length;

  bool get isEmpty => _cards.isEmpty;

  void reset() {
    _cards = [
      for (final suit in CardSuit.values)
        for (final rank in CardRank.values)
          Card(
            suit: suit,
            rank: rank,
          ),
    ];
  }

  void shuffle() {
    _cards.shuffle(_random);
  }

  Card draw() {
    if (_cards.isEmpty) {
      throw StateError('Il mazzo è vuoto.');
    }

    return _cards.removeLast();
  }

  List<Card> drawMany(int count) {
    if (count < 0) {
      throw ArgumentError(
        'Il numero di carte da pescare non può essere negativo.',
      );
    }

    if (count > _cards.length) {
      throw StateError(
        'Non ci sono abbastanza carte nel mazzo.',
      );
    }

    return List.generate(
      count,
      (_) => draw(),
    );
  }
}