import 'card.dart';

enum GamePhase {
  preFlop,
  flop,
  turn,
  river,
  showdown,
}

class GameState {
  final GamePhase phase;
  final List<Card> communityCards;

  const GameState({
    this.phase = GamePhase.preFlop,
    this.communityCards = const [],
  });

  GameState copyWith({
    GamePhase? phase,
    List<Card>? communityCards,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      communityCards: communityCards ?? this.communityCards,
    );
  }
}