class AppAssets {
  static const String whaleMascot = 'assets/characters/whale.svg';

  static const String playButton = 'assets/icons/play_button.png';
  static const String microphoneButton = 'assets/icons/microphone_button.png';
  static const String nextButton = 'assets/icons/next_button.png';
  static const String tryAgainButton = 'assets/icons/try_again_button.png';

  static const String levelOneThreeInstructionAudio =
      'audio/main_audio/prompt_voice/level1-3-instruction.mp3';
  static const String finalLevelInstructionAudio =
      'audio/main_audio/prompt_voice/final-level-instruction(lvl4).mp3';
  static const String almostThereAudio =
      'audio/main_audio/prompt_voice/almost-there-say-it-again.mp3';
  static const String goodJobAudio =
      'audio/main_audio/prompt_voice/Good Job.mp3';
  static const String quiteNotRightAudio =
      'audio/main_audio/prompt_voice/quite-not-right.mp3';
  static const String youreDoingGreatAudio =
      'audio/main_audio/prompt_voice/youre-doing-great.mp3';

  static String gameplayWordAudio(String word) {
    return 'audio/main_audio/main-content-audio/$word.mp3';
  }
}
