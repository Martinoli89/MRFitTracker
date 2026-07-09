import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const Text(
            'FitTracer',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Registra tus entrenamientos de forma rápida y visual.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entrenamiento de hoy',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aún no has registrado una rutina para hoy.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Iniciar entrenamiento'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Resumen semanal',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          const Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Días',
                  value: '0',
                  icon: Icons.calendar_today,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'Series',
                  value: '0',
                  icon: Icons.repeat,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Volumen',
                  value: '0 kg',
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'Racha',
                  value: '0',
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}