import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'views/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const VoiceVoyageApp());
}

class VoiceVoyageApp extends StatelessWidget {
  const VoiceVoyageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Voyage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF3F3F3),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF13B5EA)),
      ),
      home: const AuthGate(),
    );
  }
}
