enum RangeCategory {
  early('Early (UTG)'),
  middle('Middle (MP/LJ/HJ)'),
  late('Late (CO/BTN)'),
  smallBlind('Small Blind'),
  bigBlind('Big Blind');

  final String label;
  const RangeCategory(this.label);
}


class StrategicRanges {
  const StrategicRanges._();

  // ============================================================
  // 10-4 GIOCATORI
  // ============================================================

  static const List<String> early = [
    '88+',
    'AQo+',
    'KQs',
    'ATs+',
    'JTs',
    'T9s',
  ];

  static const List<String> middle = [
    '55+',
    'A2s+',
    'ATo+',
    'KJs+',
    'QJs',
    '98s',
    '87s',
    'QTs',
    'J9s',
  ];

  static const List<String> late = [
    '22+',
    'A2s+',
    'A2o+',
    'K2s+',
    'K2o+',
    'Q9s+',
    'Q9o+',
    '54s',
    '65s',
    '76s',
    '87s',
    '98s',
    'T9s',
    '64s',
    '75s',
    '86s',
    '97s',
    'T8s',
    'J9s',
    '76o',
    '87o',
    '98o',
    'JTo',
    'QTo',
    'T9o',
  ];

  static const List<String> smallBlind = [
    ...late,
    '43s',
    '53s',
    '65o',
    'J9o',
    'T8o',
    'QTo',
    'KTo',
    'KJo',
  ];

  // BB:
  // tutte le coppie + tutti gli assi + tutti i suited.
  static const List<String> bigBlind = [
    ...smallBlind,
  ];

  // ============================================================
  // 3 GIOCATORI
  // ============================================================

  static const List<String> threePlayerButton = [
    '22+',
    'A2s+',
    'A2o+',
    'K2s+',
    'K5o+',
    'Q2s+',
    'Q9o+',
    '43s+',
    '76o+',
    '53s+',
    '63s+',
  ];

  static const List<String> threePlayerSmallBlind = [
    '22+',
    'A2s+',
    'A2o+',
    'K5s+',
    'K9o+',
    'Q7s+',
    'QTo+',
    '54s+',
    '98s+',
    '75s+',
  ];

  static const List<String> threePlayerBigBlindCall = [
    '22',
    '33',
    '44',
    '55',
    '66',
    '77',
    '88',
  ];

  static const List<String> threePlayerBigBlindRaise = [
    '22+',
    'A2s+',
    'A5o+',
    'K7s+',
    'KTo+',
    '54s+',
  ];

  // ============================================================
  // 2 GIOCATORI
  // ============================================================

  static const List<String> headsUpSmallBlind = [
    '22+',
    'A2s+',
    'A2o+',
    'K2s+',
    'K2o+',
    'Q2s+',
    'Q2o+',
    'J2s+',
    'J5o+',
    '32s+',
    '43o+',
    '35s+',
    '25s+',
    '53o+',
    '63o+',
  ];

  static const List<String> headsUpBigBlind = [
    '22+',
    'A2s+',
    'A5o+',
    'K5s+',
    'K9o+',
    'Q8s+',
    'QJo+',
    '65s+',
  ];
}