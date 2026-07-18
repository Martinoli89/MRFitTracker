import '../models/companion_progress.dart';
import '../models/workout_metrics.dart';

class CompanionProgressCalculator {
  const CompanionProgressCalculator();

  CompanionProgress calculate(
    WorkoutMetrics? metrics, {
    DateTime? now,
  }) {
    if (metrics == null || !metrics.hasData) {
      return const CompanionProgress(
        totalXp: 0,
        level: 1,
        xpInCurrentLevel: 0,
        xpForNextLevel: 100,
        stage: CompanionStage.newcomer,
        mood: CompanionMood.curious,
        message:
            'Está mirando todo con curiosidad. Tu primera sesión también será la suya.',
        totalSessions: 0,
        totalSets: 0,
        currentStreak: 0,
        totalMinutes: 0,
      );
    }

    final totalMinutes =
        metrics.totalDurationSeconds ~/ 60;

    final totalXp =
        (metrics.totalSessions * 35) +
        (metrics.totalSets * 5) +
        totalMinutes +
        (metrics.currentStreak * 12);

    var level = 1;
    var remainingXp = totalXp;
    var xpForNextLevel = _xpRequiredForLevel(
      level,
    );

    while (remainingXp >= xpForNextLevel) {
      remainingXp -= xpForNextLevel;
      level++;

      xpForNextLevel = _xpRequiredForLevel(
        level,
      );
    }

    final stage = _stageForLevel(level);

    final mood = _calculateMood(
      metrics.lastSessionAt,
      now ?? DateTime.now(),
    );

    return CompanionProgress(
      totalXp: totalXp,
      level: level,
      xpInCurrentLevel: remainingXp,
      xpForNextLevel: xpForNextLevel,
      stage: stage,
      mood: mood,
      message: _messageForMood(mood),
      totalSessions: metrics.totalSessions,
      totalSets: metrics.totalSets,
      currentStreak: metrics.currentStreak,
      totalMinutes: totalMinutes,
    );
  }

  int _xpRequiredForLevel(int level) {
    return 100 + ((level - 1) * 40);
  }

  CompanionStage _stageForLevel(int level) {
    if (level >= 10) {
      return CompanionStage.veteran;
    }

    if (level >= 6) {
      return CompanionStage.explorer;
    }

    if (level >= 3) {
      return CompanionStage.companion;
    }

    return CompanionStage.newcomer;
  }

  CompanionMood _calculateMood(
    DateTime? lastSessionAt,
    DateTime now,
  ) {
    if (lastSessionAt == null) {
      return CompanionMood.curious;
    }

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final lastSession = lastSessionAt.toLocal();

    final lastTrainingDay = DateTime(
      lastSession.year,
      lastSession.month,
      lastSession.day,
    );

    final difference = today
        .difference(lastTrainingDay)
        .inDays;

    if (difference <= 0) {
      return CompanionMood.energized;
    }

    if (difference == 1) {
      return CompanionMood.happy;
    }

    if (difference <= 3) {
      return CompanionMood.calm;
    }

    return CompanionMood.sleepy;
  }

  String _messageForMood(
    CompanionMood mood,
  ) {
    switch (mood) {
      case CompanionMood.curious:
        return 'Está descubriendo este lugar contigo. Parece listo para empezar.';

      case CompanionMood.energized:
        return 'Hoy quedó con energía de sobra. Parece que todavía quiere acompañarte.';

      case CompanionMood.happy:
        return 'Sigue contento por la última sesión. No tiene apuro, pero sí ganas.';

      case CompanionMood.calm:
        return 'Está tranquilo, guardando energía para cuando decidas volver.';

      case CompanionMood.sleepy:
        return 'Se quedó medio dormido esperando la próxima sesión.';
    }
  }
}