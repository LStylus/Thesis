enum GameTemplateKind {
  soundBuilder,
  bucketSort,
  tapAndPop,
  minimalPairMatch,
  echoCave,
  sequenceJumper,
  voicePoweredJourney,
  soundMeterChallenge,
}

extension GameTemplateKindDetails on GameTemplateKind {
  String get templateId => switch (this) {
    GameTemplateKind.soundBuilder => 'sound_builder',
    GameTemplateKind.bucketSort => 'bucket_sort',
    GameTemplateKind.tapAndPop => 'tap_and_pop',
    GameTemplateKind.minimalPairMatch => 'minimal_pair_match',
    GameTemplateKind.echoCave => 'echo_cave',
    GameTemplateKind.sequenceJumper => 'sequence_jumper',
    GameTemplateKind.voicePoweredJourney => 'voice_powered_journey',
    GameTemplateKind.soundMeterChallenge => 'sound_meter_challenge',
  };

  String get title => switch (this) {
    GameTemplateKind.soundBuilder => 'Sound Builder',
    GameTemplateKind.bucketSort => 'Classroom Sort',
    GameTemplateKind.tapAndPop => 'Tap and Pop',
    GameTemplateKind.minimalPairMatch => 'Sound Match',
    GameTemplateKind.echoCave => 'Echo Crystal',
    GameTemplateKind.sequenceJumper => 'Sequence Trail',
    GameTemplateKind.voicePoweredJourney => 'Voice Bridge',
    GameTemplateKind.soundMeterChallenge => 'Sound Meter',
  };

  String get instruction => switch (this) {
    GameTemplateKind.soundBuilder =>
      'Build the word in order, then say it clearly.',
    GameTemplateKind.bucketSort =>
      'Drag the word token into the highlighted sound bin.',
    GameTemplateKind.tapAndPop =>
      'Find and pop the target word, then say it clearly.',
    GameTemplateKind.minimalPairMatch =>
      'Choose the card that matches the target word.',
    GameTemplateKind.echoCave => 'Tap the crystal, then repeat the caption.',
    GameTemplateKind.sequenceJumper =>
      'Tap the stepping stones in order, then say the word.',
    GameTemplateKind.voicePoweredJourney =>
      'Tap the sound orb, then use your voice to build the bridge.',
    GameTemplateKind.soundMeterChallenge =>
      'Tap the meter, then keep your voice clear until it fills.',
  };
}

enum GameDifficulty { supported, guided, independent }

enum GameHintLevel { full, visual, minimal }
