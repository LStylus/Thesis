import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/home_controller.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'features/game/presentation/picture_listen_preview_page.dart';
import 'features/game/presentation/gameplay_gallery_page.dart';
import 'features/game/presentation/sound_emphasis_preview_page.dart';
import 'features/game/presentation/falling_sound_bubbles_preview_page.dart';
import 'features/game/presentation/find_the_word_preview_page.dart';
import 'features/game/presentation/find_the_sound_preview_page.dart';
import 'features/game/presentation/sound_bucket_preview_page.dart';
import 'features/game/presentation/build_and_say_preview_page.dart';
import 'features/game/presentation/guided_training_path_preview_page.dart';
import 'features/game/presentation/listen_pop_repeat_preview_page.dart';
import 'views/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Open artwork previews directly, without initializing account services.
  final previewRoutes = <String, WidgetBuilder>{
    ListenPopRepeatPreviewPage.routeName: (context) => _previewWithBack(
      context,
      'Listen, Pop & Repeat',
      const ListenPopRepeatPreviewPage(),
    ),
    GuidedTrainingPathPreviewPage.routeName: (context) => _previewWithBack(
      context,
      'Guided Training Path',
      const GuidedTrainingPathPreviewPage(),
    ),
    SoundBucketPreviewPage.routeName: (context) => _previewWithBack(
      context,
      'Sound Bucket',
      const SoundBucketPreviewPage(),
    ),
    BuildAndSayPreviewPage.routeName: (context) => _previewWithBack(
      context,
      'Build & Say',
      const BuildAndSayPreviewPage(),
    ),
    FindTheSoundPreviewPage.routeName: (context) => Scaffold(
      appBar: AppBar(
        title: const Text('Find the Sound'),
        leading: IconButton(
          tooltip: 'Back to gameplay templates',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(
            context,
          ).pushReplacementNamed(GameplayGalleryPage.routeName),
        ),
      ),
      body: const FindTheSoundPreviewPage(),
    ),
    FindTheWordPreviewPage.routeName: (context) => Scaffold(
      appBar: AppBar(
        title: const Text('Find the Word'),
        leading: IconButton(
          tooltip: 'Back to gameplay templates',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(
            context,
          ).pushReplacementNamed(GameplayGalleryPage.routeName),
        ),
      ),
      body: const FindTheWordPreviewPage(),
    ),
    FallingSoundBubblesPreviewPage.routeName: (_) =>
        const FallingSoundBubblesPreviewPage(),
    SoundEmphasisPreviewPage.routeName: (_) => const SoundEmphasisPreviewPage(),
    PictureListenPreviewPage.routeName: (_) => const PictureListenPreviewPage(),
    GameplayGalleryPage.routeName: (_) => GameplayGalleryPage(
      onBackToMain: () {
        runApp(
          const MaterialApp(
            key: ValueKey('starting-main-app'),
            initialRoute: '/',
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          ),
        );
        _startMainApplication();
      },
    ),
  };
  final initialRoute =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  if (kDebugMode && previewRoutes.containsKey(initialRoute)) {
    runApp(
      MaterialApp(
        title: 'Voice Voyage Previews',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(
            settings: RouteSettings(name: initialRoute),
            builder: previewRoutes[initialRoute]!,
          ),
        ],
        routes: previewRoutes,
      ),
    );
    return;
  }

  await _startMainApplication();
}

Future<void> _startMainApplication() async {
  Object? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    firebaseError = e;
    debugPrint('Firebase init failed: $e\n$stack');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        Provider(create: (_) => HomeController()),
      ],
      child: VoiceVoyageApp(firebaseInitError: firebaseError),
    ),
  );
}

Widget _previewWithBack(BuildContext context, String title, Widget child) =>
    Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: 'Back to gameplay templates',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(
            context,
          ).pushReplacementNamed(GameplayGalleryPage.routeName),
        ),
      ),
      body: child,
    );

class VoiceVoyageApp extends StatelessWidget {
  final Object? firebaseInitError;

  const VoiceVoyageApp({super.key, this.firebaseInitError});

  @override
  Widget build(BuildContext context) {
    if (firebaseInitError != null) {
      return MaterialApp(
        key: const ValueKey('main-app-error'),
        initialRoute: '/',
        title: 'Voice Voyage',
        debugShowCheckedModeBanner: false,
        home: _FirebaseErrorScreen(error: firebaseInitError!),
      );
    }

    return MaterialApp(
      key: const ValueKey('main-app'),
      initialRoute: '/',
      title: 'Voice Voyage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class _FirebaseErrorScreen extends StatelessWidget {
  final Object error;

  const _FirebaseErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Firebase initialization failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Allow restarting the app programmatically
                    _startMainApplication();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
