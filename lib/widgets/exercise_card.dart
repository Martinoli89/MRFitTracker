import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/exercise.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onAdd;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.wineDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.wine),
            ),
            child: Icon(
              _iconForMuscleGroup(exercise.muscleGroup),
              color: AppColors.textPrimary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.muscleGroup} · ${exercise.equipment}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          IconButton.filledTonal(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

IconData _iconForMuscleGroup(String muscleGroup) {
  switch (muscleGroup.toLowerCase()) {
    case 'pecho':
      return Icons.fitness_center;
    case 'piernas':
      return Icons.directions_run;
    case 'espalda':
      return Icons.sports_gymnastics;
    case 'brazos':
      return Icons.fitness_center;
    case 'hombros':
      return Icons.accessibility_new;
    case 'abdomen':
      return Icons.self_improvement;
    case 'cardio':
      return Icons.directions_run;
    default:
      return Icons.fitness_center;
  }
}