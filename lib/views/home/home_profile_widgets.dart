part of 'home_page.dart';

class _ProfileChip extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onTap;

  const _ProfileChip({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
            child: Row(
              children: [
                ProfileAvatar(
                  assetPath: profile.profileAssetPath,
                  fallbackSeed: profile.profileId,
                  size: 40,
                  borderWidth: 1.5,
                  borderRadius: 20,
                  borderColor: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.childName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4B4B4B),
                          fontFamily: AppFonts.fredoka,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFC400),
                            size: 13,
                          ),
                          SizedBox(width: 1),
                          Text(
                            '500',
                            style: TextStyle(
                              color: Color(0xFFFFC400),
                              fontFamily: AppFonts.fredokaOne,
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              height: 1,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyProfileMessage extends StatelessWidget {
  const _EmptyProfileMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'No user profile found.',
        style: TextStyle(
          color: AppColors.textGray,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
