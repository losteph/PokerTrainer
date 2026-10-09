import '../models/card.dart';
import 'starting_hand.dart';

class StartingHandParser {
  const StartingHandParser._();

  static List<StartingHand> parse(String notation) {
    final value = notation.trim().toUpperCase();

    if (value.isEmpty) {
      throw FormatException(
        'La notazione della starting hand non può essere vuota.',
      );
    }

    final hasPlus = value.endsWith('+');
    final base = hasPlus
        ? value.substring(0, value.length - 1)
        : value;

    if (base.contains('+')) {
      throw FormatException(
        'Il simbolo "+" può comparire solo alla fine della notazione.',
      );
    }

    if (base.length != 2 && base.length != 3) {
      throw FormatException(
        'Notazione non valida: "$notation".',
      );
    }

    final firstRank = _parseRank(base[0]);
    final secondRank = _parseRank(base[1]);

    if (firstRank == secondRank) {
      return _parsePair(
        rank: firstRank,
        hasPlus: hasPlus,
      );
    }

    if (base.length != 3) {
      throw FormatException(
        'Le mani non in coppia devono specificare "s" oppure "o": '
        '"$notation".',
      );
    }

    final type = _parseType(base[2]);

    if (hasPlus) {
      return _parseWithPlus(
        firstRank: firstRank,
        secondRank: secondRank,
        type: type,
      );
    }

    return [
      _createHand(
        firstRank,
        secondRank,
        type,
      ),
    ];
  }

  static List<StartingHand> parseAll(
    Iterable<String> notations,
  ) {
    final result = <StartingHand>[];

    for (final notation in notations) {
      result.addAll(parse(notation));
    }

    return result;
  }

  static List<StartingHand> _parsePair({
    required CardRank rank,
    required bool hasPlus,
  }) {
    if (!hasPlus) {
      return [
        StartingHand(
          highRank: rank,
          lowRank: rank,
          type: StartingHandType.pair,
        ),
      ];
    }

    final result = <StartingHand>[];

    for (
      var rankIndex = rank.index;
      rankIndex <= CardRank.ace.index;
      rankIndex++
    ) {
      final currentRank = CardRank.values[rankIndex];

      result.add(
        StartingHand(
          highRank: currentRank,
          lowRank: currentRank,
          type: StartingHandType.pair,
        ),
      );
    }

    return result;
  }

  static List<StartingHand> _parseWithPlus({
    required CardRank firstRank,
    required CardRank secondRank,
    required StartingHandType type,
  }) {
    final highRank = _higherRank(
      firstRank,
      secondRank,
    );

    final lowRank = _lowerRank(
      firstRank,
      secondRank,
    );

    if (_isFigure(highRank)) {
      return _parseHighCardPlus(
        highRank: highRank,
        lowRank: lowRank,
        type: type,
      );
    }

    return _parseDiagonalPlus(
      firstRank: firstRank,
      secondRank: secondRank,
      type: type,
    );
  }

  static List<StartingHand> _parseHighCardPlus({
    required CardRank highRank,
    required CardRank lowRank,
    required StartingHandType type,
  }) {
    final result = <StartingHand>[];

    for (
      var lowIndex = lowRank.index;
      lowIndex < highRank.index;
      lowIndex++
    ) {
      final currentLowRank = CardRank.values[lowIndex];

      result.add(
        _createHand(
          highRank,
          currentLowRank,
          type,
        ),
      );
    }

    return result;
  }

  static List<StartingHand> _parseDiagonalPlus({
    required CardRank firstRank,
    required CardRank secondRank,
    required StartingHandType type,
  }) {
    final result = <StartingHand>[];

    var firstIndex = firstRank.index;
    var secondIndex = secondRank.index;

    while (
      firstIndex <= CardRank.ace.index &&
      secondIndex <= CardRank.ace.index
    ) {
      final first = CardRank.values[firstIndex];
      final second = CardRank.values[secondIndex];

      if (first == second) {
        break;
      }

      result.add(
        _createHand(
          first,
          second,
          type,
        ),
      );

      firstIndex++;
      secondIndex++;
    }

    return result;
  }

  static StartingHand _createHand(
    CardRank firstRank,
    CardRank secondRank,
    StartingHandType type,
  ) {
    final highRank = _higherRank(
      firstRank,
      secondRank,
    );

    final lowRank = _lowerRank(
      firstRank,
      secondRank,
    );

    return StartingHand(
      highRank: highRank,
      lowRank: lowRank,
      type: type,
    );
  }

  static CardRank _higherRank(
    CardRank first,
    CardRank second,
  ) {
    return first.index >= second.index ? first : second;
  }

  static CardRank _lowerRank(
    CardRank first,
    CardRank second,
  ) {
    return first.index <= second.index ? first : second;
  }

  static bool _isFigure(CardRank rank) {
    return rank == CardRank.jack ||
        rank == CardRank.queen ||
        rank == CardRank.king ||
        rank == CardRank.ace;
  }

  static CardRank _parseRank(String value) {
    return switch (value) {
      '2' => CardRank.two,
      '3' => CardRank.three,
      '4' => CardRank.four,
      '5' => CardRank.five,
      '6' => CardRank.six,
      '7' => CardRank.seven,
      '8' => CardRank.eight,
      '9' => CardRank.nine,
      'T' => CardRank.ten,
      'J' => CardRank.jack,
      'Q' => CardRank.queen,
      'K' => CardRank.king,
      'A' => CardRank.ace,
      _ => throw FormatException(
        'Rank non valido: "$value".',
      ),
    };
  }

  static StartingHandType _parseType(String value) {
    return switch (value) {
      'S' => StartingHandType.suited,
      'O' => StartingHandType.offsuit,
      _ => throw FormatException(
        'Il tipo della mano deve essere "s" oppure "o".',
      ),
    };
  }
}