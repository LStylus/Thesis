import 'package:flutter/material.dart';

import '../domain/game_definition.dart';
import '../domain/game_stage.dart';
import 'picture_listen_preview_page.dart';
import 'sound_emphasis_preview_page.dart';
import 'falling_sound_bubbles_preview_page.dart';
import 'find_the_word_preview_page.dart';
import 'find_the_sound_preview_page.dart';
import 'sound_bucket_preview_page.dart';
import 'build_and_say_preview_page.dart';
import 'guided_training_path_preview_page.dart';
import 'listen_pop_repeat_preview_page.dart';

/// Temporary template browser; availability is separate from learner progress.
class GameplayGalleryPage extends StatelessWidget {
  const GameplayGalleryPage({super.key, this.onBackToMain});

  /// Direct development previews have no previous route to pop.
  final VoidCallback? onBackToMain;

  static const routeName = '/dev/gameplays';

  static final _previews = <GameDefinition, WidgetBuilder>{
    GameDefinition.listenPopAndRepeat: (_) =>
        const ListenPopRepeatPreviewPage(),
    GameDefinition.guidedTrainingPath: (_) =>
        const GuidedTrainingPathPreviewPage(),
    GameDefinition.soundBucket: (_) => const SoundBucketPreviewPage(),
    GameDefinition.buildAndSay: (_) => const BuildAndSayPreviewPage(),
    GameDefinition.findTheSound: (_) => const FindTheSoundPreviewPage(),
    GameDefinition.findTheWord: (_) => const FindTheWordPreviewPage(),
    GameDefinition.pictureListen: (_) => const PictureListenPreviewPage(),
    GameDefinition.soundEmphasis: (_) => const SoundEmphasisPreviewPage(),
    GameDefinition.fallingSoundBubbles: (_) =>
        const FallingSoundBubblesPreviewPage(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to main screen',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              onBackToMain?.call();
            }
          },
        ),
        title: const Text('Gameplay Templates'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          const Text(
            'Listen, Recognize and Guided Say templates are ready to preview. '
            'More templates are coming soon.',
          ),
          const SizedBox(height: 16),
          for (final stage in GameStage.values) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${stage.number}. ${stage.title}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final game in GameDefinition.values.where(
              (game) => game.stage == stage,
            ))
              Card(
                child: ListTile(
                  enabled: _previews.containsKey(game),
                  leading: Icon(
                    _previews.containsKey(game)
                        ? Icons.photo_library_outlined
                        : Icons.hourglass_empty,
                  ),
                  title: Text(game.title),
                  subtitle: Text(
                    game == GameDefinition.pictureListen ||
                            game == GameDefinition.soundEmphasis ||
                            game == GameDefinition.findTheWord ||
                            game == GameDefinition.findTheSound ||
                            game == GameDefinition.soundBucket ||
                            game == GameDefinition.buildAndSay ||
                            game == GameDefinition.guidedTrainingPath ||
                            game == GameDefinition.listenPopAndRepeat
                        ? 'Animation preview · temporary captions'
                        : game == GameDefinition.fallingSoundBubbles
                        ? 'Falling, popping & temporary captions'
                        : _previews.containsKey(game)
                        ? 'Layout preview'
                        : 'Coming soon',
                  ),
                  trailing: _previews.containsKey(game)
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: _previews.containsKey(game)
                      ? () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(title: Text(game.title)),
                              body: _previews[game]!(context),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
