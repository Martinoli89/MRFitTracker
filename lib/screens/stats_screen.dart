import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/workout_database.dart';
import '../models/workout_metrics.dart';
import '../services/workout_metrics_calculator.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const _calculator = WorkoutMetricsCalculator();

  WorkoutDatabase get _database => WorkoutDatabase.instance;

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
    final sessions = await _database.getSessions();

    return _calculator.calculate(sessions);
  }

  void _handleDatabaseRevision() {
    if (!mounted) {
      return;
    }

    setState(() {
      _metricsFuture = _loadMetrics();
    });
  }

  Future<void> _refresh() async {
    final future = _loadMetrics();

    setState(() {
      _metricsFuture = future;
    });

    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<WorkoutMetrics>(
        future: _metricsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const _MetricsLoading();
          }

          if (snapshot.hasError) {
            return _MetricsError(
              onRetry: _refresh,
            );
          }

          final metrics = snapshot.data;

          if (metrics == null || !metrics.hasData) {
            return const _EmptyMetrics();
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: _MetricsContent(
              metrics: metrics,
            ),
          );
        },
      ),
    );
  }
}

class _MetricsContent extends StatelessWidget {
  final WorkoutMetrics metrics;

  const _MetricsContent({
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        34,
      ),
      children: [
        const Text(
          'PROGRESO',
          style: TextStyle(
            color: AppColors.wineStrong,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Tus números,\nsin ruido.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          metrics.lastSessionAt == null
              ? 'Todavía no hay entrenamientos registrados.'
              : 'Última sesión: '
                  '${_formatRelativeDate(metrics.lastSessionAt!)}.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        _WeeklyOverviewCard(
          metrics: metrics,
        ),

        const SizedBox(height: 14),

        _MetricGrid(
          metrics: metrics,
        ),

        const SizedBox(height: 28),

        const _SectionTitle(
          title: 'Actividad reciente',
          subtitle: 'Últimos siete días',
        ),

        const SizedBox(height: 12),

        _WeeklyActivityCard(
          metrics: metrics.dailyActivity,
        ),

        const SizedBox(height: 28),

        const _SectionTitle(
          title: 'Constancia',
          subtitle: 'Frecuencia y duración de tus sesiones',
        ),

        const SizedBox(height: 12),

        _ConsistencyCard(
          metrics: metrics,
        ),

        if (metrics.muscleMetrics.isNotEmpty) ...[
          const SizedBox(height: 28),
          const _SectionTitle(
            title: 'Distribución',
            subtitle: 'Series acumuladas por grupo muscular',
          ),
          const SizedBox(height: 12),
          _MuscleDistributionCard(
            metrics: metrics.muscleMetrics,
          ),
        ],

        if (metrics.topExercises.isNotEmpty) ...[
          const SizedBox(height: 28),
          const _SectionTitle(
            title: 'Ejercicios frecuentes',
            subtitle: 'Ordenados por series registradas',
          ),
          const SizedBox(height: 12),
          _TopExercisesCard(
            exercises: metrics.topExercises,
          ),
        ],
      ],
    );
  }
}

class _WeeklyOverviewCard extends StatelessWidget {
  final WorkoutMetrics metrics;

  const _WeeklyOverviewCard({
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final comparison = _buildWeekComparison(
      metrics.setsLast7Days,
      metrics.setsPrevious7Days,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
              alpha: 0.78,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(
                    alpha: 0.36,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ÚLTIMOS 7 DÍAS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Actividad semanal',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _WeeklyValue(
                  value: '${metrics.sessionsLast7Days}',
                  label: 'sesiones',
                ),
              ),
              Expanded(
                child: _WeeklyValue(
                  value: '${metrics.setsLast7Days}',
                  label: 'series',
                ),
              ),
              Expanded(
                child: _WeeklyValue(
                  value: _formatCompactNumber(
                    metrics.volumeLast7Days,
                  ),
                  label: 'kg volumen',
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(
                alpha: 0.24,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  comparison.icon,
                  color: comparison.emphasized
                      ? AppColors.wineStrong
                      : AppColors.textSecondary,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comparison.label,
                    style: TextStyle(
                      color: comparison.emphasized
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyValue extends StatelessWidget {
  final String value;
  final String label;

  const _WeeklyValue({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final WorkoutMetrics metrics;

  const _MetricGrid({
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;

        final itemWidth =
            (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                icon: Icons.calendar_month_rounded,
                label: 'Sesiones',
                value: '${metrics.totalSessions}',
                detail:
                    '${metrics.totalTrainingDays} días activos',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                icon: Icons.timer_outlined,
                label: 'Tiempo total',
                value: _formatDuration(
                  metrics.totalDurationSeconds,
                ),
                detail:
                    'Promedio ${_formatDuration(metrics.averageDurationSeconds)}',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                icon: Icons.layers_rounded,
                label: 'Series',
                value: '${metrics.totalSets}',
                detail:
                    '${metrics.totalReps} repeticiones',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                icon: Icons.monitor_weight_outlined,
                label: 'Volumen',
                value:
                    '${_formatCompactNumber(metrics.totalVolume)} kg',
                detail:
                    '${metrics.totalExercises} ejercicios',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 134,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.wineDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.wineStrong,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // Antes había un Spacer aquí.
          // Dentro de un ListView provocaba altura infinita.
          const SizedBox(height: 18),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  final List<DailyWorkoutMetric> metrics;

  const _WeeklyActivityCard({
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    var maximumSets = 0;

    for (final metric in metrics) {
      if (metric.sets > maximumSets) {
        maximumSets = metric.sets;
      }
    }

    final safeMaximum =
        maximumSets == 0 ? 1 : maximumSets;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final metric in metrics)
                  Expanded(
                    child: _DayActivityBar(
                      metric: metric,
                      maximumSets: safeMaximum,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(
            color: AppColors.border,
            height: 1,
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(
                Icons.layers_rounded,
                color: AppColors.wineStrong,
                size: 15,
              ),
              SizedBox(width: 7),
              Text(
                'Altura de la barra: series registradas',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayActivityBar extends StatelessWidget {
  final DailyWorkoutMetric metric;
  final int maximumSets;

  const _DayActivityBar({
    required this.metric,
    required this.maximumSets,
  });

  @override
  Widget build(BuildContext context) {
    final rawRatio = maximumSets <= 0
        ? 0.0
        : metric.sets / maximumSets;

    final activityRatio = rawRatio.clamp(
      0.0,
      1.0,
    );

    final heightFactor = metric.sets == 0
        ? 0.05
        : activityRatio.clamp(
            0.16,
            1.0,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 18,
            child: metric.sets > 0
                ? Text(
                    '${metric.sets}',
                    style: const TextStyle(
                      color:
                          AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 450,
                  ),
                  curve: Curves.easeOutCubic,
                  width: 19,
                  decoration: BoxDecoration(
                    color: metric.hasActivity
                        ? AppColors.wineStrong
                        : AppColors.border,
                    borderRadius:
                        BorderRadius.circular(
                      999,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 15,
            child: Text(
              _shortWeekday(metric.date),
              style: TextStyle(
                color: metric.hasActivity
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: metric.hasActivity
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  final WorkoutMetrics metrics;

  const _ConsistencyCard({
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ConsistencyMetric(
              icon: Icons.local_fire_department_outlined,
              value: '${metrics.currentStreak}',
              label: 'Racha actual',
              suffix: 'días',
            ),
          ),
          const _CardDivider(),
          Expanded(
            child: _ConsistencyMetric(
              icon: Icons.emoji_events_outlined,
              value: '${metrics.bestStreak}',
              label: 'Mejor racha',
              suffix: 'días',
            ),
          ),
          const _CardDivider(),
          Expanded(
            child: _ConsistencyMetric(
              icon: Icons.calendar_today_outlined,
              value: '${metrics.daysTrainedLast30}',
              label: 'Últimos 30',
              suffix: 'días activos',
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsistencyMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String suffix;

  const _ConsistencyMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.suffix,
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
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          suffix,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 66,
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      color: AppColors.border,
    );
  }
}

class _MuscleDistributionCard extends StatelessWidget {
  final List<MuscleWorkoutMetric> metrics;

  const _MuscleDistributionCard({
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final totalSets = metrics.fold<int>(
      0,
      (total, metric) => total + metric.sets,
    );

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          for (
            var index = 0;
            index < metrics.length;
            index++
          ) ...[
            _MuscleDistributionRow(
              metric: metrics[index],
              totalSets: totalSets,
            ),
            if (index < metrics.length - 1)
              const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _MuscleDistributionRow
    extends StatelessWidget {
  final MuscleWorkoutMetric metric;
  final int totalSets;

  const _MuscleDistributionRow({
    required this.metric,
    required this.totalSets,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalSets == 0
        ? 0.0
        : metric.sets / totalSets;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: AppColors.wineDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForMuscleGroup(
                  metric.muscleGroup,
                ),
                color: AppColors.textPrimary,
                size: 17,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                metric.muscleGroup,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${metric.sets} series',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 34,
              child: Text(
                '${(percentage * 100).round()}%',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: AppColors.wineStrong,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 7,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation(
              AppColors.wineStrong,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopExercisesCard extends StatelessWidget {
  final List<ExerciseWorkoutMetric> exercises;

  const _TopExercisesCard({
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          for (
            var index = 0;
            index < exercises.length;
            index++
          ) ...[
            _TopExerciseRow(
              position: index + 1,
              exercise: exercises[index],
            ),
            if (index < exercises.length - 1)
              const Divider(
                color: AppColors.border,
                height: 22,
              ),
          ],
        ],
      ),
    );
  }
}

class _TopExerciseRow extends StatelessWidget {
  final int position;
  final ExerciseWorkoutMetric exercise;

  const _TopExerciseRow({
    required this.position,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: position == 1
                ? AppColors.wineDark
                : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: position == 1
                  ? AppColors.wine
                  : AppColors.border,
            ),
          ),
          child: Text(
            '$position',
            style: TextStyle(
              color: position == 1
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.exerciseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${exercise.muscleGroup} · '
                '${exercise.timesPerformed} veces',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${exercise.sets} series',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${_formatCompactNumber(exercise.volume)} kg',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _MetricsLoading extends StatelessWidget {
  const _MetricsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _MetricsError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _MetricsError({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.textSecondary,
              size: 54,
            ),
            const SizedBox(height: 15),
            const Text(
              'No pudimos calcular tus métricas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comprueba la consola por si SQLite informó algún error.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              child: const Text(
                'Intentar nuevamente',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMetrics extends StatelessWidget {
  const _EmptyMetrics();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        24,
        70,
        24,
        30,
      ),
      children: [
        Container(
          width: 94,
          height: 94,
          margin: const EdgeInsets.symmetric(
            horizontal: 100,
          ),
          decoration: BoxDecoration(
            color: AppColors.wineDark,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.wine,
            ),
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: AppColors.textPrimary,
            size: 42,
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Aquí aparecerán tus métricas',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Guarda tu primer entrenamiento para comenzar a registrar actividad, series y constancia.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _WeekComparison {
  final String label;
  final IconData icon;
  final bool emphasized;

  const _WeekComparison({
    required this.label,
    required this.icon,
    required this.emphasized,
  });
}

_WeekComparison _buildWeekComparison(
  int currentSets,
  int previousSets,
) {
  if (currentSets == 0 && previousSets == 0) {
    return const _WeekComparison(
      label:
          'Todavía no hay actividad semanal para comparar.',
      icon: Icons.horizontal_rule_rounded,
      emphasized: false,
    );
  }

  if (previousSets == 0) {
    return const _WeekComparison(
      label:
          'Esta semana será tu primera referencia.',
      icon: Icons.flag_outlined,
      emphasized: true,
    );
  }

  final difference = currentSets - previousSets;

  final percentage =
      ((difference / previousSets) * 100)
          .abs()
          .round();

  if (difference > 0) {
    return _WeekComparison(
      label:
          '$percentage% más series que en los siete días anteriores.',
      icon: Icons.trending_up_rounded,
      emphasized: true,
    );
  }

  if (difference < 0) {
    return _WeekComparison(
      label:
          '$percentage% menos series que en los siete días anteriores.',
      icon: Icons.trending_down_rounded,
      emphasized: false,
    );
  }

  return const _WeekComparison(
    label:
        'Misma cantidad de series que en el periodo anterior.',
    icon: Icons.trending_flat_rounded,
    emphasized: false,
  );
}

IconData _iconForMuscleGroup(
  String muscleGroup,
) {
  switch (muscleGroup.toLowerCase()) {
    case 'pecho':
      return Icons.fitness_center_rounded;

    case 'espalda':
      return Icons.sports_gymnastics_rounded;

    case 'piernas':
      return Icons.directions_run_rounded;

    case 'hombros':
      return Icons.accessibility_new_rounded;

    case 'brazos':
      return Icons.fitness_center_rounded;

    case 'abdomen':
      return Icons.self_improvement_rounded;

    case 'cardio':
      return Icons.monitor_heart_outlined;

    default:
      return Icons.fitness_center_rounded;
  }
}

String _shortWeekday(DateTime value) {
  const weekdays = [
    'L',
    'M',
    'M',
    'J',
    'V',
    'S',
    'D',
  ];

  return weekdays[value.weekday - 1];
}

String _formatDuration(int totalSeconds) {
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

String _formatCompactNumber(double value) {
  if (value >= 1000000) {
    return '${_decimalComma(value / 1000000)}M';
  }

  if (value >= 1000) {
    return '${_decimalComma(value / 1000)}k';
  }

  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(1)
      .replaceAll('.', ',');
}

String _decimalComma(double value) {
  final decimals = value >= 100 ? 0 : 1;

  return value
      .toStringAsFixed(decimals)
      .replaceAll('.', ',');
}

String _formatRelativeDate(DateTime value) {
  final localDate = value.toLocal();
  final now = DateTime.now();

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final date = DateTime(
    localDate.year,
    localDate.month,
    localDate.day,
  );

  final difference =
      today.difference(date).inDays;

  if (difference == 0) {
    return 'hoy a las ${_formatClock(localDate)}';
  }

  if (difference == 1) {
    return 'ayer a las ${_formatClock(localDate)}';
  }

  return '${localDate.day}/'
      '${localDate.month}/'
      '${localDate.year}';
}

String _formatClock(DateTime value) {
  final hour =
      value.hour.toString().padLeft(2, '0');

  final minute =
      value.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}