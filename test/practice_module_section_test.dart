import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/models/learning_module_model.dart';
import 'package:thesis/widgets/practice_module_section.dart';

LearningModuleModel _module() {
  return LearningModuleModel.fromMap(const {
    'module_id': 'mod-test',
    'focus_sounds': ['s'],
    'focus_processes': ['Stopping'],
    'outline_id': 'stopping-s',
    'outline_title': 'Stopping: /s/ practice',
    'levels': [
      {
        'level': 'syllable',
        'items': [
          {'text': 'sa', 'target_sound': '', 'position': ''},
          {'text': 'see', 'target_sound': '', 'position': ''},
        ],
      },
      {
        'level': 'word',
        'items': [
          {'text': 'sea', 'target_sound': '', 'position': ''},
        ],
      },
      {
        'level': 'phrase',
        'items': [
          {'text': 'see the sea', 'target_sound': '', 'position': ''},
        ],
      },
      {
        'level': 'sentence',
        'items': [
          {'text': 'I see a sock.', 'target_sound': '', 'position': ''},
        ],
      },
    ],
    'rationale': 'Age 5: eliminating stopping of initial /s/.',
    'generated_by': 'llm',
  });
}

void main() {
  testWidgets('renders the produced module as text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PracticeModuleSection(module: _module()),
          ),
        ),
      ),
    );

    expect(find.text('Practice module'), findsOneWidget);
    expect(find.text('Stopping: /s/ practice'), findsOneWidget);
    expect(find.text('Focus sounds: / s'), findsOneWidget);
    expect(find.text('Targets: Stopping'), findsOneWidget);
    expect(
      find.text('Age 5: eliminating stopping of initial /s/.'),
      findsOneWidget,
    );

    // Level labels
    expect(find.text('Syllables'), findsOneWidget);
    expect(find.text('Words'), findsOneWidget);
    expect(find.text('Phrases'), findsOneWidget);
    expect(find.text('Sentences'), findsOneWidget);

    // Item chips
    expect(find.text('sa'), findsOneWidget);
    expect(find.text('see'), findsOneWidget);
    expect(find.text('sea'), findsOneWidget);
    expect(find.text('see the sea'), findsOneWidget);
    expect(find.text('I see a sock.'), findsOneWidget);
  });

  testWidgets('hides level groups with no items', (tester) async {
    final module = LearningModuleModel.fromMap(const {
      'module_id': 'm',
      'focus_sounds': [],
      'focus_processes': [],
      'outline_id': 'o',
      'outline_title': 'T',
      'levels': [
        {'level': 'word', 'items': []},
      ],
      'rationale': '',
      'generated_by': 'llm',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PracticeModuleSection(module: module)),
      ),
    );

    expect(find.text('T'), findsOneWidget);
    expect(find.text('Words'), findsNothing);
    expect(find.text('Focus sounds:'), findsNothing);
  });
}
