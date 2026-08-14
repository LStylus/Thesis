import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/models/learning_module_model.dart';
import 'package:thesis/models/profile_model.dart';
import 'package:thesis/services/learning_module_store.dart';
import 'package:thesis/views/home/child_profile_page.dart';

ProfileModel _profile() {
  return ProfileModel.fromMap(const {
    'profileId': 'p1',
    'userId': 'u1',
    'email': 'parent@test.com',
    'progressId': 'prog1',
    'birthDate': '2020-06-15',
    'categoryId': 'cat1',
    'courseNo': 'course1',
    'parentName': 'Parent',
    'relationshipToChild': 'Mother',
    'childName': 'Maya',
    'profileAssetPath': 'assets/profiles/dolphin.svg',
  });
}

void main() {
  testWidgets('profile panel shows child name and age', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChildProfilePage(
          profile: _profile(),
          dataLoader: () async => const StoredLearningData(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Child Profile'), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Age: 6 yrs old'), findsOneWidget);
  });

  testWidgets('shows empty states when no learning data exists',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChildProfilePage(
          profile: _profile(),
          dataLoader: () async => const StoredLearningData(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Phoneme errors'), findsOneWidget);
    expect(find.textContaining('No errors recorded yet'), findsOneWidget);
    expect(find.textContaining('No practice module yet'), findsOneWidget);
  });

  testWidgets('shows actual phoneme errors and the generated module',
      (tester) async {
    final module = LearningModuleModel.fromMap(const {
      'module_id': 'mod-test',
      'focus_sounds': ['s'],
      'focus_processes': ['Stopping'],
      'outline_id': 'stopping-s',
      'outline_title': 'Stopping: /s/ practice',
      'levels': [
        {
          'level': 'word',
          'items': [
            {'text': 'sea', 'target_sound': '', 'position': ''},
          ],
        },
      ],
      'rationale': 'Age 5: eliminating stopping of initial /s/.',
      'generated_by': 'llm',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ChildProfilePage(
          profile: _profile(),
          dataLoader: () async => StoredLearningData(
            age: 5,
            processes: const [
              {
                'process': 'Stopping',
                'position': 'Initial',
                'detail': '/s/ -> [t]',
              },
            ],
            module: module,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stopping - Initial'), findsOneWidget);
    expect(find.text('/s/ -> [t]'), findsOneWidget);
    expect(find.text('Stopping: /s/ practice'), findsOneWidget);
    expect(find.text('sea'), findsOneWidget);
  });
}
