import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/workout_database.dart';
import '../models/companion_progress.dart';
import '../models/workout_metrics.dart';
import '../services/companion_progress_calculator.dart';
import '../services/workout_metrics_calculator.dart';
import '../widgets/companion_avatar.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onStartWorkout;

  const DashboardScreen({
    super.key,
    required this.onStartWorkout,
  });

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  static const _metricsCalculator =
      WorkoutMetricsCalculator();

  static const _companionCalculator =
      CompanionProgressCalculator();

  WorkoutDatabase get _database =>
      WorkoutDatabase.instance;

  late Future<WorkoutMetrics> _metricsFuture;

  @override
  void initState() {
    super.initState();

    _metricsFuture = _loadMetrics();

    _database.revision.addListener(
      _handleDatabaseRevision,
    );
  }

  @override
  void dispose() {
    _database.revision.removeListener(
      _handleDatabaseRevision,
    );

    super.dispose();
  }

  Future<WorkoutMetrics> _loadMetrics() async {
    final sessions =
        await _database.getSessions();

    return _metricsCalculator.calculate(
      sessions,
    );
  }

  void _handleDatabaseRevision() {
    if (!mounted) {
      return;
    }

    setState(() {
      _metricsFuture = _loadMetrics();
    });
  }

  Future<void> _openCompanionDetails(
    CompanionProgress progress,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CompanionDetailSheet(
          progress: progress,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorkoutMetrics>(
      future: _metricsFuture,
      builder: (context, snapshot) {
        final metrics = snapshot.data;

        final companion =
            _companionCalculator.calculate(
          metrics,
        );

        return ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            24,
            20,
            34,
          ),
          children: [
            _DashboardHeader(
              level: companion.level,
            ),
            const SizedBox(height: 30),
            Text(
              _buildGreeting(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '¿Entrenamos\nun rato?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 36,
                height: 1.04,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.1,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No hace falta hacerlo perfecto. Solo empezar y avanzar a tu ritmo.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            _StartWorkoutCard(
              onStartWorkout:
                  widget.onStartWorkout,
            ),
            const SizedBox(height: 30),
            const _SectionHeader(
              title: 'Así vas',
              subtitle:
                  'Una mirada rápida a todo lo que has ido sumando.',
            ),
            const SizedBox(height: 14),
            _QuickMetrics(
              streak:
                  metrics?.currentStreak ?? 0,
              totalSets:
                  metrics?.totalSets ?? 0,
              durationSeconds:
                  metrics?.totalDurationSeconds ??
                      0,
            ),
            const SizedBox(height: 30),
            const _SectionHeader(
              title: 'Tu compañero',
              subtitle:
                  'Crece con tus sesiones, no con la perfección.',
            ),
            const SizedBox(height: 14),
            _CompanionCard(
              progress: companion,
              onTap: () {
                _openCompanionDetails(
                  companion,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final int level;

  const _DashboardHeader({
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'MR FITTRACKER',
            style: TextStyle(
              color: AppColors.wineStrong,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.wineStrong,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                'Nivel $level',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StartWorkoutCard extends StatelessWidget {
  final VoidCallback onStartWorkout;

  const _StartWorkoutCard({
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.wine.withValues(
            alpha: 0.65,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceAlt,
            AppColors.wineDark.withValues(
              alpha: 0.82,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.22,
            ),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.background
                  .withValues(alpha: 0.32),
              borderRadius:
                  BorderRadius.circular(999),
            ),
            child: const Text(
              'TU PRÓXIMA SESIÓN',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tu entrenamiento,\nsin vueltas.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 27,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Elige un ejercicio, registra tus series y sigue cuando estés listo.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onStartWorkout,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(19),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                        const BoxDecoration(
                      color: Color(0x2A000000),
                      borderRadius:
                          BorderRadius.all(
                        Radius.circular(13),
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color:
                          AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Empezar entrenamiento',
                      style: TextStyle(
                        color:
                            AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color:
                        AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMetrics extends StatelessWidget {
  final int streak;
  final int totalSets;
  final int durationSeconds;

  const _QuickMetrics({
    required this.streak,
    required this.totalSets,
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickMetricItem(
              icon: Icons
                  .local_fire_department_outlined,
              value: '$streak',
              label: streak == 1
                  ? 'día seguido'
                  : 'días seguidos',
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _QuickMetricItem(
              icon: Icons.layers_rounded,
              value: '$totalSets',
              label: totalSets == 1
                  ? 'serie hecha'
                  : 'series hechas',
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _QuickMetricItem(
              icon: Icons.timer_outlined,
              value: _formatCompactDuration(
                durationSeconds,
              ),
              label: 'entrenando',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _QuickMetricItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.wineStrong,
          size: 20,
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 55,
      margin: const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      color: AppColors.border,
    );
  }
}

class _CompanionCard extends StatelessWidget {
  final CompanionProgress progress;
  final VoidCallback onTap;

  const _CompanionCard({
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius:
          BorderRadius.circular(27),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(27),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(27),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.wineDark
                      .withValues(alpha: 0.42),
                  borderRadius:
                      BorderRadius.circular(27),
                  border: Border.all(
                    color: AppColors.wine
                        .withValues(alpha: 0.55),
                  ),
                ),
                child: Center(
                  child: CompanionAvatar(
                    size: 78,
                    stage: progress.stage,
                    mood: progress.mood,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            progress.stageName,
                            style:
                                const TextStyle(
                              color: AppColors
                                  .textPrimary,
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons
                              .arrow_forward_ios_rounded,
                          color: AppColors
                              .textSecondary,
                          size: 13,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.message,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: AppColors
                            .textSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Nivel ${progress.level}',
                          style:
                              const TextStyle(
                            color: AppColors
                                .wineStrong,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${progress.xpInCurrentLevel}/'
                          '${progress.xpForNextLevel} XP',
                          style:
                              const TextStyle(
                            color: AppColors
                                .textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        999,
                      ),
                      child:
                          LinearProgressIndicator(
                        value: progress
                            .levelProgress,
                        minHeight: 7,
                        backgroundColor:
                            AppColors.surfaceAlt,
                        valueColor:
                            const AlwaysStoppedAnimation(
                          AppColors.wineStrong,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanionDetailSheet
    extends StatelessWidget {
  final CompanionProgress progress;

  const _CompanionDetailSheet({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            22,
            12,
            22,
            30,
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius:
                      BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 22),
              CompanionAvatar(
                size: 165,
                stage: progress.stage,
                mood: progress.mood,
              ),
              const SizedBox(height: 12),
              Text(
                progress.stageName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Nivel ${progress.level} · '
                '${progress.moodName}',
                style: const TextStyle(
                  color: AppColors.wineStrong,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                progress.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Nivel ${progress.level}',
                          style:
                              const TextStyle(
                            color: AppColors
                                .textPrimary,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${progress.remainingXp} XP para subir',
                          style:
                              const TextStyle(
                            color: AppColors
                                .textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        999,
                      ),
                      child:
                          LinearProgressIndicator(
                        value: progress
                            .levelProgress,
                        minHeight: 9,
                        backgroundColor:
                            AppColors.surfaceAlt,
                        valueColor:
                            const AlwaysStoppedAnimation(
                          AppColors.wineStrong,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Text(
                        '${progress.xpInCurrentLevel} de '
                        '${progress.xpForNextLevel} XP',
                        style:
                            const TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 17,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _CompanionStat(
                        value:
                            '${progress.totalSessions}',
                        label: 'sesiones',
                      ),
                    ),
                    const _DetailDivider(),
                    Expanded(
                      child: _CompanionStat(
                        value:
                            '${progress.totalSets}',
                        label: 'series',
                      ),
                    ),
                    const _DetailDivider(),
                    Expanded(
                      child: _CompanionStat(
                        value:
                            '${progress.totalMinutes}',
                        label: 'minutos',
                      ),
                    ),
                    const _DetailDivider(),
                    Expanded(
                      child: _CompanionStat(
                        value:
                            '${progress.currentStreak}',
                        label: 'racha',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.wineDark
                      .withValues(alpha: 0.48),
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.wine
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color:
                          AppColors.wineStrong,
                      size: 20,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Tu compañero gana experiencia con las sesiones, las series, el tiempo entrenado y la constancia. No pierde niveles por descansar.',
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanionStat extends StatelessWidget {
  final String value;
  final String label;

  const _CompanionStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      color: AppColors.border,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

String _buildGreeting() {
  final hour = DateTime.now().hour;

  if (hour < 6) {
    return 'Todavía despierto, ¿eh?';
  }

  if (hour < 12) {
    return 'Buenos días';
  }

  if (hour < 20) {
    return 'Buenas tardes';
  }

  return 'Buenas noches';
}

String _formatCompactDuration(
  int totalSeconds,
) {
  final hours = totalSeconds ~/ 3600;

  final minutes =
      (totalSeconds % 3600) ~/ 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }

  if (minutes > 0) {
    return '${minutes}m';
  }

  return '${totalSeconds}s';
}