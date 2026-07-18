enum CompanionStage {
  newcomer,
  companion,
  explorer,
  veteran,
}

enum CompanionMood {
  curious,
  energized,
  happy,
  calm,
  sleepy,
}

class CompanionProgress {
  final int totalXp;

  final int level;
  final int xpInCurrentLevel;
  final int xpForNextLevel;

  final CompanionStage stage;
  final CompanionMood mood;

  final String message;

  final int totalSessions;
  final int totalSets;
  final int currentStreak;
  final int totalMinutes;

  const CompanionProgress({
    required this.totalXp,
    required this.level,
    required this.xpInCurrentLevel,
    required this.xpForNextLevel,
    required this.stage,
    required this.mood,
    required this.message,
    required this.totalSessions,
    required this.totalSets,
    required this.currentStreak,
    required this.totalMinutes,
  });

  double get levelProgress {
    if (xpForNextLevel <= 0) {
      return 0;
    }

    return (xpInCurrentLevel / xpForNextLevel)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  int get remainingXp {
    return (xpForNextLevel - xpInCurrentLevel)
        .clamp(0, xpForNextLevel)
        .toInt();
  }

  String get stageName {
    switch (stage) {
      case CompanionStage.newcomer:
        return 'Recién llegado';

      case CompanionStage.companion:
        return 'Compañero';

      case CompanionStage.explorer:
        return 'Explorador';

      case CompanionStage.veteran:
        return 'Veterano';
    }
  }

  String get moodName {
    switch (mood) {
      case CompanionMood.curious:
        return 'Curioso';

      case CompanionMood.energized:
        return 'Con energía';

      case CompanionMood.happy:
        return 'Contento';

      case CompanionMood.calm:
        return 'Tranquilo';

      case CompanionMood.sleepy:
        return 'Con sueño';
    }
  }
}