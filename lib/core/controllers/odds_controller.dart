import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/bet_size.dart';
import '../models/card.dart';
import '../models/odds_training_scenario.dart';

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
    if (_currentScenario == null || _feedback != null) return;

    final scenario = _currentScenario!;
    final shouldCall = scenario.isCallCorrect;
    final userWasCorrect = (called == shouldCall);

    String explanation;

    if (scenario.isDominantMadeHand) {
      explanation =
          'Punto Chiuso: ${scenario.drawDescription}\n'
          'Board Asciutto (Dry): Stai dominando il tavolo (~85%+ di equity).\n'
          'Tuo Stack: \$${scenario.userStack.toInt()} | Piatto: \$${scenario.pot.toInt()} | Bet: \$${scenario.callAmount.toInt()}\n\n'
          'Verdetto: CALL (o Raise) per valore! Con un set su board asciutto non si folda mai.';
    } else if (scenario.outs == 0) {
      explanation =
          'Mano Spazzatura: Nessun progetto né carta viva (0 outs).\n\n'
          'Verdetto: FOLD immediato. Evita di regalare fiches.';
    } else {
      final ruleDesc = scenario.mode == OddsRuleMode.ruleOf4
          ? '${scenario.outs} outs × 4${scenario.outs >= 8 ? " - 1%" : ""}'
          : '${scenario.outs} outs × 2${scenario.outs >= 8 ? " + 1%" : ""}';

      final betDesc = scenario.isAllIn
          ? 'All-in (\$${scenario.callAmount.toInt()} su Stack di \$${scenario.userStack.toInt()}) → Richiede 51% base'
          : 'Bet: \$${scenario.callAmount.toInt()} su Piatto di \$${scenario.pot.toInt()} (~${scenario.betSize.label}, base: ${scenario.betSize.requiredEquity.toStringAsFixed(0)}%)';

      explanation =
          'Progetto: ${scenario.drawDescription} (${scenario.outs} outs)\n'
          'Tua Equity: ${scenario.estimatedEquity.toStringAsFixed(1)}% ($ruleDesc)\n'
          '$betDesc\n'
          'Sconto ${scenario.playerCount} Giocatori: -${scenario.multiwayDiscount.toStringAsFixed(0)}%\n'
          'Equity Richiesta Effettiva: ${scenario.adjustedRequiredEquity.toStringAsFixed(1)}%\n\n'
          'Verdetto: ${scenario.estimatedEquity.toStringAsFixed(1)}% ${shouldCall ? "≥" : "<"} ${scenario.adjustedRequiredEquity.toStringAsFixed(1)}% '
          '→ ${shouldCall ? "CALL CORRETTO (+EV)" : "FOLD CORRETTO (-EV)"}';
    }

    _feedback = OddsFeedback(
      isCorrect: userWasCorrect,
      title: userWasCorrect ? 'Decisione Corretta!' : 'Decisione Sbagliata!',
      explanation: explanation,
    );

    notifyListeners();
  }

  OddsTrainingScenario _generateProceduralScenario(OddsRuleMode mode) {
    final boardCount = mode == OddsRuleMode.ruleOf4 ? 3 : 4;
    final roll = _random.nextInt(100);

    List<Card> hole;
    List<Card> board;
    String drawDesc;
    int outs;
    bool isDominant = false;

    if (roll < 12) {
      final generated = _buildTrashHand(boardCount);
      hole = generated.$1;
      board = generated.$2;
      drawDesc = 'Mano Spazzatura (No Draw)';
      outs = 0;
    } else if (roll < 22) {
      final generated = _buildGutshot(boardCount);
      hole = generated.$1;
      board = generated.$2;
      drawDesc = 'Gutshot (Scala a Incastro)';
      outs = 4;
    } else if (roll < 34) {
      final generated = _buildOvercards(boardCount);
      hole = generated.$1;
      board = generated.$2;
      drawDesc = '2 Overcards su Board Basso';
      outs = 6;
    } else if (roll < 48) {
      final generated = _buildOesd(boardCount);
      hole = generated.$1;
      board = generated.$2;
      drawDesc = 'Scala Bilaterale (OESD)';
      outs = 8;
    } else if (roll < 64) {
      final generated = _buildFlushDraw(boardCount);
      hole = generated.$1;
      board = generated.$2;
      drawDesc = 'Flush Draw (Colore)';
      outs = 9;
    } else if (roll < 74) {
      final generated = _buildComboDraw(boardCount);
      hole = generated.$1;
      board = generated.$2;
      drawDesc = 'Combo Draw (Flush Draw + Gutshot)';
      outs = 12;
    } else if (roll < 82) {
      final generated = _buildMonsterDraw(boardCount);
      hole = generated.$1;
      board = generated.$2;
      drawDesc = 'Monster Draw (Flush Draw + Bilaterale)';
      outs = 15;
    } else if (roll < 91) {
      final generated = _buildSetOnWetBoard(boardCount);
      hole = generated.$1;
      board = generated.$2;
      drawDesc = 'Set su Board Pericoloso (insegui Full/Poker vs Colore)';
      outs = 7;
    } else {
      final generated = _buildSetDominant(boardCount);
      hole = generated.$1;
      board = generated.$2;
      drawDesc = 'Set Servito su Board Asciutto (Mano Dominante)';
      outs = 0;
      isDominant = true;
    }

    // --- GENERATORE REALISTICO PARTITA CASALINGA (4-10 Player, Bankroll 2000$) ---
    final playerCount = 4 + _random.nextInt(7); // da 4 a 10 giocatori
    
    // Distribuzione dello stack in base ai presenti (totale 2000$)
    final double startingStack = switch (playerCount) {
      >= 9 => 200.0,
      >= 7 => 250.0,
      >= 5 => 350.0,
      _ => 500.0,
    };

    // Estrazione della FASE DI GIOCO (Early, Mid, Late/Deep)
    final gameStageRoll = _random.nextInt(100);
    double userStack;
    double rawPot;

    if (gameStageRoll < 35) {
      // 1. INIZIO PARTITA (Early stage - Bui 1/2 o 2/5, piatti piccoli e controllati)
      userStack = _roundToChipSize(startingStack * (0.85 + _random.nextDouble() * 0.3));
      rawPot = _roundToChipSize(6.0 + _random.nextInt(10) * 2.0); // Piatti tra $6 e $26
    } else if (gameStageRoll < 75) {
      // 2. FASE INTERMEDIA (Mid stage - Bui 5/10 o 10/20, piatti medi)
      userStack = _roundToChipSize(startingStack * (0.6 + _random.nextDouble() * 0.9));
      rawPot = _roundToChipSize(25.0 + _random.nextInt(12) * 10.0); // Piatti tra $25 e $145
    } else {
      // 3. FASE AVANZATA / PIATTO GROSSO (Late stage - Bui alti o scontro profondo)
      userStack = _roundToChipSize(startingStack * (0.5 + _random.nextDouble() * 1.5));
      if (userStack > 1000) userStack = 1000;
      rawPot = _roundToChipSize(100.0 + _random.nextInt(15) * 20.0); // Piatti tra $100 e $400
    }

    // Scelta della dimensione di puntata dalla tabella
    final bet = BetSizeCategory.values[_random.nextInt(BetSizeCategory.values.length)];

    double rawCall = rawPot * bet.potMultiplier;
    double finalCall;

    // Gestione dell'ALL-IN (se pescato all-in o se la bet copre lo stack dell'utente)
    if (bet == BetSizeCategory.allIn || rawCall >= userStack) {
      finalCall = userStack;
    } else {
      finalCall = _roundToChipSize(rawCall);
      if (finalCall < 2.0) finalCall = 2.0; // Minimo grande buio
    }

    return OddsTrainingScenario(
      holeCards: hole,
      boardCards: board,
      drawDescription: drawDesc,
      outs: outs,
      betSize: bet,
      pot: rawPot,
      callAmount: finalCall,
      userStack: userStack,
      playerCount: playerCount,
      mode: mode,
      isDominantMadeHand: isDominant,
    );
  }

  double _roundToChipSize(double amount) {
    if (amount <= 10) return (amount / 2).round() * 2.0; // fiches da 1$ o 2$
    if (amount <= 50) return (amount / 5).round() * 5.0; // fiches da 5$
    if (amount <= 200) return (amount / 10).round() * 10.0; // fiches da 10$ o 20$
    return (amount / 20).round() * 20.0; // fiches da 20$, 50$ o 100$
  }

  // --- BUILDERS DELLE CARTE (INVARIATI) ---
  CardSuit _pickRandomSuit() => CardSuit.values[_random.nextInt(CardSuit.values.length)];

  (List<Card>, List<Card>) _buildFlushDraw(int boardCount) {
    final flushSuit = _pickRandomSuit();
    final otherSuits = CardSuit.values.where((s) => s != flushSuit).toList();
    final allRanks = List<CardRank>.from(CardRank.values)..shuffle(_random);
    final hole = [Card(suit: flushSuit, rank: allRanks[0]), Card(suit: flushSuit, rank: allRanks[1])];
    final board = [
      Card(suit: flushSuit, rank: allRanks[2]),
      Card(suit: flushSuit, rank: allRanks[3]),
      Card(suit: otherSuits[_random.nextInt(otherSuits.length)], rank: allRanks[4]),
    ];
    if (boardCount == 4) {
      board.add(Card(suit: otherSuits[_random.nextInt(otherSuits.length)], rank: allRanks[5]));
    }
    return (hole, board);
  }

  (List<Card>, List<Card>) _buildOesd(int boardCount) {
    final baseIndex = 2 + _random.nextInt(6);
    final suits = List<CardSuit>.from(CardSuit.values)..shuffle(_random);
    final hole = [Card(suit: suits[0], rank: CardRank.values[baseIndex + 1]), Card(suit: suits[1], rank: CardRank.values[baseIndex + 2])];
    final board = [
      Card(suit: suits[2], rank: CardRank.values[baseIndex]),
      Card(suit: suits[3], rank: CardRank.values[baseIndex + 3]),
      Card(suit: suits[0], rank: CardRank.two),
    ];
    if (boardCount == 4) {
      board.add(Card(suit: suits[1], rank: CardRank.ace));
    }
    return (hole, board);
  }

  (List<Card>, List<Card>) _buildGutshot(int boardCount) {
    final baseIndex = 3 + _random.nextInt(5);
    final suits = List<CardSuit>.from(CardSuit.values)..shuffle(_random);
    final hole = [Card(suit: suits[0], rank: CardRank.values[baseIndex]), Card(suit: suits[1], rank: CardRank.values[baseIndex + 1])];
    final board = [
      Card(suit: suits[2], rank: CardRank.values[baseIndex + 3]),
      Card(suit: suits[3], rank: CardRank.values[baseIndex + 4]),
      Card(suit: suits[0], rank: CardRank.two),
    ];
    if (boardCount == 4) {
      board.add(Card(suit: suits[1], rank: CardRank.ace));
    }
    return (hole, board);
  }

  (List<Card>, List<Card>) _buildOvercards(int boardCount) {
    final suits = List<CardSuit>.from(CardSuit.values)..shuffle(_random);
    final hole = [Card(suit: suits[0], rank: CardRank.ace), Card(suit: suits[1], rank: CardRank.king)];
    final board = [
      Card(suit: suits[2], rank: CardRank.eight),
      Card(suit: suits[3], rank: CardRank.four),
      Card(suit: suits[1], rank: CardRank.two),
    ];
    if (boardCount == 4) {
      board.add(Card(suit: suits[0], rank: CardRank.six));
    }
    return (hole, board);
  }

  (List<Card>, List<Card>) _buildComboDraw(int boardCount) {
    final flushSuit = _pickRandomSuit();
    final otherSuits = CardSuit.values.where((s) => s != flushSuit).toList();
    final hole = [Card(suit: flushSuit, rank: CardRank.jack), Card(suit: flushSuit, rank: CardRank.ten)];
    final board = [
      Card(suit: flushSuit, rank: CardRank.eight),
      Card(suit: flushSuit, rank: CardRank.seven),
      Card(suit: otherSuits[0], rank: CardRank.two),
    ];
    if (boardCount == 4) {
      board.add(Card(suit: otherSuits[1], rank: CardRank.four));
    }
    return (hole, board);
  }

  (List<Card>, List<Card>) _buildMonsterDraw(int boardCount) {
    final flushSuit = _pickRandomSuit();
    final otherSuits = CardSuit.values.where((s) => s != flushSuit).toList();
    final hole = [Card(suit: flushSuit, rank: CardRank.nine), Card(suit: flushSuit, rank: CardRank.eight)];
    final board = [
      Card(suit: flushSuit, rank: CardRank.seven),
      Card(suit: flushSuit, rank: CardRank.six),
      Card(suit: otherSuits[0], rank: CardRank.two),
    ];
    if (boardCount == 4) {
      board.add(Card(suit: otherSuits[1], rank: CardRank.king));
    }
    return (hole, board);
  }

  (List<Card>, List<Card>) _buildSetOnWetBoard(int boardCount) {
    final flushSuit = _pickRandomSuit();
    final otherSuits = CardSuit.values.where((s) => s != flushSuit).toList();
    final setRank = CardRank.values[3 + _random.nextInt(6)];
    final hole = [Card(suit: otherSuits[0], rank: setRank), Card(suit: otherSuits[1], rank: setRank)];
    final board = [
      Card(suit: flushSuit, rank: setRank),
      Card(suit: flushSuit, rank: CardRank.ace),
      Card(suit: flushSuit, rank: CardRank.ten),
    ];
    if (boardCount == 4) {
      board.add(Card(suit: otherSuits[0], rank: CardRank.two));
    }
    return (hole, board);
  }

  (List<Card>, List<Card>) _buildSetDominant(int boardCount) {
    final suits = List<CardSuit>.from(CardSuit.values)..shuffle(_random);
    final setRank = CardRank.values[4 + _random.nextInt(6)];
    final hole = [Card(suit: suits[0], rank: setRank), Card(suit: suits[1], rank: setRank)];
    final board = [
      Card(suit: suits[2], rank: setRank),
      Card(suit: suits[3], rank: CardRank.two),
      Card(suit: suits[0], rank: CardRank.eight),
    ];
    if (boardCount == 4) {
      board.add(Card(suit: suits[1], rank: CardRank.king));
    }
    return (hole, board);
  }

  (List<Card>, List<Card>) _buildTrashHand(int boardCount) {
    final suits = List<CardSuit>.from(CardSuit.values)..shuffle(_random);
    final hole = [Card(suit: suits[0], rank: CardRank.eight), Card(suit: suits[1], rank: CardRank.three)];
    final board = [
      Card(suit: suits[2], rank: CardRank.king),
      Card(suit: suits[3], rank: CardRank.jack),
      Card(suit: suits[0], rank: CardRank.four),
    ];
    if (boardCount == 4) {
      board.add(Card(suit: suits[1], rank: CardRank.two));
    }
    return (hole, board);
  }
}