import '../models/card.dart';

enum StartingHandType {
  pair,
  suited,
  offsuit,
}

class StartingHand {
  final CardRank highRank;
  final CardRank lowRank;
  final StartingHandType type;

  const StartingHand._({
    required this.highRank,
    required this.lowRank,
    required this.type,
  });

  factory StartingHand({
    required CardRank highRank,
    required CardRank lowRank,
    required StartingHandType type,
  }) {
    if (highRank.index < lowRank.index) {
      throw ArgumentError(
        'highRank deve essere maggiore o uguale a lowRank.',
      );
    }

    if (highRank == lowRank && type != StartingHandType.pair) {
      throw ArgumentError(
        'Una pocket pair deve avere tipo pair.',
      );
    }

    if (highRank != lowRank && type == StartingHandType.pair) {
      throw ArgumentError(
        'Una mano non-coppia non può avere tipo pair.',
      );
    }

    return StartingHand._(
      highRank: highRank,
      lowRank: lowRank,
      type: type,
    );
  }

  bool get isPair {
    return highRank == lowRank;
  }

  String get notation {
    if (isPair) {
      return '${highRank.shortName}${lowRank.shortName}';
    }

    final suffix = switch (type) {
      StartingHandType.pair => '',
      StartingHandType.suited => 's',
      StartingHandType.offsuit => 'o',
    };

    return '${highRank.shortName}${lowRank.shortName}$suffix';
  }

  @override
  String toString() {
    return notation;
  }

  @override
  bool operator ==(Object other) {
    return other is StartingHand &&
        other.highRank == highRank &&
        other.lowRank == lowRank &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(
      highRank,
      lowRank,
      type,
    );
  }
}

extension StartingHandRankExtension on CardRank {
  String get shortName {
    return switch (this) {
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
  }
}