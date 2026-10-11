import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/bet_size.dart';
import '../models/card.dart';
import '../models/odds_training_scenario.dart';
import '../rules/outs_evaluator.dart';

class OddsFeedback {
  final bool isCorrect;
  final String title;
  final String explanation;

  const OddsFeedback({
    required this.isCorrect,
    required this.title,
    required this.explanation,
  });
}

class OddsController extends ChangeNotifier {
  final Random _random = Random();

  OddsRuleMode _mode = OddsRuleMode.ruleOf4;
  OddsTrainingScenario? _currentScenario;
  OddsFeedback? _feedback;

  OddsRuleMode get mode => _mode;
  OddsTrainingScenario? get currentScenario => _currentScenario;
  OddsFeedback? get feedback => _feedback;

  void setMode(OddsRuleMode mode) {
    _mode = mode;
    startNewScenario();
  }

  void startNewScenario() {
    _feedback = null;
    _currentScenario = _generateProceduralScenario(_mode);
    notifyListeners();
  }

  void chooseAction({required bool called}) {
    final scenario = _currentScenario;

    if (scenario == null || _feedback != null) return;

    final shouldCall = scenario.isCallCorrect;
    final correct = called == shouldCall;

    final rule = scenario.mode == OddsRuleMode.ruleOf4 ? 4 : 2;
    final baseEquity = scenario.outs * rule.toDouble();
    final correction = scenario.outs >= 8
        ? (rule == 4 ? -1.0 : 1.0)
        : 0.0;

    final estimated = scenario.estimatedEquity;
    final required = scenario.betSize.requiredEquity;
    final isPositiveEv = scenario.isCallCorrect;

    final comparison = scenario.isDominantMadeHand
      ? 'MANO FORTE'
      : estimated >= required
          ? '>='
          : '<';

    final explanation =
        'Scenario: ${scenario.drawDescription}\n\n'
        'Puntata: ${scenario.betSize.label} '
        '(\$${scenario.callAmount.toStringAsFixed(0)})\n'
        'Equity richiesta: ${required.toStringAsFixed(1)}%\n\n'
        'Outs: ${scenario.outs}\n'
        'Equity stimata: '
        '${scenario.outs} × $rule = '
        '${baseEquity.toStringAsFixed(0)}%'
        '${correction == 0 ? '' : ' '
            '${correction > 0 ? '+' : '-'} '
            '${correction.abs().toStringAsFixed(0)}%'}\n\n'
        '${scenario.isDominantMadeHand
          ? comparison
          : '${estimated.toStringAsFixed(1)}% $comparison '
            '${required.toStringAsFixed(1)}%'}\n'
        '${isPositiveEv ? '+EV → CALL' : '-EV → FOLD'}';

    _feedback = OddsFeedback(
      isCorrect: correct,
      title: correct
          ? 'Decisione Corretta!'
          : 'Decisione Sbagliata!',
      explanation: explanation,
   );

    notifyListeners();
  }

  OddsTrainingScenario _generateProceduralScenario(
    OddsRuleMode mode,
  ) {
    final boardCount = mode == OddsRuleMode.ruleOf4 ? 3 : 4;
    final roll = _random.nextInt(100);

    late final (List<Card>, List<Card>) cards;

    if (roll < 10) {
      cards = _buildTrashHand(boardCount);
    } else if (roll < 18) {
      cards = _buildGutshot(boardCount);
    } else if (roll < 28) {
      cards = _buildOvercards(boardCount);
    } else if (roll < 40) {
      cards = _buildOesd(boardCount);
    } else if (roll < 53) {
      cards = _buildFlushDraw(boardCount);
    } else if (roll < 61) {
      cards = _buildComboDraw(boardCount);
    } else if (roll < 68) {
      cards = _buildMonsterDraw(boardCount);
    } else if (roll < 75) {
      cards = _buildTripsHand(boardCount);
    } else if (roll < 81) {
      cards = _buildSetOnWetBoard(boardCount);
    } else if (roll < 87) {
      cards = _buildSetDominant(boardCount);
    } else if (roll < 91) {
      cards = _buildPairPlusFlushDraw(boardCount);
    } else if (roll < 94) {
      cards = _buildPairedBoard(boardCount);
    } else if (roll < 96) {
      cards = _buildMiddlePair(boardCount);
    } else if (roll < 98) {
      cards = _buildTwoPair(boardCount);
    } else {
      cards = _buildMadeFlush(boardCount);
    }

    final hole = cards.$1;
    final board = cards.$2;

    final analysis = OutsEvaluator.evaluate(
      hole: hole,
      board: board,
    );

    final playerCount = 4 + _random.nextInt(7);

    final startingStack = switch (playerCount) {
      >= 9 => 200.0,
      >= 7 => 250.0,
      >= 5 => 350.0,
      _ => 500.0,
    };

    final gameStageRoll = _random.nextInt(100);

    double userStack;
    double rawPot;

    if (gameStageRoll < 35) {
      userStack = _roundToChipSize(
        startingStack * (0.85 + _random.nextDouble() * 0.3),
      );
      rawPot = _roundToChipSize(
        6.0 + _random.nextInt(10) * 2.0,
      );
    } else if (gameStageRoll < 75) {
      userStack = _roundToChipSize(
        startingStack * (0.6 + _random.nextDouble() * 0.9),
      );
      rawPot = _roundToChipSize(
        25.0 + _random.nextInt(12) * 10.0,
      );
    } else {
      userStack = _roundToChipSize(
        startingStack * (0.5 + _random.nextDouble() * 1.5),
      );
      if (userStack > 1000) userStack = 1000;

      rawPot = _roundToChipSize(
        100.0 + _random.nextInt(15) * 20.0,
      );
    }

    final targetBet = BetSizeCategory.values[
        _random.nextInt(BetSizeCategory.values.length)];

    final rawCall = rawPot * targetBet.potMultiplier;

    double finalCall;

    if (targetBet == BetSizeCategory.allIn ||
        rawCall >= userStack) {
      finalCall = userStack;
    } else {
      finalCall = _roundToChipSize(rawCall);
      if (finalCall < 2.0) finalCall = 2.0;
    }

    late final BetSizeCategory actualBet;

    if (finalCall >= userStack ||
        targetBet == BetSizeCategory.allIn) {
      actualBet = BetSizeCategory.allIn;
    } else {
      final ratio = finalCall / rawPot;

      actualBet = BetSizeCategory.values
          .where((b) => b != BetSizeCategory.allIn)
          .reduce(
            (a, b) =>
                (a.potMultiplier - ratio).abs() <
                        (b.potMultiplier - ratio).abs()
                    ? a
                    : b,
          );
    }

    return OddsTrainingScenario(
      holeCards: hole,
      boardCards: board,
      drawDescription: analysis.description,
      outs: analysis.totalOuts,
      effectiveOuts: analysis.effectiveOuts,
      betSize: actualBet,
      pot: rawPot,
      callAmount: finalCall,
      userStack: userStack,
      playerCount: playerCount,
      mode: mode,
      isDominantMadeHand: analysis.isDominantMadeHand,
    );
  }

  double _roundToChipSize(double amount) {
    if (amount <= 10) return (amount / 2).round() * 2.0;
    if (amount <= 50) return (amount / 5).round() * 5.0;
    if (amount <= 200) return (amount / 10).round() * 10.0;
    return (amount / 20).round() * 20.0;
  }

  List<Card> _createNewDeck() {
    final deck = <Card>[];

    for (final suit in CardSuit.values) {
      for (final rank in CardRank.values) {
        deck.add(Card(suit: suit, rank: rank));
      }
    }

    deck.shuffle(_random);
    return deck;
  }

  Card _takeCard(
    List<Card> deck,
    bool Function(Card) predicate,
  ) {
    final index = deck.indexWhere(predicate);

    if (index == -1) {
      throw StateError(
        'Impossibile generare lo scenario richiesto.',
      );
    }

    return deck.removeAt(index);
  }

  (List<Card>, List<Card>) _buildFlushDraw(
    int boardCount,
  ) {
    final deck = _createNewDeck();
    final suit = CardSuit.values[
        _random.nextInt(CardSuit.values.length)];

    final hole = [
      _takeCard(deck, (c) => c.suit == suit),
      _takeCard(deck, (c) => c.suit == suit),
    ];

    final board = [
      _takeCard(deck, (c) => c.suit == suit),
      _takeCard(deck, (c) => c.suit == suit),
      _takeCard(deck, (c) => c.suit != suit),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(deck, (c) => c.suit != suit),
      );
    }

    return (hole, board);
  }

  (List<Card>, List<Card>) _buildOesd(
    int boardCount,
  ) {
    final deck = _createNewDeck();
    final base = 2 + _random.nextInt(6);

    final hole = [
      _takeCard(
        deck,
        (c) => c.rank == CardRank.values[base + 1],
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.values[base + 2],
      ),
    ];

    final board = [
      _takeCard(
        deck,
        (c) => c.rank == CardRank.values[base],
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.values[base + 3],
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.two,
      ),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(deck, (c) => c.rank == CardRank.ace),
      );
    }

    return (hole, board);
  }

  (List<Card>, List<Card>) _buildGutshot(
    int boardCount,
  ) {
    final deck = _createNewDeck();
    final base = 3 + _random.nextInt(5);

    final hole = [
      _takeCard(
        deck,
        (c) => c.rank == CardRank.values[base],
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.values[base + 1],
      ),
    ];

    final board = [
      _takeCard(
        deck,
        (c) => c.rank == CardRank.values[base + 3],
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.values[base + 4],
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.two,
      ),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(deck, (c) => c.rank == CardRank.ace),
      );
    }

    return (hole, board);
  }

  (List<Card>, List<Card>) _buildOvercards(
    int boardCount,
  ) {
    final deck = _createNewDeck();

    final hole = [
      _takeCard(deck, (c) => c.rank == CardRank.ace),
      _takeCard(deck, (c) => c.rank == CardRank.king),
    ];

    final board = [
      _takeCard(deck, (c) => c.rank == CardRank.eight),
      _takeCard(deck, (c) => c.rank == CardRank.four),
      _takeCard(deck, (c) => c.rank == CardRank.two),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(deck, (c) => c.rank == CardRank.six),
      );
    }

    return (hole, board);
  }

  (List<Card>, List<Card>) _buildComboDraw(
    int boardCount,
  ) {
    final deck = _createNewDeck();
    final suit = CardSuit.values[
        _random.nextInt(CardSuit.values.length)];

    final hole = [
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.jack,
      ),
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.ten,
      ),
    ];

    final board = [
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.eight,
      ),
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.seven,
      ),
      _takeCard(
        deck,
        (c) =>
            c.suit != suit &&
            c.rank == CardRank.two,
      ),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(
          deck,
          (c) =>
              c.suit != suit &&
              c.rank == CardRank.four,
        ),
      );
    }

    return (hole, board);
  }

  (List<Card>, List<Card>) _buildMonsterDraw(
    int boardCount,
  ) {
    final deck = _createNewDeck();
    final suit = CardSuit.values[
        _random.nextInt(CardSuit.values.length)];

    final hole = [
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.nine,
      ),
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.eight,
      ),
    ];

    final board = [
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.seven,
      ),
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.six,
      ),
      _takeCard(
        deck,
        (c) =>
            c.suit != suit &&
            c.rank == CardRank.two,
      ),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(
          deck,
          (c) =>
              c.suit != suit &&
              c.rank == CardRank.king,
        ),
      );
    }

    return (hole, board);
  }

  (List<Card>, List<Card>) _buildTripsHand(
    int boardCount,
  ) {
    final deck = _createNewDeck();
    final rank = CardRank.values[
        2 + _random.nextInt(8)];

    final hole = [
      _takeCard(deck, (c) => c.rank == rank),
      _takeCard(deck, (c) => c.rank != rank),
    ];

    final board = [
      _takeCard(deck, (c) => c.rank == rank),
      _takeCard(deck, (c) => c.rank == rank),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.ace,
      ),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(
          deck,
          (c) =>
              c.rank != rank &&
              c.rank != CardRank.ace,
        ),
      );
    }

    return (hole, board);
  }

  (List<Card>, List<Card>) _buildPairPlusFlushDraw(
    int boardCount,
  ) {
    final deck = _createNewDeck();
    final suit = CardSuit.values[
        _random.nextInt(CardSuit.values.length)];

    final pairRank = CardRank.values[
        4 + _random.nextInt(5)];

    final hole = [
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank != pairRank,
      ),
      _takeCard(
        deck,
        (c) =>
            c.rank == pairRank &&
            c.suit != suit,
      ),
    ];

    final board = [
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank != pairRank,
      ),
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank != pairRank,
      ),
      _takeCard(
        deck,
        (c) => c.rank == pairRank,
      ),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(
          deck,
          (c) =>
              c.suit != suit &&
              c.rank != pairRank,
        ),
      );
    }

    return (hole, board);
  }

  (List<Card>, List<Card>) _buildPairedBoard(
    int boardCount,
  ) {
    final deck = _createNewDeck();
    final pairedRank = CardRank.values[
        3 + _random.nextInt(7)];

    final hole = [
      _takeCard(
        deck,
        (c) => c.rank == CardRank.ace,
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.king,
      ),
    ];

    final board = [
      _takeCard(
        deck,
        (c) => c.rank == pairedRank,
      ),
      _takeCard(
        deck,
        (c) => c.rank == pairedRank,
      ),
      _takeCard(
        deck,
        (c) =>
            c.rank != pairedRank &&
            c.rank != CardRank.ace &&
            c.rank != CardRank.king,
      ),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(
          deck,
          (c) =>
              c.rank != pairedRank &&
              c.rank != CardRank.ace &&
              c.rank != CardRank.king,
        ),
      );
    }

    return (hole, board);
  }

  (List<Card>, List<Card>) _buildMiddlePair(
    int boardCount,
  ) {
    final deck = _createNewDeck();
    final pairRank = CardRank.values[
        4 + _random.nextInt(4)];

    final hole = [
      _takeCard(
        deck,
        (c) => c.rank == pairRank,
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.queen,
      ),
    ];

    final board = [
      _takeCard(
        deck,
        (c) => c.rank == pairRank,
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.ace,
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.two,
      ),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(
          deck,
          (c) => c.rank == CardRank.four,
        ),
      );
    }

    return (hole, board);
  }

  (List<Card>, List<Card>) _buildSetOnWetBoard(
    int boardCount,
  ) {
    final deck = _createNewDeck();
    final setRank = CardRank.values[
        3 + _random.nextInt(6)];

    final suit = CardSuit.values[
        _random.nextInt(CardSuit.values.length)];

    final hole = [
      _takeCard(
        deck,
        (c) =>
            c.rank == setRank &&
            c.suit != suit,
      ),
      _takeCard(
        deck,
        (c) =>
            c.rank == setRank &&
            c.suit != suit,
      ),
    ];

    final board = [
      _takeCard(
        deck,
        (c) =>
            c.rank == setRank &&
            c.suit == suit,
      ),
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank != setRank,
      ),
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank != setRank,
      ),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(
          deck,
          (c) =>
              c.suit != suit &&
              c.rank != setRank,
        ),
      );
    }

    return (hole, board);
  }

  (List<Card>, List<Card>) _buildSetDominant(
    int boardCount,
  ) {
    final deck = _createNewDeck();

    final possibleRanks = CardRank.values
        .where(
          (rank) =>
              rank.index >= 4 &&
              rank.index <= 9 &&
              rank != CardRank.eight,
        )
        .toList();

    final setRank = possibleRanks[
        _random.nextInt(possibleRanks.length)];

    final hole = [
      _takeCard(
        deck,
        (c) => c.rank == setRank,
      ),
      _takeCard(
        deck,
        (c) => c.rank == setRank,
      ),
    ];

    final board = <Card>[
      _takeCard(
        deck,
        (c) => c.rank == setRank,
      ),
    ];

    bool suitAvailable(Card candidate) {
      return board
              .where(
                (c) => c.suit == candidate.suit,
              )
              .length <
          2;
    }

    board.add(
      _takeCard(
        deck,
        (c) =>
            c.rank == CardRank.two &&
            suitAvailable(c),
      ),
    );

    board.add(
      _takeCard(
        deck,
        (c) =>
            c.rank == CardRank.eight &&
            suitAvailable(c),
      ),
    );

    if (boardCount == 4) {
      board.add(
        _takeCard(
          deck,
          (c) =>
              c.rank == CardRank.king &&
              suitAvailable(c),
        ),
      );
    }

    return (hole, board);
  }

  (List<Card>, List<Card>) _buildTrashHand(
    int boardCount,
  ) {
    final deck = _createNewDeck();

    final hole = [
      _takeCard(
        deck,
        (c) => c.rank == CardRank.eight,
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.three,
      ),
    ];

    final board = [
      _takeCard(
        deck,
        (c) => c.rank == CardRank.king,
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.jack,
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.four,
      ),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(
          deck,
          (c) => c.rank == CardRank.two,
        ),
      );
    }

    return (hole, board);
  }

  // NUOVO: doppia coppia personale.
  (List<Card>, List<Card>) _buildTwoPair(
    int boardCount,
  ) {
    final deck = _createNewDeck();

    final hole = [
      _takeCard(
        deck,
        (c) => c.rank == CardRank.king,
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.jack,
      ),
    ];

    final board = [
      _takeCard(
        deck,
        (c) => c.rank == CardRank.king,
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.jack,
      ),
      _takeCard(
        deck,
        (c) => c.rank == CardRank.two,
      ),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(
          deck,
          (c) => c.rank == CardRank.four,
        ),
      );
    }

    return (hole, board);
  }

  // NUOVO: colore già chiuso con entrambe le hole.
  (List<Card>, List<Card>) _buildMadeFlush(
    int boardCount,
  ) {
    final deck = _createNewDeck();
    final suit = CardSuit.values[
        _random.nextInt(CardSuit.values.length)];

    final hole = [
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.ace,
      ),
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.king,
      ),
    ];

    final board = [
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.eight,
      ),
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.four,
      ),
      _takeCard(
        deck,
        (c) =>
            c.suit == suit &&
            c.rank == CardRank.two,
      ),
    ];

    if (boardCount == 4) {
      board.add(
        _takeCard(
          deck,
          (c) =>
              c.suit != suit &&
              c.rank == CardRank.six,
        ),
      );
    }

    return (hole, board);
  }
}