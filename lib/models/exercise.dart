class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final String? imagePath;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    this.imagePath,
  });
}