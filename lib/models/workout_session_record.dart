import 'workout_exercise_record.dart';

class WorkoutSessionRecord {
  final int? id;

  final DateTime startedAt;
  final DateTime finishedAt;

  final int durationSeconds;
  final List<WorkoutExerciseRecord> exercises;

  const WorkoutSessionRecord({
    this.id,
    required this.startedAt,
    required this.finishedAt,
    required this.durationSeconds,
    required this.exercises,
  });

  int get totalExercises => exercises.length;

  int get totalSets {
    return exercises.fold(
      0,
      (total, exercise) => total + exercise.sets.length,
    );
  }

  int get totalReps {
    return exercises.fold(
      0,
      (total, exercise) => total + exercise.totalReps,
    );
  }

  double get totalVolume {
    return exercises.fold(
      0,
      (total, exercise) => total + exercise.totalVolume,
    );
  }

  Set<String> get muscleGroups {
    return exercises
        .map((exercise) => exercise.muscleGroup)
        .toSet();
  }

  WorkoutSessionRecord copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? durationSeconds,
    List<WorkoutExerciseRecord>? exercises,
  }) {
    return WorkoutSessionRecord(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      durationSeconds:
          durationSeconds ?? this.durationSeconds,
      exercises: exercises ?? this.exercises,
    );
  }
}