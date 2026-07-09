import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/exercise_seed_data.dart';
import '../widgets/exercise_card.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const Text(
            'Rutina del día',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecciona ejercicios para agregarlos a tu entrenamiento.',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          for (final exercise in exerciseSeedData) ...[
            ExerciseCard(exercise: exercise),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}