import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/home_controller.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'views/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

class VoiceVoyageApp extends StatelessWidget {
  final Object? firebaseInitError;

  const VoiceVoyageApp({super.key, this.firebaseInitError});

  @override
  Widget build(BuildContext context) {
    if (firebaseInitError != null) {
      return MaterialApp(
        title: 'Voice Voyage',
        debugShowCheckedModeBanner: false,
        home: _FirebaseErrorScreen(error: firebaseInitError!),
      );
    }

    return MaterialApp(
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
                    main();
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
