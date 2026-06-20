enum RoomType {
  start,
  normal,
  treasure,
  miniboss,
  elite,
  challenge,
  merchant,
  offering,
  upstairs,
  memory,
  boss,
}

extension RoomTypeLabel on RoomType {
  String get label {
    return switch (this) {
      RoomType.start => 'Start',
      RoomType.normal => 'Normal',
      RoomType.treasure => 'Treasure',
      RoomType.miniboss => 'Miniboss',
      RoomType.elite => 'Elite',
      RoomType.challenge => 'Challenge',
      RoomType.merchant => 'Offering',
      RoomType.offering => 'Offering',
      RoomType.upstairs => 'Stairs',
      RoomType.memory => 'Memory',
      RoomType.boss => 'Boss',
    };
  }

  String get icon {
    return switch (this) {
      RoomType.start => 'Start',
      RoomType.normal => 'Sword',
      RoomType.treasure => 'Gold',
      RoomType.miniboss => 'Horn',
      RoomType.elite => 'Skull',
      RoomType.challenge => 'Risk',
      RoomType.merchant => 'Altar',
      RoomType.offering => 'Altar',
      RoomType.upstairs => 'Stairs',
      RoomType.memory => 'Memory',
      RoomType.boss => 'Crown',
    };
  }

  String get description {
    return switch (this) {
      RoomType.start => 'The first chamber of this floor.',
      RoomType.normal => 'A standard combat room.',
      RoomType.treasure => 'No enemies. Gain Essence and a free blessing.',
      RoomType.miniboss => 'A single strong foe guards a reward.',
      RoomType.elite => 'Harder enemies. Clear for extra Essence.',
      RoomType.challenge => 'Take a curse now. Clear for a large reward.',
      RoomType.merchant => 'Spend Essence at an offering altar.',
      RoomType.offering => 'Spend Essence at an offering altar.',
      RoomType.upstairs => 'A stairway to the next floor.',
      RoomType.memory => 'A quiet chamber where a lost memory surfaces.',
      RoomType.boss => 'A boss waits at the end of the path.',
    };
  }
}
