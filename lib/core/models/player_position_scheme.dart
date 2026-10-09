import 'player_position.dart';

class PlayerPositionScheme {
  const PlayerPositionScheme._();

  static List<PlayerPosition> getForPlayerCount(
    int playerCount,
  ) {
    if (playerCount < 2 || playerCount > 10) {
      throw ArgumentError(
        'Il numero di giocatori deve essere compreso tra 2 e 10.',
      );
    }

    switch (playerCount) {
      case 10:
        return const [
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
        ];

      case 9:
        return const [
          PlayerPosition.utg,
          PlayerPosition.utg1,
          PlayerPosition.mp,
          PlayerPosition.lj,
          PlayerPosition.hj,
          PlayerPosition.co,
          PlayerPosition.btn,
          PlayerPosition.sb,
          PlayerPosition.bb,
        ];

      case 8:
        return const [
          PlayerPosition.utg,
          PlayerPosition.mp,
          PlayerPosition.lj,
          PlayerPosition.hj,
          PlayerPosition.co,
          PlayerPosition.btn,
          PlayerPosition.sb,
          PlayerPosition.bb,
        ];

      case 7:
        return const [
          PlayerPosition.mp,
          PlayerPosition.lj,
          PlayerPosition.hj,
          PlayerPosition.co,
          PlayerPosition.btn,
          PlayerPosition.sb,
          PlayerPosition.bb,
        ];

      case 6:
        return const [
          PlayerPosition.mp, // o lj
          PlayerPosition.hj,
          PlayerPosition.co,
          PlayerPosition.btn,
          PlayerPosition.sb,
          PlayerPosition.bb,
        ];

      case 5:
        return const [
          PlayerPosition.mp,
          PlayerPosition.co,
          PlayerPosition.btn,
          PlayerPosition.sb,
          PlayerPosition.bb,
        ];

      case 4:
        return const [
          PlayerPosition.co,
          PlayerPosition.btn,
          PlayerPosition.sb,
          PlayerPosition.bb,
        ];

      case 3:
      case 2:
        throw UnsupportedError(
          'Gli schemi per 2 e 3 giocatori '
          'usano regole specifiche e saranno gestiti separatamente.',
        );
    }

    throw StateError('Schema non gestito.');
  }
}