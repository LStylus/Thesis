import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/home_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _formatBirthDate(DateTime birthDate) {
    return DateFormat('MMMM dd, yyyy').format(birthDate);
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$label: $value', style: const TextStyle(fontSize: 13.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeController = context.read<HomeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Voyage'),
        actions: [
          IconButton(
            onPressed: () async {
              await homeController.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<ProfileModel?>(
        stream: homeController.currentUserProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;

          if (profile == null) {
            return const Center(child: Text('No user profile found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${profile.parentName}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This data is loaded from the currently logged-in Firebase account.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    _infoTile('Parent Name', profile.parentName),
                    _infoTile('Relationship', profile.relationshipToChild),
                    _infoTile('Child Name', profile.childName),
                    _infoTile(
                      'Child Birth Date',
                      _formatBirthDate(profile.birthDate),
                    ),
                    _infoTile('Age', profile.age.toString()),

                    const SizedBox(height: 14),
                    const Text(
                      'Profile Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _infoTile('Profile ID', profile.profileId),
                    _infoTile('User ID', profile.userId),
                    _infoTile(
                      'Progress ID',
                      profile.progressId.isEmpty ? '-' : profile.progressId,
                    ),
                    _infoTile(
                      'Category ID',
                      profile.categoryId.isEmpty ? '-' : profile.categoryId,
                    ),
                    _infoTile(
                      'Course No',
                      profile.courseNo.isEmpty ? '-' : profile.courseNo,
                    ),

                    const SizedBox(height: 10),
                    const Text(
                      'Progress fields can be connected later once your progress module is ready.',
                      style: TextStyle(color: AppColors.textGray, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
