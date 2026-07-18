class SetEntry {
  final int? id;
  final double weightKg;
  final int reps;

  const SetEntry({
    this.id,
    required this.weightKg,
    required this.reps,
  });

  double get volume => weightKg * reps;

  SetEntry copyWith({
    int? id,
    double? weightKg,
    int? reps,
  }) {
    return SetEntry(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
    );
  }
}