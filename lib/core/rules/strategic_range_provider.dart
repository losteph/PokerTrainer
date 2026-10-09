import '../models/card.dart';
import '../models/player_position.dart';
import 'starting_hand.dart';
import 'starting_hand_parser.dart';
import 'starting_hand_range.dart';
import 'strategic_range_definition.dart';
import 'strategic_ranges.dart';

class StrategicRangeProvider {
  const StrategicRangeProvider._();

  static StartingHandRange getRange({
    required int playerCount,
    required PlayerPosition position,
  }) {
    final definition = _getDefinition(
      playerCount: playerCount,
      position: position,
    );

    return _buildRange(definition);
  }

  static StartingHandRange _buildRange(
    StrategicRangeDefinition definition,
  ) {
    final hands = <StartingHand>{};

    hands.addAll(
      StartingHandParser.parseAll(
        definition.notations,
      ),
    );

    if (definition.allPairs) {
      hands.addAll(
        StartingHandParser.parse('22+'),
      );
    }

    if (definition.allAces) {
      hands.addAll(
        StartingHandParser.parseAll([
          'A2s+',
          'A2o+',
        ]),
      );
    }

    if (definition.allSuited) {
      hands.addAll(
        _allSuitedHands(),
      );
    }

    return StartingHandRange(
      hands: hands,
    );
  }

  static StrategicRangeDefinition _getDefinition({
    required int playerCount,
    required PlayerPosition position,
  }) {
    if (playerCount < 2 || playerCount > 10) {
      throw ArgumentError(
        'Il numero di giocatori deve essere compreso tra 2 e 10.',
      );
    }

    if (playerCount == 3) {
      return _getThreePlayerDefinition(position);
    }

    if (playerCount == 2) {
      return _getHeadsUpDefinition(position);
    }

    return _getStandardDefinition(
      playerCount: playerCount,
      position: position,
    );
  }

  static StrategicRangeDefinition _getStandardDefinition({
    required int playerCount,
    required PlayerPosition position,
  }) {
    final availablePositions =
        _standardPositionsByPlayerCount[playerCount];

    if (availablePositions == null ||
        !availablePositions.contains(position)) {
      throw ArgumentError(
        'La posizione ${position.label} non è disponibile '
        'con $playerCount giocatori.',
      );
    }

    switch (position) {
      case PlayerPosition.utg:
      case PlayerPosition.utg1:
      case PlayerPosition.utg2:
        return StrategicRangeDefinition(
          notations: StrategicRanges.early,
        );

      case PlayerPosition.mp:
      case PlayerPosition.lj:
      case PlayerPosition.hj:
        return StrategicRangeDefinition(
          notations: StrategicRanges.middle,
        );

      case PlayerPosition.co:
      case PlayerPosition.btn:
        return StrategicRangeDefinition(
          notations: StrategicRanges.late,
        );

      case PlayerPosition.sb:
        return StrategicRangeDefinition(
          notations: StrategicRanges.smallBlind,
        );

      case PlayerPosition.bb:
        return const StrategicRangeDefinition(
          allPairs: true,
          allAces: true,
          allSuited: true,
        );
    }
  }

  static StrategicRangeDefinition _getThreePlayerDefinition(
    PlayerPosition position,
  ) {
    switch (position) {
      case PlayerPosition.btn:
        return StrategicRangeDefinition(
          notations: StrategicRanges.threePlayerButton,
        );

      case PlayerPosition.sb:
        return StrategicRangeDefinition(
          notations: StrategicRanges.threePlayerSmallBlind,
        );

      case PlayerPosition.bb:
        return StrategicRangeDefinition(
          notations: [
            ...StrategicRanges.threePlayerBigBlindCall,
            ...StrategicRanges.threePlayerBigBlindRaise,
          ],
        );

      default:
        throw ArgumentError(
          'La posizione ${position.label} non è valida '
          'con 3 giocatori.',
        );
    }
  }

  static StrategicRangeDefinition _getHeadsUpDefinition(
    PlayerPosition position,
  ) {
    switch (position) {
      case PlayerPosition.btn:
      case PlayerPosition.sb:
        return StrategicRangeDefinition(
          notations: StrategicRanges.headsUpSmallBlind,
        );

      case PlayerPosition.bb:
        return StrategicRangeDefinition(
          notations: StrategicRanges.headsUpBigBlind,
        );

      default:
        throw ArgumentError(
          'La posizione ${position.label} non è valida '
          'con 2 giocatori.',
        );
    }
  }

  static const Map<int, Set<PlayerPosition>>
      _standardPositionsByPlayerCount = {
    10: {
      PlayerPosition.utg,
      PlayerPosition.utg1,
      PlayerPosition.utg2,
      PlayerPosition.mp,
      PlayerPosition.lj,
      PlayerPosition.hj,
      PlayerPosition.co,
      PlayerPosition.btn,
      PlayerPosition.sb,
      PlayerPosition.bb,
    },
    9: {
      PlayerPosition.utg,
      PlayerPosition.utg1,
      PlayerPosition.mp,
      PlayerPosition.hj,
      PlayerPosition.lj,
      PlayerPosition.co,
      PlayerPosition.btn,
      PlayerPosition.sb,
      PlayerPosition.bb,
    },
    8: {
      PlayerPosition.utg,
      PlayerPosition.mp,
      PlayerPosition.lj,
      PlayerPosition.hj,
      PlayerPosition.co,
      PlayerPosition.btn,
      PlayerPosition.sb,
      PlayerPosition.bb,
    },
    7: {
      PlayerPosition.mp,
      PlayerPosition.lj,
      PlayerPosition.hj,
      PlayerPosition.co,
      PlayerPosition.btn,
      PlayerPosition.sb,
      PlayerPosition.bb,
    },
    6: {
      PlayerPosition.mp,
      PlayerPosition.lj,
      PlayerPosition.co,
      PlayerPosition.btn,
      PlayerPosition.sb,
      PlayerPosition.bb,
    },
    5: {
      PlayerPosition.mp,
      PlayerPosition.co,
      PlayerPosition.btn,
      PlayerPosition.sb,
      PlayerPosition.bb,
    },
    4: {
      PlayerPosition.co,
      PlayerPosition.btn,
      PlayerPosition.sb,
      PlayerPosition.bb,
    },
  };

  static Set<StartingHand> _allSuitedHands() {
    final result = <StartingHand>{};

    for (
      var highIndex = 1;
      highIndex <= CardRank.ace.index;
      highIndex++
    ) {
      for (
        var lowIndex = 0;
        lowIndex < highIndex;
        lowIndex++
      ) {
        final high = _rankSymbol(highIndex);
        final low = _rankSymbol(lowIndex);

        result.addAll(
          StartingHandParser.parse(
            '$high${low}s',
          ),
        );
      }
    }

    return result;
  }

  static String _rankSymbol(int index) {
    return switch (index) {
      0 => '2',
      1 => '3',
      2 => '4',
      3 => '5',
      4 => '6',
      5 => '7',
      6 => '8',
      7 => '9',
      8 => 'T',
      9 => 'J',
      10 => 'Q',
      11 => 'K',
      12 => 'A',
      _ => throw StateError(
        'Indice rank non valido: $index',
      ),
    };
  }
}