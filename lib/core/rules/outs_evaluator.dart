import '../models/card.dart';

class HandOutsAnalysis {
  final int totalOuts;
  final Set<Card> cleanOuts;
  final Set<Card> dirtyOuts;
  final String description;
  final bool isDominantMadeHand;
  final double effectiveOuts;

  const HandOutsAnalysis({
    required this.totalOuts,
    required this.cleanOuts,
    required this.dirtyOuts,
    required this.description,
    this.isDominantMadeHand = false,
    double? effectiveOuts,
  }) : effectiveOuts = effectiveOuts ?? 0.0;
}

class OutsEvaluator {
  static HandOutsAnalysis evaluate({
    required List<Card> hole,
    required List<Card> board,
  }) {
    if (hole.length != 2 || (board.length != 3 && board.length != 4)) {
      throw ArgumentError('Servono 2 carte private e 3 o 4 sul board.');
    }

    final known = [...hole, ...board];
    final used = known.map(_key).toSet();

    if (used.length != known.length) {
      throw ArgumentError('Carte duplicate nello scenario.');
    }

    final remaining = _remainingDeck(known);

    final made = _madeHand(hole, board);
    final madeName = made.$1;

    final clean = <Card>{};
    final dirty = <Card>{};
    final discounted = <Card>{};

    final hasFlush = _hasFlush(known);
    final hasStraight = _hasStraight(known);

    final counts = _counts(known);

    final isPocketSet =
        hole[0].rank == hole[1].rank &&
        board.any((c) => c.rank == hole[0].rank);

    final boardHasThreeOfSuit = CardSuit.values.any(
     (suit) => board.where((c) => c.suit == suit).length >= 3,
    );

    final boardHasFourOfSuit = CardSuit.values.any(
      (suit) => board.where((c) => c.suit == suit).length >= 4,
    );

    final boardHasPair =
        _counts(board).values.any((count) => count >= 2);

    bool flushDraw = false;
    bool straightDraw = false;

    // Un set su board monotone non e' automaticamente dominante.
    // Le carte che completano full o poker sono outs utili.
    if (isPocketSet) {
      final setRank = hole[0].rank;

      for (final candidate in remaining) {
        final makesQuads = candidate.rank == setRank;

        final makesFull = board.any(
          (b) => b.rank == candidate.rank && b.rank != setRank,
        );

        if (makesQuads || makesFull) {
          clean.add(candidate);
        }
      }

      final danger = boardHasThreeOfSuit
          ? ' - attenzione: possibile colore avversario'
          : boardHasPair
              ? ' - board accoppiato'
              : ' - set gia formato';

      return HandOutsAnalysis(
        totalOuts: clean.length,
        effectiveOuts: clean.length.toDouble(),
        cleanOuts: clean,
        dirtyOuts: dirty,
        description:
            'Set (tris con pocket pair)$danger; '
            '${clean.length} outs per full/poker',
        isDominantMadeHand: false,
      );
    }

    // Progetti che usano davvero le carte private.
    for (final candidate in remaining) {
      final after = [...known, candidate];

      final completesFlush = !hasFlush && _hasFlush(after);
      final completesStraight = !hasStraight && _hasStraight(after);

      if (!completesFlush && !completesStraight) continue;

      final personalFlush = completesFlush &&
          _bestFlushUsesHole(hole, board, candidate);

      final personalStraight = completesStraight &&
          _straightUsesHole(hole, board, candidate);

      if (!personalFlush && !personalStraight) {
        dirty.add(candidate);
        continue;
      }

      if (personalFlush) {
        flushDraw = true;

        // Se abbiamo A del seme del colore, e' il colore nuts.
        final flushSuit = candidate.suit;

        final hasNutAce = hole.any(
          (h) =>
              h.rank == CardRank.ace &&
              h.suit == flushSuit,
        );

        if (hasNutAce) {
          clean.add(candidate);
        } else {
          // Colore non nuts: resta utile, ma non garantito.
          // Non lo eliminiamo automaticamente.
          clean.add(candidate);
        }

        continue;
      }

      if (personalStraight) {
        straightDraw = true;

        if (_opponentFlushThreat(board, candidate)) {
          dirty.add(candidate);
        } else {
          clean.add(candidate);
        }
      }
    }

    // Overcard: contiamo per intero le carte che
    // formano una coppia superiore al board.
    final personalPair = _hasPersonalPair(hole, board);

    final maxBoard = board
        .map((c) => c.rank.index)
        .reduce((a, b) => a > b ? a : b);

    final twoOvercards =
        hole[0].rank != hole[1].rank &&
        hole.every((c) => c.rank.index > maxBoard);

    if (!personalPair && twoOvercards) {
      for (final candidate in remaining) {
        final makesPair = hole.any(
          (h) => h.rank == candidate.rank,
        );

        if (makesPair &&
            !_containsCard(clean, candidate) &&
            !_containsCard(dirty, candidate)) {
          clean.add(candidate);
        }
      }
    }

    // Coppia personale: le carte residue dello stesso
    // rango possono completare il tris.
    if (personalPair) {
      for (final candidate in remaining) {
        final matchingHole = hole.any(
          (h) => h.rank == candidate.rank,
        );

        if (matchingHole &&
            (counts[candidate.rank] ?? 0) == 2 &&
            !_containsCard(clean, candidate) &&
            !_containsCard(dirty, candidate)) {
          clean.add(candidate);
        }
      }
    }

    final effective = clean.length.toDouble();


    final parts = <String>[];

    if (madeName.isNotEmpty) {
      parts.add(madeName);
    }

    if (flushDraw && straightDraw) {
      parts.add('Progetto colore + scala');
    } else if (flushDraw) {
      parts.add('Progetto di colore');
    } else if (straightDraw) {
      parts.add('Progetto di scala');
    }

    final excluded = dirty.length;

    if (excluded > 0) {
      parts.add('$excluded outs a rischio esclusi');
    }

    if (boardHasFourOfSuit && !hasFlush) {
      parts.add('Attenzione: board con quattro carte dello stesso seme');
    }

    if (parts.isEmpty) {
      parts.add('Carta alta senza progetto riconosciuto');
    }

    // Non assegnare automaticamente 100% di equity a set,
    // tris, scala, colore o full: dipende dal board e dal range.
    return HandOutsAnalysis(
      totalOuts: clean.length,
      effectiveOuts: effective,
      cleanOuts: clean,
      dirtyOuts: dirty,
      description: parts.join(' + '),
      isDominantMadeHand: false,
    );
  }

  static String _key(Card card) =>
      '${card.rank.index}-${card.suit.index}';

  static bool _containsCard(Set<Card> cards, Card target) =>
      cards.any((card) =>
          card.rank == target.rank && card.suit == target.suit);

  static List<Card> _remainingDeck(List<Card> known) {
    final used = known.map(_key).toSet();
    final result = <Card>[];

    for (final suit in CardSuit.values) {
      for (final rank in CardRank.values) {
        final card = Card(suit: suit, rank: rank);
        if (!used.contains(_key(card))) {
          result.add(card);
        }
      }
    }

    return result;
  }

  static Map<CardRank, int> _counts(List<Card> cards) {
    final result = <CardRank, int>{};
    for (final card in cards) {
      result[card.rank] = (result[card.rank] ?? 0) + 1;
    }
    return result;
  }

  static bool _hasPersonalPair(
    List<Card> hole,
    List<Card> board,
  ) {
    if (hole[0].rank == hole[1].rank) return true;

    return hole.any(
      (h) => board.any((b) => b.rank == h.rank),
    );
  }

  static bool _hasFlush(List<Card> cards) {
    for (final suit in CardSuit.values) {
      if (cards.where((c) => c.suit == suit).length >= 5) {
        return true;
      }
    }
    return false;
  }

  static bool _hasStraight(List<Card> cards) {
    final ranks = cards.map((c) => c.rank.index).toSet();

    // CardRank segue l'ordine 2 ... A.
    if (ranks.contains(CardRank.ace.index)) {
      ranks.add(-1);
    }

    for (int start = -1; start <= 8; start++) {
      if (List.generate(5, (i) => start + i)
          .every(ranks.contains)) {
        return true;
      }
    }

    return false;
  }

  static bool _bestFlushUsesHole(
    List<Card> hole,
    List<Card> board,
    Card candidate,
  ) {
    final all = [...hole, ...board, candidate];

    for (final suit in CardSuit.values) {
      final suited = all.where((c) => c.suit == suit).toList();

      if (suited.length >= 5 &&
          hole.any((h) => h.suit == suit)) {
        return true;
      }
    }

    return false;
  }

  static bool _straightUsesHole(
    List<Card> hole,
    List<Card> board,
    Card candidate,
  ) {
    final all = [...hole, ...board, candidate];

    if (!_hasStraight(all)) return false;

    // Se togliendo entrambe le hole la scala resta sul board,
    // non e' un progetto personale.
    return !_hasStraight([...board, candidate]);
  }

  static bool _opponentFlushThreat(
    List<Card> board,
    Card candidate,
  ) {
    final withCandidate = [...board, candidate];

    for (final suit in CardSuit.values) {
      if (withCandidate.where((c) => c.suit == suit).length >= 3) {
        return true;
      }
    }

    return false;
  }

  static (String, bool) _madeHand(
    List<Card> hole,
    List<Card> board,
  ) {
    final all = [...hole, ...board];
    final counts = _counts(all);
    final boardCounts = _counts(board);

    final four = counts.values.any((n) => n == 4);
    final three = counts.values.any((n) => n >= 3);
    final pairRanks =
        counts.values.where((n) => n >= 2).length;

    final full = three && pairRanks >= 2;

    if (four) return ('Poker già formato', true);
    if (full) return ('Full house già formato', true);

    if (_hasFlush(all)) {
      return ('Colore già chiuso', true);
    }

    if (_hasStraight(all)) {
      return ('Scala già chiusa', true);
    }

    if (three) {
      final personalTrips = counts.entries.any(
        (entry) =>
            entry.value >= 3 &&
            hole.any((h) => h.rank == entry.key),
      );

      return (
        personalTrips
            ? 'Tris già formato'
            : 'Tris condiviso sul board',
        personalTrips,
      );
    }

    if (pairRanks >= 2) {
      return ('Doppia coppia già formata', false);
    }

    if (pairRanks == 1) {
      final boardPaired =
          boardCounts.values.any((n) => n >= 2);

      if (boardPaired && !_hasPersonalPair(hole, board)) {
        return ('Coppia sul board (condivisa)', false);
      }

      if (hole[0].rank == hole[1].rank) {
        return ('Pocket pair già formata', false);
      }

      final matchingHole = hole.where(
        (h) => board.any((b) => b.rank == h.rank),
      );

      if (matchingHole.isNotEmpty) {
        final maxBoard = board
            .map((c) => c.rank.index)
            .reduce((a, b) => a > b ? a : b);

        if (matchingHole.first.rank.index == maxBoard) {
          return ('Top pair già formata', false);
        }

        return ('Coppia personale già formata', false);
      }

      return ('Coppia già formata', false);
    }

    return ('', false);
  }
}