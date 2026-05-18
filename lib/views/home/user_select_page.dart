import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/profile_model.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/child_info_page.dart';

class UserSelectPage extends StatefulWidget {
  final ProfileModel activeProfile;
  final List<ProfileModel> profiles;

  const UserSelectPage({
    super.key,
    required this.activeProfile,
    required this.profiles,
  });

  @override
  State<UserSelectPage> createState() => _UserSelectPageState();
}

class _UserSelectPageState extends State<UserSelectPage> {
  late String _selectedProfileId;
  late List<ProfileModel> _profiles;
  ProfileModel? _activeProfileAfterEdit;
  bool _isBusy = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _lockLandscape();
    _selectedProfileId = widget.activeProfile.profileId;
    _profiles = _mergeProfiles(widget.profiles, widget.activeProfile);
  }

  Future<void> _lockLandscape() {
    return SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  List<ProfileModel> _mergeProfiles(
    List<ProfileModel> profiles,
    ProfileModel activeProfile,
  ) {
    final uniqueProfiles = <String, ProfileModel>{};
    for (final profile in profiles) {
      uniqueProfiles[profile.profileId] = profile;
    }
    uniqueProfiles.putIfAbsent(activeProfile.profileId, () => activeProfile);
    return uniqueProfiles.values.toList();
  }

  Future<void> _addChild() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final authController = context.read<AuthController>();
    final ok = await authController.startAddChildForCurrentParent();

    if (!mounted) return;

    setState(() {
      _isBusy = false;
    });

    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            authController.errorMessage ??
                'Could not prepare the child profile form.',
          ),
        ),
      );
      return;
    }

    await navigator.push(
      MaterialPageRoute(builder: (_) => const ChildInfoPage()),
    );

    if (!mounted) return;
    await _lockLandscape();
  }

  Future<void> _selectProfile(ProfileModel profile) async {
    if (_isBusy || _isEditing) return;
    setState(() {
      _isBusy = true;
      _selectedProfileId = profile.profileId;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<HomeController>().switchActiveProfile(profile);
      if (!mounted) return;
      Navigator.of(context).pop(profile);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not switch child profile.')),
      );
      setState(() {
        _isBusy = false;
        _selectedProfileId = widget.activeProfile.profileId;
      });
    }
  }

  Future<void> _deleteProfile(ProfileModel profile) async {
    if (_isBusy) return;

    final remainingProfiles = _profiles
        .where((childProfile) => childProfile.profileId != profile.profileId)
        .toList();
    final messenger = ScaffoldMessenger.of(context);

    if (remainingProfiles.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Add another child before deleting this profile.'),
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete child profile?'),
          content: Text(
            'This will remove ${profile.childName} from this guardian account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      _isBusy = true;
    });

    try {
      final replacement = await context
          .read<HomeController>()
          .deleteChildProfile(profile);
      if (!mounted) return;

      setState(() {
        _profiles = remainingProfiles;
        if (replacement != null) {
          _selectedProfileId = replacement.profileId;
          _activeProfileAfterEdit = replacement;
        } else if (_selectedProfileId == profile.profileId) {
          _selectedProfileId = remainingProfiles.first.profileId;
          _activeProfileAfterEdit = remainingProfiles.first;
        }
        _isBusy = false;
      });

      messenger.showSnackBar(
        SnackBar(content: Text('${profile.childName} was removed.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete child profile.')),
      );
    }
  }

  Future<void> _signOut() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
    });

    final authController = context.read<AuthController>();
    Navigator.of(context).pop();
    await authController.signOut();
  }

  void _close() {
    Navigator.of(context).pop(_activeProfileAfterEdit);
  }

  @override
  Widget build(BuildContext context) {
    final orderedProfiles = _profiles.toList()
      ..sort((left, right) {
        final leftRank = left.profileId == _selectedProfileId ? 0 : 1;
        final rightRank = right.profileId == _selectedProfileId ? 0 : 1;
        if (leftRank != rightRank) return leftRank.compareTo(rightRank);
        return left.childName.toLowerCase().compareTo(
          right.childName.toLowerCase(),
        );
      });

    return Scaffold(
      backgroundColor: const Color(0xFFD1D1D1),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;
            final edge = compact ? 8.0 : 14.0;

            return Padding(
              padding: EdgeInsets.all(edge),
              child: ColoredBox(
                color: Colors.white,
                child: Stack(
                  children: [
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _SelectorIconButton(
                        icon: Icons.close_rounded,
                        label: 'Close',
                        onTap: _isBusy ? null : _close,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _SelectorIconButton(
                        icon: _isEditing
                            ? Icons.check_rounded
                            : Icons.edit_rounded,
                        label: _isEditing ? 'Done editing' : 'Edit children',
                        onTap: _isBusy
                            ? null
                            : () {
                                setState(() {
                                  _isEditing = !_isEditing;
                                });
                              },
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 18 : 28,
                          compact ? 58 : 62,
                          compact ? 18 : 28,
                          20,
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Who's Playing?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontFamily: AppFonts.fredokaOne,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                height: 1,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: compact ? 30 : 42),
                            Flexible(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      for (final profile in orderedProfiles) ...[
                                        _ProfileChoiceTile(
                                          profile: profile,
                                          isActive:
                                              profile.profileId ==
                                              _selectedProfileId,
                                          isEnabled: !_isBusy,
                                          isEditing: _isEditing,
                                          onTap: () => _selectProfile(profile),
                                          onDelete: () =>
                                              _deleteProfile(profile),
                                        ),
                                        const SizedBox(width: 24),
                                      ],
                                      _AddChildTile(
                                        isEnabled: !_isBusy,
                                        onTap: _addChild,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _LogoutButton(
                              isEnabled: !_isBusy,
                              onTap: _signOut,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SelectorIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SelectorIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFD8D8D8),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onTap;

  const _LogoutButton({
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1 : 0.55,
      child: TextButton(
        onPressed: isEnabled ? onTap : null,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFD73A3A),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFD73A3A),
            fontFamily: AppFonts.fredoka,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _AddChildTile extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onTap;

  const _AddChildTile({
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1 : 0.55,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isEnabled ? onTap : null,
        child: SizedBox(
          width: 78,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF8E8E8E),
                  size: 25,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add Child',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8A8A8A),
                  fontFamily: AppFonts.fredoka,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileChoiceTile extends StatelessWidget {
  final ProfileModel profile;
  final bool isActive;
  final bool isEnabled;
  final bool isEditing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProfileChoiceTile({
    required this.profile,
    required this.isActive,
    required this.isEnabled,
    required this.isEditing,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1 : 0.72,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isEnabled && !isEditing ? onTap : null,
        child: SizedBox(
          width: 78,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    assetPath: profile.profileAssetPath,
                    fallbackSeed: profile.profileId,
                    size: 78,
                    borderWidth: isActive ? 2 : 0,
                    borderRadius: 9,
                    borderColor: AppColors.primary,
                  ),
                  if (isActive)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  if (isEditing)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: isEnabled ? onDelete : null,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5A5A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                profile.childName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontFamily: AppFonts.fredoka,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
