import '../models/card.dart';

class HandOutsAnalysis {
  final int totalOuts;
  final Set<Card> cleanOuts;
  final Set<Card> dirtyOuts;
  final String description;
  final bool isDominantMadeHand;

  const HandOutsAnalysis({
    required this.totalOuts,
    required this.cleanOuts,
    required this.dirtyOuts,
    required this.description,
    this.isDominantMadeHand = false,
  });
}

class OutsEvaluator {
  static HandOutsAnalysis evaluate({
    required List<Card> hole,
    required List<Card> board,
  }) {
    final allKnown = [...hole, ...board];

    // 0. VERIFICA PUNTI ASSOLUTI GIÀ CHIUSI (Poker o Full)
    if (_hasFourOfAKind(hole, board)) {
      return const HandOutsAnalysis(
        totalOuts: 0,
        cleanOuts: {},
        dirtyOuts: {},
        description: 'Poker Servito (Mano Imbattibile - Made Hand)',
        isDominantMadeHand: true,
      );
    }

    if (_hasFullHouse(hole, board)) {
      return const HandOutsAnalysis(
        totalOuts: 0,
        cleanOuts: {},
        dirtyOuts: {},
        description: 'Full Servito (Mano Dominante - Made Hand)',
        isDominantMadeHand: true,
      );
    }

    // CASO 1: Set da Pocket Pair (es. 7-7 in mano con un 7 a terra)
    if (_isPocketSet(hole, board)) {
      if (_isWetBoard(board)) {
        final outs = _getSetOuts(hole, board);
        return HandOutsAnalysis(
          totalOuts: outs.length,
          cleanOuts: outs,
          dirtyOuts: {},
          description: 'Set su Board Pericoloso (${outs.length} outs per Full/Poker)',
        );
      } else {
        return const HandOutsAnalysis(
          totalOuts: 0,
          cleanOuts: {},
          dirtyOuts: {},
          description: 'Set Servito su Board Asciutto (Mano Dominante)',
          isDominantMadeHand: true,
        );
      }
    }

    // CASO 2: Trips con carta singola in mano (es. 7-8 su 7-7-A o J-9 su J-J-K)
    if (_isBoardTrips(hole, board)) {
      return _evaluateTrips(hole, board);
    }

    // CASO 3: Progetti di Scala, Colore e Combo
    final remainingDeck = _getRemainingDeck(allKnown);
    final rawOuts = <Card>{};
    final alreadyHasFlush = _hasFlush(allKnown);
    final alreadyHasStraight = _hasStraight(allKnown);
    bool makesFlush = false;
    bool makesStraight = false;

    // Un out deve completare una combinazione che non era già presente.
    for (final candidate in remainingDeck) {
      final testCards = [...allKnown, candidate];
      final flush = !alreadyHasFlush && _hasFlush(testCards);
      final straight = !alreadyHasStraight && _hasStraight(testCards);

      if (flush || straight) {
        rawOuts.add(candidate);
        if (flush) makesFlush = true;
        if (straight) makesStraight = true;
      }
    }

    // Classifica ogni carta individualmente: non usare un unico flag globale
    // makesFlush per decidere se tutti gli outs di un seme siano puliti.
    final cleanOuts = <Card>{};
    final dirtyOuts = <Card>{};

    for (final out in rawOuts) {
      final completesOurFlush =
          !alreadyHasFlush && _hasFlush([...allKnown, out]);
      if (!completesOurFlush && _isFlushThreatSuit(board, out.suit)) {
        dirtyOuts.add(out);
      } else {
        cleanOuts.add(out);
      }
    }

    // CASO 4: Se non ci sono draw di colore/scala, verifichiamo le 2 Overcards
    if (rawOuts.isEmpty && _hasTwoOvercards(hole, board)) {
      final overcards = _getOvercardOuts(hole, allKnown);
      return HandOutsAnalysis(
        totalOuts: overcards.length,
        cleanOuts: overcards,
        dirtyOuts: {},
        description: '2 Overcards (${overcards.length} outs per Top Pair)',
      );
    }

    final count = cleanOuts.length;
    String desc;

    if (makesFlush && makesStraight) {
      desc = count >= 12 ? 'Monster Draw (Colore + Scala)' : 'Combo Draw';
    } else if (makesFlush) {
      desc = 'Flush Draw (Colore)';
    } else if (makesStraight) {
      final dirtyNote = dirtyOuts.isNotEmpty ? ' (${dirtyOuts.length} out sporchi scartati)' : '';
      desc = count >= 8 ? 'Scala Bilaterale (OESD)$dirtyNote' : 'Gutshot a Incastro$dirtyNote';
    } else if (count == 0) {
      desc = 'Mano Spazzatura (No Draw)';
    } else {
      desc = 'Progetto ($count outs)';
    }

    return HandOutsAnalysis(
      totalOuts: count,
      cleanOuts: cleanOuts,
      dirtyOuts: dirtyOuts,
      description: desc,
    );
  }

  // --- LOGICHE MATEMATICHE ---

  static bool _hasFourOfAKind(List<Card> hole, List<Card> board) {
    final all = [...hole, ...board];
    final counts = <CardRank, int>{};
    for (final c in all) {
      counts[c.rank] = (counts[c.rank] ?? 0) + 1;
      if (counts[c.rank]! >= 4) return true;
    }
    return false;
  }

  static bool _hasFullHouse(List<Card> hole, List<Card> board) {
    final all = [...hole, ...board];
    final counts = <CardRank, int>{};
    for (final c in all) {
      counts[c.rank] = (counts[c.rank] ?? 0) + 1;
    }
    final hasThree = counts.values.any((v) => v >= 3);
    final pairs = counts.values.where((v) => v >= 2).length;
    return hasThree && pairs >= 2;
  }

  static bool _isPocketSet(List<Card> hole, List<Card> board) {
    if (hole[0].rank != hole[1].rank) return false;
    return board.any((b) => b.rank == hole[0].rank);
  }

  static bool _isBoardTrips(List<Card> hole, List<Card> board) {
    final boardRanks = board.map((c) => c.rank).toList();
    for (final h in hole) {
      if (boardRanks.where((r) => r == h.rank).length >= 2) return true;
    }
    return false;
  }

  static HandOutsAnalysis _evaluateTrips(List<Card> hole, List<Card> board) {
    final tripsRank = hole.firstWhere(
      (h) => board.where((b) => b.rank == h.rank).length >= 2,
    ).rank;

    final kicker = hole.firstWhere((h) => h.rank != tripsRank);
    final boardOtherRanks = board.where((b) => b.rank != tripsRank).map((b) => b.rank).toList();

    final clean = <Card>{};
    final dirty = <Card>{};

    for (final suit in CardSuit.values) {
      // 1. Quarta carta uguale -> Poker (sempre Clean)
      final pokerCard = Card(suit: suit, rank: tripsRank);
      if (!hole.contains(pokerCard) && !board.contains(pokerCard)) {
        clean.add(pokerCard);
      }

      // 2. Carta uguale al nostro kicker -> Full imbattibile
      final kickerFull = Card(suit: suit, rank: kicker.rank);
      if (!hole.contains(kickerFull) && !board.contains(kickerFull)) {
        clean.add(kickerFull);
      }

      // 3. Carte che accoppiano le altre del board
      for (final otherRank in boardOtherRanks) {
        final pairCard = Card(suit: suit, rank: otherRank);
        if (!hole.contains(pairCard) && !board.contains(pairCard)) {
          if (otherRank.index > tripsRank.index) {
            dirty.add(pairCard); // Rischio overfull per l'avversario
          } else {
            clean.add(pairCard);
          }
        }
      }
    }

    return HandOutsAnalysis(
      totalOuts: clean.length,
      cleanOuts: clean,
      dirtyOuts: dirty,
      description: 'Trips con Kicker (${clean.length} outs puliti, ${dirty.length} esclusi per rischio overfull)',
    );
  }

  static bool _isWetBoard(List<Card> board) {
    final suits = <CardSuit, int>{};
    for (final b in board) {
      suits[b.suit] = (suits[b.suit] ?? 0) + 1;
      if (suits[b.suit]! >= 3) return true;
    }
    return false;
  }

  static Set<Card> _getSetOuts(List<Card> hole, List<Card> board) {
    final setRank = hole[0].rank;
    final outs = <Card>{};
    for (final suit in CardSuit.values) {
      final fourth = Card(suit: suit, rank: setRank);
      if (!hole.contains(fourth) && !board.contains(fourth)) outs.add(fourth);

      for (final b in board) {
        if (b.rank != setRank) {
          final pairUp = Card(suit: suit, rank: b.rank);
          if (!board.contains(pairUp)) outs.add(pairUp);
        }
      }
    }
    return outs;
  }

  static bool _isFlushThreatSuit(List<Card> board, CardSuit suit) {
    return board.where((card) => card.suit == suit).length >= 2;
  }

  static List<Card> _getRemainingDeck(List<Card> known) {
    final deck = <Card>[];
    for (final suit in CardSuit.values) {
      for (final rank in CardRank.values) {
        final card = Card(suit: suit, rank: rank);
        if (!known.any((k) => k.suit == card.suit && k.rank == card.rank)) {
          deck.add(card);
        }
      }
    }
    return deck;
  }

  static bool _hasFlush(List<Card> cards) {
    final counts = <CardSuit, int>{};
    for (final c in cards) {
      counts[c.suit] = (counts[c.suit] ?? 0) + 1;
      if (counts[c.suit]! >= 5) return true;
    }
    return false;
  }

  static bool _hasStraight(List<Card> cards) {
    final ranks = cards.map((c) => c.rank.index).toSet();
    if (ranks.contains(12)) ranks.add(-1);

    for (int start = -1; start <= 8; start++) {
      if (ranks.contains(start) &&
          ranks.contains(start + 1) &&
          ranks.contains(start + 2) &&
          ranks.contains(start + 3) &&
          ranks.contains(start + 4)) {
        return true;
      }
    }
    return false;
  }

  static bool _hasTwoOvercards(List<Card> hole, List<Card> board) {
    final maxBoardRank = board.map((c) => c.rank.index).reduce((a, b) => a > b ? a : b);
    return hole[0].rank.index > maxBoardRank && hole[1].rank.index > maxBoardRank;
  }

  static Set<Card> _getOvercardOuts(List<Card> hole, List<Card> known) {
    final outs = <Card>{};
    for (final suit in CardSuit.values) {
      final c1 = Card(suit: suit, rank: hole[0].rank);
      final c2 = Card(suit: suit, rank: hole[1].rank);
      if (!known.contains(c1)) outs.add(c1);
      if (!known.contains(c2)) outs.add(c2);
    }
    return outs;
  }
}