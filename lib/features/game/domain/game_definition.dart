import 'game_stage.dart';

/// Design catalog only. None of these entries has an implementation or route.
/// IDs are explicit so future persistence need not depend on enum ordering.
enum GameDefinition {
  pictureListen('picture_listen', 'Picture Listen', GameStage.listen),
  soundEmphasis('sound_emphasis', 'Sound Emphasis', GameStage.listen),
  fallingSoundBubbles(
    'falling_sound_bubbles',
    'Falling Sound Bubbles',
    GameStage.listen,
  ),
  findTheWord('find_the_word', 'Find the Word', GameStage.recognize),
  findTheSound('find_the_sound', 'Find the Sound', GameStage.recognize),
  soundBucket('sound_bucket', 'Sound Bucket', GameStage.recognize),
  buildAndSay('build_and_say', 'Build & Say', GameStage.guidedSay),
  guidedTrainingPath(
    'guided_training_path',
    'Guided Training Path',
    GameStage.guidedSay,
  ),
  listenPopAndRepeat(
    'listen_pop_and_repeat',
    'Listen, Pop & Repeat',
    GameStage.guidedSay,
  ),
  forestDiscovery(
    'forest_discovery',
    'Forest Discovery',
    GameStage.independentSay,
  ),
  sillyMonster('silly_monster', 'Silly Monster', GameStage.independentSay),
  buildTheBridge(
    'build_the_bridge',
    'Build the Bridge',
    GameStage.independentSay,
  ),
  talkWithBuddy('talk_with_buddy', 'Talk With Buddy', GameStage.useInContext),
  missionRoleplay(
    'mission_roleplay',
    'Mission Roleplay',
    GameStage.useInContext,
  ),
  storyAdventure('story_adventure', 'Story Adventure', GameStage.useInContext);

  const GameDefinition(this.id, this.title, this.stage);

  final String id;
  final String title;
  final GameStage stage;
}
