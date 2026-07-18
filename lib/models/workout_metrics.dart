class DailyWorkoutMetric {
  final DateTime date;
  final int sessions;
  final int sets;
  final int durationSeconds;
  final double volume;

  const DailyWorkoutMetric({
    required this.date,
    required this.sessions,
    required this.sets,
    required this.durationSeconds,
    required this.volume,
  });

  bool get hasActivity => sessions > 0;
}

class MuscleWorkoutMetric {
  final String muscleGroup;
  final int exerciseEntries;
  final int sets;
  final int reps;
  final double volume;

  const MuscleWorkoutMetric({
    required this.muscleGroup,
    required this.exerciseEntries,
    required this.sets,
    required this.reps,
    required this.volume,
  });
}

class ExerciseWorkoutMetric {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;

  final int timesPerformed;
  final int sets;
  final int reps;
  final double volume;

  const ExerciseWorkoutMetric({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.timesPerformed,
    required this.sets,
    required this.reps,
    required this.volume,
  });
}

class WorkoutMetrics {
  final int totalSessions;
  final int totalExercises;
  final int totalSets;
  final int totalReps;
  final int totalDurationSeconds;
  final double totalVolume;

  final int averageDurationSeconds;
  final int totalTrainingDays;
  final int daysTrainedLast30;

  final int currentStreak;
  final int bestStreak;

  final int sessionsLast7Days;
  final int setsLast7Days;
  final int setsPrevious7Days;
  final double volumeLast7Days;

  final DateTime? lastSessionAt;

  final List<DailyWorkoutMetric> dailyActivity;
  final List<MuscleWorkoutMetric> muscleMetrics;
  final List<ExerciseWorkoutMetric> topExercises;

  const WorkoutMetrics({
    required this.totalSessions,
    required this.totalExercises,
    required this.totalSets,
    required this.totalReps,
    required this.totalDurationSeconds,
    required this.totalVolume,
    required this.averageDurationSeconds,
    required this.totalTrainingDays,
    required this.daysTrainedLast30,
    required this.currentStreak,
    required this.bestStreak,
    required this.sessionsLast7Days,
    required this.setsLast7Days,
    required this.setsPrevious7Days,
    required this.volumeLast7Days,
    required this.lastSessionAt,
    required this.dailyActivity,
    required this.muscleMetrics,
    required this.topExercises,
  });

  bool get hasData => totalSessions > 0;
}