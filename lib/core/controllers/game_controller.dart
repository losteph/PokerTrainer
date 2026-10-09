import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/deck.dart';
import '../models/game_state.dart';
import '../models/player_position.dart';
import '../models/player_position_scheme.dart';
import '../rules/starting_hand.dart';
import '../rules/starting_hand_matcher.dart';
import '../rules/starting_hand_range.dart';
import '../rules/strategic_range_provider.dart';

enum TrainingAction {
  fold,
  call,
}

enum TrainingFeedbackType {
  correct,
  mistake,
}

class TrainingFeedback {
  final TrainingFeedbackType type;
  final String message;

  const TrainingFeedback({
    required this.type,
    required this.message,
  });
}

class GameController extends ChangeNotifier {
  final Deck deck;

  GameState _gameState = const GameState();

  int? _playerCount;
  PlayerPosition? _playerPosition;

  List<Card> _holeCards = const [];
  TrainingFeedback? _feedback;

  GameController({
    Deck? deck,
  }) : deck = deck ?? Deck();

  GameState get gameState => _gameState;

  int? get playerCount => _playerCount;

  PlayerPosition? get playerPosition => _playerPosition;

  List<Card> get holeCards => List.unmodifiable(_holeCards);

  TrainingFeedback? get feedback => _feedback;

  StartingHand? get currentStartingHand {
    if (_holeCards.length != 2) {
      return null;
    }

    return StartingHandMatcher.fromCards(
      _holeCards[0],
      _holeCards[1],
    );
  }

  StartingHandRange get currentRange {
    if (_playerCount == null || _playerPosition == null) {
      return StartingHandRange();
    }

    return StrategicRangeProvider.getRange(
      playerCount: _playerCount!,
      position: _playerPosition!,
    );
  }

  void configureTable({
    required int playerCount,
    required PlayerPosition playerPosition,
  }) {
    final availablePositions = playerCount <= 3
        ? _specialPositions(playerCount)
        : PlayerPositionScheme.getForPlayerCount(playerCount);

    if (!availablePositions.contains(playerPosition)) {
      throw ArgumentError(
        'La posizione ${playerPosition.label} '
        'non è disponibile con $playerCount giocatori.',
      );
    }

    _playerCount = playerCount;
    _playerPosition = playerPosition;

    notifyListeners();
  }

  void startNewHand() {
    deck.reset();
    deck.shuffle();

    _holeCards = deck.drawMany(2);
    _feedback = null;
    _gameState = const GameState();

    notifyListeners();
  }

  void chooseAction(TrainingAction action) {
    final hand = currentStartingHand;
    if (hand == null) return;

    final inRange = currentRange.contains(hand);
    final isMiddlePosition = _playerPosition == PlayerPosition.mp ||
        _playerPosition == PlayerPosition.lj ||
        _playerPosition == PlayerPosition.hj;
    final isLowPair = hand.isPair && hand.highRank.index < CardRank.five.index; // 22, 33, 44

    // Caso speciale: 22-44 in Middle Position (concetto di Stack Effettivo / Set Mining)
    if (isMiddlePosition && isLowPair) {
      if (action == TrainingAction.fold) {
        _feedback = const TrainingFeedback(
          type: TrainingFeedbackType.correct,
          message: 'Corretto! Di base è Fold. (Nota: giocabile solo con Stack Effettivo > 15 BB per set value).',
        );
      } else {
        _feedback = const TrainingFeedback(
          type: TrainingFeedbackType.mistake,
          message: 'Errore: da Middle le coppie < 55 si foldano, a meno che lo Stack Effettivo non superi i 15 BB.',
        );
      }
      notifyListeners();
      return;
    }

    // Flusso standard per tutte le altre mani
    if (inRange) {
      if (action == TrainingAction.call) {
        _feedback = const TrainingFeedback(
          type: TrainingFeedbackType.correct,
          message: 'Corretto! La mano è nel range di apertura.',
        );
      } else {
        _feedback = const TrainingFeedback(
          type: TrainingFeedbackType.mistake,
          message: 'Errore: questa mano è giocabile, dovevi chiamare.',
        );
      }
    } else {
      if (action == TrainingAction.fold) {
        _feedback = const TrainingFeedback(
          type: TrainingFeedbackType.correct,
          message: 'Corretto! Mano fuori range, fold giusto.',
        );
      } else {
        _feedback = const TrainingFeedback(
          type: TrainingFeedbackType.mistake,
          message: 'Errore: mano fuori range, dovevi foldare.',
        );
      }
    }

    notifyListeners();
  }

  void setGamePhase(GamePhase phase) {
    _gameState = _gameState.copyWith(
      phase: phase,
    );

    notifyListeners();
  }

  void resetGame() {
    deck.reset();

    _gameState = const GameState();
    _holeCards = const [];
    _feedback = null;

    _playerCount = null;
    _playerPosition = null;

    notifyListeners();
  }

  List<PlayerPosition> _specialPositions(int playerCount) {
    switch (playerCount) {
      case 2:
        return const [
          PlayerPosition.sb,
          PlayerPosition.bb,
        ];

      case 3:
        return const [
          PlayerPosition.btn,
          PlayerPosition.sb,
          PlayerPosition.bb,
        ];

      default:
        throw ArgumentError(
          'Il numero di giocatori deve essere compreso tra 2 e 10.',
        );
    }
  }
}