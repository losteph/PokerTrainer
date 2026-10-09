enum PlayerPosition {
  utg,
  utg1,
  utg2,
  mp,
  lj,
  hj,
  co,
  btn,
  sb,
  bb,
}

extension PlayerPositionExtension on PlayerPosition {
  String get label {
    return switch (this) {
      PlayerPosition.utg => 'UTG',
      PlayerPosition.utg1 => 'UTG+1',
      PlayerPosition.utg2 => 'UTG+2',
      PlayerPosition.mp => 'MP',
      PlayerPosition.lj => 'LJ',
      PlayerPosition.hj => 'HJ',
      PlayerPosition.co => 'CO',
      PlayerPosition.btn => 'BTN',
      PlayerPosition.sb => 'SB',
      PlayerPosition.bb => 'BB',
    };
  }
}