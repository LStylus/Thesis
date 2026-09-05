import 'package:flutter/material.dart';

/// Navigation-only notice while the replacement games are unimplemented.
/// Does not start recording, assess speech, or write progress.
class GameplayUnavailablePage extends StatelessWidget {
  const GameplayUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'New gameplay system coming next.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to map'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
