import '../models/workout_metrics.dart';
import '../models/workout_session_record.dart';

class WorkoutMetricsCalculator {
  const WorkoutMetricsCalculator();

  WorkoutMetrics calculate(
    List<WorkoutSessionRecord> sessions, {
    DateTime? now,
  }) {
    final today = _dateOnly(
      (now ?? DateTime.now()).toLocal(),
    );

    final sessionDates = <DateTime>{};

    final muscleAccumulators =
        <String, _MuscleAccumulator>{};

    final exerciseAccumulators =
        <String, _ExerciseAccumulator>{};

    var totalExercises = 0;
    var totalSets = 0;
    var totalReps = 0;
    var totalDurationSeconds = 0;
    var totalVolume = 0.0;

    DateTime? lastSessionAt;

    for (final session in sessions) {
      final localStartedAt =
          session.startedAt.toLocal();

      final sessionDate = _dateOnly(
        localStartedAt,
      );

      sessionDates.add(sessionDate);

      if (lastSessionAt == null ||
          localStartedAt.isAfter(lastSessionAt)) {
        lastSessionAt = localStartedAt;
      }

      totalExercises += session.totalExercises;
      totalSets += session.totalSets;
      totalReps += session.totalReps;
      totalDurationSeconds +=
          session.durationSeconds;
      totalVolume += session.totalVolume;

      for (final exercise in session.exercises) {
        final setCount = exercise.sets.length;
        final reps = exercise.totalReps;
        final volume = exercise.totalVolume;

        final muscleAccumulator =
            muscleAccumulators.putIfAbsent(
          exercise.muscleGroup,
          () => _MuscleAccumulator(
            muscleGroup: exercise.muscleGroup,
          ),
        );

        muscleAccumulator.exerciseEntries++;
        muscleAccumulator.sets += setCount;
        muscleAccumulator.reps += reps;
        muscleAccumulator.volume += volume;

        final exerciseAccumulator =
            exerciseAccumulators.putIfAbsent(
          exercise.exerciseId,
          () => _ExerciseAccumulator(
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exerciseName,
            muscleGroup: exercise.muscleGroup,
          ),
        );

        exerciseAccumulator.timesPerformed++;
        exerciseAccumulator.sets += setCount;
        exerciseAccumulator.reps += reps;
        exerciseAccumulator.volume += volume;
      }
    }

    final last7DaysStart = today.subtract(
      const Duration(days: 6),
    );

    final previous7DaysStart = today.subtract(
      const Duration(days: 13),
    );

    final previous7DaysEnd = today.subtract(
      const Duration(days: 7),
    );

    final last30DaysStart = today.subtract(
      const Duration(days: 29),
    );

    var sessionsLast7Days = 0;
    var setsLast7Days = 0;
    var setsPrevious7Days = 0;
    var volumeLast7Days = 0.0;

    for (final session in sessions) {
      final sessionDate = _dateOnly(
        session.startedAt.toLocal(),
      );

      if (_isBetweenInclusive(
        sessionDate,
        last7DaysStart,
        today,
      )) {
        sessionsLast7Days++;
        setsLast7Days += session.totalSets;
        volumeLast7Days += session.totalVolume;
      }

      if (_isBetweenInclusive(
        sessionDate,
        previous7DaysStart,
        previous7DaysEnd,
      )) {
        setsPrevious7Days += session.totalSets;
      }
    }

    final dailyActivity =
        List<DailyWorkoutMetric>.generate(
      7,
      (index) {
        final date = last7DaysStart.add(
          Duration(days: index),
        );

        var daySessions = 0;
        var daySets = 0;
        var dayDuration = 0;
        var dayVolume = 0.0;

        for (final session in sessions) {
          final sessionDate = _dateOnly(
            session.startedAt.toLocal(),
          );

          if (sessionDate != date) {
            continue;
          }

          daySessions++;
          daySets += session.totalSets;
          dayDuration += session.durationSeconds;
          dayVolume += session.totalVolume;
        }

        return DailyWorkoutMetric(
          date: date,
          sessions: daySessions,
          sets: daySets,
          durationSeconds: dayDuration,
          volume: dayVolume,
        );
      },
      growable: false,
    );

    final muscleMetrics = muscleAccumulators.values
        .map(
          (accumulator) => MuscleWorkoutMetric(
            muscleGroup:
                accumulator.muscleGroup,
            exerciseEntries:
                accumulator.exerciseEntries,
            sets: accumulator.sets,
            reps: accumulator.reps,
            volume: accumulator.volume,
          ),
        )
        .toList();

    muscleMetrics.sort((first, second) {
      final bySets = second.sets.compareTo(
        first.sets,
      );

      if (bySets != 0) {
        return bySets;
      }

      return second.volume.compareTo(
        first.volume,
      );
    });

    final topExercises = exerciseAccumulators.values
        .map(
          (accumulator) => ExerciseWorkoutMetric(
            exerciseId:
                accumulator.exerciseId,
            exerciseName:
                accumulator.exerciseName,
            muscleGroup:
                accumulator.muscleGroup,
            timesPerformed:
                accumulator.timesPerformed,
            sets: accumulator.sets,
            reps: accumulator.reps,
            volume: accumulator.volume,
          ),
        )
        .toList();

    topExercises.sort((first, second) {
      final bySets = second.sets.compareTo(
        first.sets,
      );

      if (bySets != 0) {
        return bySets;
      }

      return second.volume.compareTo(
        first.volume,
      );
    });

    final daysTrainedLast30 = sessionDates
        .where(
          (date) => _isBetweenInclusive(
            date,
            last30DaysStart,
            today,
          ),
        )
        .length;

    final totalSessions = sessions.length;

    return WorkoutMetrics(
      totalSessions: totalSessions,
      totalExercises: totalExercises,
      totalSets: totalSets,
      totalReps: totalReps,
      totalDurationSeconds:
          totalDurationSeconds,
      totalVolume: totalVolume,
      averageDurationSeconds: totalSessions == 0
          ? 0
          : totalDurationSeconds ~/ totalSessions,
      totalTrainingDays: sessionDates.length,
      daysTrainedLast30: daysTrainedLast30,
      currentStreak: _calculateCurrentStreak(
        sessionDates,
        today,
      ),
      bestStreak: _calculateBestStreak(
        sessionDates,
      ),
      sessionsLast7Days: sessionsLast7Days,
      setsLast7Days: setsLast7Days,
      setsPrevious7Days: setsPrevious7Days,
      volumeLast7Days: volumeLast7Days,
      lastSessionAt: lastSessionAt,
      dailyActivity: List.unmodifiable(
        dailyActivity,
      ),
      muscleMetrics: List.unmodifiable(
        muscleMetrics,
      ),
      topExercises: List.unmodifiable(
        topExercises.take(5),
      ),
    );
  }

  int _calculateCurrentStreak(
    Set<DateTime> trainingDates,
    DateTime today,
  ) {
    if (trainingDates.isEmpty) {
      return 0;
    }

    DateTime cursor;

    if (trainingDates.contains(today)) {
      cursor = today;
    } else {
      final yesterday = today.subtract(
        const Duration(days: 1),
      );

      if (!trainingDates.contains(yesterday)) {
        return 0;
      }

      cursor = yesterday;
    }

    var streak = 0;

    while (trainingDates.contains(cursor)) {
      streak++;

      cursor = cursor.subtract(
        const Duration(days: 1),
      );
    }

    return streak;
  }

  int _calculateBestStreak(
    Set<DateTime> trainingDates,
  ) {
    if (trainingDates.isEmpty) {
      return 0;
    }

    final sortedDates = trainingDates.toList()
      ..sort();

    var bestStreak = 1;
    var currentStreak = 1;

    for (
      var index = 1;
      index < sortedDates.length;
      index++
    ) {
      final previous = sortedDates[index - 1];
      final current = sortedDates[index];

      final dayDifference =
          current.difference(previous).inDays;

      if (dayDifference == 1) {
        currentStreak++;

        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    return bestStreak;
  }

  bool _isBetweenInclusive(
    DateTime value,
    DateTime start,
    DateTime end,
  ) {
    return !value.isBefore(start) &&
        !value.isAfter(end);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
    );
  }
}

class _MuscleAccumulator {
  final String muscleGroup;

  int exerciseEntries = 0;
  int sets = 0;
  int reps = 0;
  double volume = 0;

  _MuscleAccumulator({
    required this.muscleGroup,
  });
}

class _ExerciseAccumulator {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;

  int timesPerformed = 0;
  int sets = 0;
  int reps = 0;
  double volume = 0;

  _ExerciseAccumulator({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
  });
}