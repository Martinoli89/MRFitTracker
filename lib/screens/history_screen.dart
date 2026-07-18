import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../data/workout_database.dart';
import '../models/workout_exercise_record.dart';
import '../models/workout_session_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  WorkoutDatabase get _database => WorkoutDatabase.instance;

  late Future<List<WorkoutSessionRecord>> _sessionsFuture;

  List<WorkoutSessionRecord> _loadedSessions = [];

  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  bool _selectionInitialized = false;

  @override
  void initState() {
    super.initState();

    final today = _dateOnly(DateTime.now());

    _visibleMonth = DateTime(
      today.year,
      today.month,
    );

    _selectedDate = today;

    _sessionsFuture = _loadSessions();

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

  Future<List<WorkoutSessionRecord>> _loadSessions() async {
    final sessions = await _database.getSessions();

    sessions.sort(
      (first, second) => second.startedAt.compareTo(
        first.startedAt,
      ),
    );

    _loadedSessions = sessions;

    if (!_selectionInitialized) {
      _selectionInitialized = true;

      if (sessions.isNotEmpty) {
        final mostRecentDate = _dateOnly(
          sessions.first.startedAt.toLocal(),
        );

        _selectedDate = mostRecentDate;

        _visibleMonth = DateTime(
          mostRecentDate.year,
          mostRecentDate.month,
        );
      }
    }

    return sessions;
  }

  void _handleDatabaseRevision() {
    if (!mounted) {
      return;
    }

    setState(() {
      _sessionsFuture = _loadSessions();
    });
  }

  Future<void> _refresh() async {
    final future = _loadSessions();

    setState(() {
      _sessionsFuture = future;
    });

    await future;
  }

  void _selectDate(DateTime date) {
    HapticFeedback.selectionClick();

    setState(() {
      _selectedDate = _dateOnly(date);
    });
  }

  void _changeMonth(int difference) {
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + difference,
    );

    final currentMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month,
    );

    if (nextMonth.isAfter(currentMonth)) {
      return;
    }

    final sessionsInNextMonth = _loadedSessions.where(
      (session) {
        final date = session.startedAt.toLocal();

        return date.year == nextMonth.year &&
            date.month == nextMonth.month;
      },
    ).toList();

    final DateTime nextSelectedDate;

    if (sessionsInNextMonth.isNotEmpty) {
      sessionsInNextMonth.sort(
        (first, second) => second.startedAt.compareTo(
          first.startedAt,
        ),
      );

      nextSelectedDate = _dateOnly(
        sessionsInNextMonth.first.startedAt.toLocal(),
      );
    } else {
      nextSelectedDate = DateTime(
        nextMonth.year,
        nextMonth.month,
        1,
      );
    }

    HapticFeedback.selectionClick();

    setState(() {
      _visibleMonth = nextMonth;
      _selectedDate = nextSelectedDate;
    });
  }

  Future<void> _openSessionDetails(
    WorkoutSessionRecord session,
  ) async {
    HapticFeedback.selectionClick();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SessionDetailSheet(
          session: session,
        );
      },
    );
  }

  Future<void> _confirmDeleteSession(
    WorkoutSessionRecord session,
  ) async {
    final sessionId = session.id;

    if (sessionId == null) {
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              22,
              20,
              28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.wineDark,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Eliminar este entrenamiento?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'También desaparecerán sus ejercicios, series y notas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop(true);
                    },
                    child: const Text('Eliminar'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop(false);
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    HapticFeedback.mediumImpact();

    await _database.deleteSession(sessionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<WorkoutSessionRecord>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const _HistoryLoading();
          }

          if (snapshot.hasError) {
            return _HistoryError(
              onRetry: _refresh,
            );
          }

          final sessions =
              snapshot.data ?? const <WorkoutSessionRecord>[];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: _HistoryContent(
              sessions: sessions,
              visibleMonth: _visibleMonth,
              selectedDate: _selectedDate,
              onPreviousMonth: () {
                _changeMonth(-1);
              },
              onNextMonth: () {
                _changeMonth(1);
              },
              onSelectDate: _selectDate,
              onOpenSession: _openSessionDetails,
              onDeleteSession: _confirmDeleteSession,
            ),
          );
        },
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  final List<WorkoutSessionRecord> sessions;

  final DateTime visibleMonth;
  final DateTime selectedDate;

  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<WorkoutSessionRecord> onOpenSession;
  final ValueChanged<WorkoutSessionRecord> onDeleteSession;

  const _HistoryContent({
    required this.sessions,
    required this.visibleMonth,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
    required this.onOpenSession,
    required this.onDeleteSession,
  });

  Map<DateTime, List<WorkoutSessionRecord>>
      get _sessionsByDate {
    final result =
        <DateTime, List<WorkoutSessionRecord>>{};

    for (final session in sessions) {
      final date = _dateOnly(
        session.startedAt.toLocal(),
      );

      result.putIfAbsent(
        date,
        () => <WorkoutSessionRecord>[],
      );

      result[date]!.add(session);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final sessionsByDate = _sessionsByDate;

    final selectedSessions =
        sessionsByDate[_dateOnly(selectedDate)] ??
            const <WorkoutSessionRecord>[];

    final monthlySessions = sessions.where(
      (session) {
        final date = session.startedAt.toLocal();

        return date.year == visibleMonth.year &&
            date.month == visibleMonth.month;
      },
    ).toList();

    final monthlyTrainingDays = monthlySessions
        .map(
          (session) => _dateOnly(
            session.startedAt.toLocal(),
          ),
        )
        .toSet()
        .length;

    final monthlySets = monthlySessions.fold<int>(
      0,
      (total, session) => total + session.totalSets,
    );

    final currentMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month,
    );

    final canGoNext = visibleMonth.isBefore(
      currentMonth,
    );

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
          'HISTORIAL',
          style: TextStyle(
            color: AppColors.wineStrong,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Tu ritmo,\ndía por día.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Los días marcados guardan alguna sesión. Toca uno para revisar qué hiciste.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),

        _MonthlySummary(
          activeDays: monthlyTrainingDays,
          sessions: monthlySessions.length,
          sets: monthlySets,
        ),

        const SizedBox(height: 14),

        _WorkoutCalendar(
          visibleMonth: visibleMonth,
          selectedDate: selectedDate,
          sessionsByDate: sessionsByDate,
          canGoNext: canGoNext,
          onPreviousMonth: onPreviousMonth,
          onNextMonth: onNextMonth,
          onSelectDate: onSelectDate,
        ),

        const SizedBox(height: 28),

        _SelectedDayHeader(
          date: selectedDate,
          sessionCount: selectedSessions.length,
        ),

        const SizedBox(height: 12),

        if (selectedSessions.isEmpty)
          _NoWorkoutForDay(
            date: selectedDate,
          )
        else
          for (final session in selectedSessions) ...[
            _WorkoutSessionCard(
              session: session,
              onTap: () {
                onOpenSession(session);
              },
              onDelete: () {
                onDeleteSession(session);
              },
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  final int activeDays;
  final int sessions;
  final int sets;

  const _MonthlySummary({
    required this.activeDays,
    required this.sessions,
    required this.sets,
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
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MonthlyMetric(
              icon: Icons.calendar_today_outlined,
              value: '$activeDays',
              label: activeDays == 1
                  ? 'día activo'
                  : 'días activos',
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _MonthlyMetric(
              icon: Icons.fitness_center_rounded,
              value: '$sessions',
              label: sessions == 1
                  ? 'sesión'
                  : 'sesiones',
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _MonthlyMetric(
              icon: Icons.layers_rounded,
              value: '$sets',
              label: sets == 1
                  ? 'serie'
                  : 'series',
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MonthlyMetric({
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
          size: 19,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
      height: 52,
      margin: const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      color: AppColors.border,
    );
  }
}

class _WorkoutCalendar extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDate;

  final Map<DateTime, List<WorkoutSessionRecord>>
      sessionsByDate;

  final bool canGoNext;

  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  final ValueChanged<DateTime> onSelectDate;

  const _WorkoutCalendar({
    required this.visibleMonth,
    required this.selectedDate,
    required this.sessionsByDate,
    required this.canGoNext,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;

    final leadingEmptyDays = firstDay.weekday - 1;

    final usedCells =
        leadingEmptyDays + daysInMonth;

    final totalCells =
        ((usedCells + 6) ~/ 7) * 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                tooltip: 'Mes anterior',
                icon: const Icon(
                  Icons.chevron_left_rounded,
                ),
              ),
              Expanded(
                child: Text(
                  _formatMonthYear(
                    visibleMonth,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: canGoNext
                    ? onNextMonth
                    : null,
                tooltip: 'Mes siguiente',
                icon: const Icon(
                  Icons.chevron_right_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const Row(
            children: [
              _WeekdayLabel('L'),
              _WeekdayLabel('M'),
              _WeekdayLabel('M'),
              _WeekdayLabel('J'),
              _WeekdayLabel('V'),
              _WeekdayLabel('S'),
              _WeekdayLabel('D'),
            ],
          ),

          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final dayNumber =
                  index - leadingEmptyDays + 1;

              if (dayNumber < 1 ||
                  dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                visibleMonth.year,
                visibleMonth.month,
                dayNumber,
              );

              final sessions =
                  sessionsByDate[_dateOnly(date)] ??
                      const <WorkoutSessionRecord>[];

              return _CalendarDay(
                date: date,
                selected: _isSameDay(
                  date,
                  selectedDate,
                ),
                isToday: _isSameDay(
                  date,
                  DateTime.now(),
                ),
                sessionCount: sessions.length,
                onTap: () {
                  onSelectDate(date);
                },
              );
            },
          ),

          const SizedBox(height: 14),

          const Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              _CalendarLegend(
                marked: true,
                label: 'Entrenaste',
              ),
              SizedBox(width: 20),
              _CalendarLegend(
                marked: false,
                label: 'Sin sesión',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final DateTime date;

  final bool selected;
  final bool isToday;

  final int sessionCount;

  final VoidCallback onTap;

  const _CalendarDay({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.sessionCount,
    required this.onTap,
  });

  bool get hasWorkout => sessionCount > 0;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? AppColors.wineStrong
        : hasWorkout
            ? AppColors.wineDark
            : Colors.transparent;

    final borderColor = selected
        ? AppColors.wineStrong
        : isToday
            ? AppColors.wine
            : hasWorkout
                ? AppColors.wine.withValues(
                    alpha: 0.65,
                  )
                : Colors.transparent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 190,
          ),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: selected || hasWorkout
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        selected || hasWorkout
                            ? FontWeight.w800
                            : FontWeight.w600,
                  ),
                ),
              ),

              if (hasWorkout && !selected)
                Positioned(
                  bottom: 5,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.wineStrong,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

              if (sessionCount > 1)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 14,
                    height: 14,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.background
                              .withValues(alpha: 0.5)
                          : AppColors.wineStrong,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$sessionCount',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  final bool marked;
  final String label;

  const _CalendarLegend({
    required this.marked,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: marked
                ? AppColors.wineDark
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: marked
                  ? AppColors.wine
                  : AppColors.border,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _SelectedDayHeader extends StatelessWidget {
  final DateTime date;
  final int sessionCount;

  const _SelectedDayHeader({
    required this.date,
    required this.sessionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'DÍA SELECCIONADO',
                style: TextStyle(
                  color: AppColors.wineStrong,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _formatSelectedDate(date),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Text(
          sessionCount == 0
              ? 'Sin sesiones'
              : sessionCount == 1
                  ? '1 sesión'
                  : '$sessionCount sesiones',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NoWorkoutForDay extends StatelessWidget {
  final DateTime date;

  const _NoWorkoutForDay({
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final futureDate = _dateOnly(date).isAfter(
      _dateOnly(DateTime.now()),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              futureDate
                  ? Icons.event_outlined
                  : Icons.bedtime_outlined,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  futureDate
                      ? 'Este día todavía no llega'
                      : 'Ese día no entrenaste',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  futureDate
                      ? 'Cuando registres una sesión aparecerá marcada aquí.'
                      : 'Un día sin sesión también puede ser parte del descanso.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
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

class _WorkoutSessionCard extends StatelessWidget {
  final WorkoutSessionRecord session;

  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorkoutSessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final groups =
        session.muscleGroups.toList()..sort();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.wineDark,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.wine,
                      ),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entrenamiento de las '
                          '${_formatClock(session.startedAt)}',
                          style: const TextStyle(
                            color:
                                AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatFullDuration(
                            session.durationSeconds,
                          ),
                          style: const TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Eliminar entrenamiento',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SessionTag(
                    icon: Icons.fitness_center_rounded,
                    text:
                        '${session.totalExercises} ejercicios',
                  ),
                  _SessionTag(
                    icon: Icons.layers_rounded,
                    text: '${session.totalSets} series',
                  ),
                  _SessionTag(
                    icon: Icons.monitor_weight_outlined,
                    text:
                        '${_formatWeight(session.totalVolume)} kg',
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                groups.join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  Text(
                    'Ver lo que hiciste',
                    style: TextStyle(
                      color: AppColors.wineStrong,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.wineStrong,
                    size: 17,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SessionTag({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.wineStrong,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionDetailSheet extends StatelessWidget {
  final WorkoutSessionRecord session;

  const _SessionDetailSheet({
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (
        context,
        scrollController,
      ) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                30,
              ),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius:
                          BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  _formatSessionDate(
                    session.startedAt,
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatClock(session.startedAt)} · '
                  '${_formatFullDuration(session.durationSeconds)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DetailMetric(
                          label: 'Ejercicios',
                          value:
                              '${session.totalExercises}',
                        ),
                      ),
                      Expanded(
                        child: _DetailMetric(
                          label: 'Series',
                          value: '${session.totalSets}',
                        ),
                      ),
                      Expanded(
                        child: _DetailMetric(
                          label: 'Volumen',
                          value:
                              '${_formatWeight(session.totalVolume)} kg',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Lo que hiciste',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                for (var index = 0;
                    index < session.exercises.length;
                    index++) ...[
                  _ExerciseDetailCard(
                    number: index + 1,
                    exercise:
                        session.exercises[index],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DetailMetric({
    required this.label,
    required this.value,
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
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ExerciseDetailCard extends StatelessWidget {
  final int number;
  final WorkoutExerciseRecord exercise;

  const _ExerciseDetailCard({
    required this.number,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.wineDark,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exercise.muscleGroup} · '
                      '${exercise.equipment}',
                      style: const TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0;
                  index < exercise.sets.length;
                  index++)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Text(
                    '${index + 1} · '
                    '${_formatWeight(exercise.sets[index].weightKg)} kg × '
                    '${exercise.sets[index].reps}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (exercise.note.trim().isNotEmpty) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.wineDark.withValues(
                  alpha: 0.55,
                ),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.wineStrong,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exercise.note,
                      style: const TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _HistoryError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _HistoryError({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.textSecondary,
              size: 55,
            ),
            const SizedBox(height: 14),
            const Text(
              'No pudimos abrir tu historial',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tus sesiones siguen guardadas. Probemos cargarlo nuevamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
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

DateTime _dateOnly(DateTime value) {
  return DateTime(
    value.year,
    value.month,
    value.day,
  );
}

bool _isSameDay(
  DateTime first,
  DateTime second,
) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _formatMonthYear(DateTime value) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  return '${months[value.month - 1]} ${value.year}';
}

String _formatSelectedDate(DateTime value) {
  const weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  return '${weekdays[value.weekday - 1]} '
      '${value.day} de '
      '${months[value.month - 1]}';
}

String _formatSessionDate(DateTime value) {
  return _formatSelectedDate(
    value.toLocal(),
  );
}

String _formatClock(DateTime value) {
  final date = value.toLocal();

  final hour =
      date.hour.toString().padLeft(2, '0');

  final minute =
      date.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

String _formatFullDuration(
  int totalSeconds,
) {
  final hours = totalSeconds ~/ 3600;

  final minutes =
      (totalSeconds % 3600) ~/ 60;

  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '$hours h $minutes min';
  }

  if (minutes > 0) {
    return '$minutes min $seconds s';
  }

  return '$seconds segundos';
}

String _formatWeight(double weight) {
  if (weight == weight.roundToDouble()) {
    return weight.toInt().toString();
  }

  return weight.toStringAsFixed(1);
}