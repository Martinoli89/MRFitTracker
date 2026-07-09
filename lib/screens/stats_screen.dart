import 'package:flutter/material.dart';

import '../widgets/empty_state_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateScreen(
      title: 'Métricas',
      message: 'Aquí veremos gráficos de progreso, volumen y grupos musculares.',
      icon: Icons.bar_chart,
    );
  }
}