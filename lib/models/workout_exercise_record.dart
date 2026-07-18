import 'set_entry.dart';

class WorkoutExerciseRecord {
  final int? id;

  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final String equipment;
  final String note;

  final List<SetEntry> sets;

  const WorkoutExerciseRecord({
    this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.equipment,
    required this.note,
    required this.sets,
  });

  int get totalReps {
    return sets.fold(
      0,
      (total, set) => total + set.reps,
    );
  }

  double get totalVolume {
    return sets.fold(
      0,
      (total, set) => total + set.volume,
    );
  }

  WorkoutExerciseRecord copyWith({
    int? id,
    String? exerciseId,
    String? exerciseName,
    String? muscleGroup,
    String? equipment,
    String? note,
    List<SetEntry>? sets,
  }) {
    return WorkoutExerciseRecord(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      note: note ?? this.note,
      sets: sets ?? this.sets,
    );
  }
}