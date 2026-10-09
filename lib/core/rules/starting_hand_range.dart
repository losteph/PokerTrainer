import 'starting_hand.dart';

class StartingHandRange {
  final Set<StartingHand> hands;

  StartingHandRange({
    Set<StartingHand>? hands,
  }) : hands = Set.unmodifiable(hands ?? {});

  bool contains(StartingHand hand) {
    return hands.contains(hand);
  }

  bool get isEmpty {
    return hands.isEmpty;
  }

  int get length {
    return hands.length;
  }

  StartingHandRange add(StartingHand hand) {
    final updatedHands = Set<StartingHand>.from(hands);
    updatedHands.add(hand);

    return StartingHandRange(
      hands: updatedHands,
    );
  }

  StartingHandRange addAll(
    Iterable<StartingHand> newHands,
  ) {
    final updatedHands = Set<StartingHand>.from(hands);
    updatedHands.addAll(newHands);

    return StartingHandRange(
      hands: updatedHands,
    );
  }

  @override
  String toString() {
    return hands
        .map((hand) => hand.notation)
        .join(', ');
  }
}