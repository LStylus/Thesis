part of 'home_page.dart';

class _QuestProgress {
  final String title;
  final int levelsDone;
  final int totalLevels;

  const _QuestProgress({
    required this.title,
    required this.levelsDone,
    required this.totalLevels,
  });
}

class _ProgressBadge extends StatelessWidget {
  final _QuestProgress quest;
  final int activityNumber;
  final int activityCount;
  final VoidCallback onTap;

  const _ProgressBadge({
    required this.quest,
    required this.activityNumber,
    required this.activityCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentActivity = activityNumber.clamp(1, activityCount);

    return Semantics(
      label:
          '${quest.title} progress $currentActivity of $activityCount activities',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 63,
          height: 73,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Progress',
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: AppFonts.fredokaOne,
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Container(
                  width: 43,
                  height: 43,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$currentActivity/$activityCount\nActivity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: AppFonts.fredokaOne,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
                      height: 0.95,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
