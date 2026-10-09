import 'starting_hand_parser.dart';
import 'starting_hand_range.dart';

class StartingHandRangeFactory {
  const StartingHandRangeFactory._();

  static StartingHandRange fromNotations(
    Iterable<String> notations,
  ) {
    final hands = StartingHandParser.parseAll(notations);

    return StartingHandRange(
      hands: hands.toSet(),
    );
  }
}