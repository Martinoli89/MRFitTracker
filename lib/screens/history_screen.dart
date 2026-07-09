import 'package:flutter/material.dart';

import '../widgets/empty_state_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateScreen(
      title: 'Historial',
      message: 'Aquí aparecerán tus entrenamientos guardados por fecha.',
      icon: Icons.calendar_month,
    );
  }
}