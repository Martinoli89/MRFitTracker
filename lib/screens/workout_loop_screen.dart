
import 'dart:async';
import '../widgets/exercise_note_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../data/exercise_seed_data.dart';
import '../data/workout_database.dart';
import '../models/exercise.dart';
import '../models/set_entry.dart';
import '../models/workout_exercise_record.dart';
import '../models/workout_session_record.dart';

enum WorkoutPhase {
  choosingFocus,
  choosingExercise,
  performingExercise,
  exerciseCompleted,
  workoutCompleted,
}

class WorkoutLoopScreen extends StatefulWidget {
  const WorkoutLoopScreen({super.key});

  @override
  State<WorkoutLoopScreen> createState() =>
      _WorkoutLoopScreenState();
}

class _WorkoutLoopScreenState
    extends State<WorkoutLoopScreen> {
  WorkoutPhase _phase = WorkoutPhase.choosingFocus;

  final Set<String> _selectedMuscleGroups = {};
  final Set<String> _completedExerciseIds = {};

  final List<Exercise> _recentExercises = [];
  final List<SetEntry> _currentSets = [];

  final List<WorkoutExerciseRecord>
      _completedExerciseRecords = [];

  final TextEditingController _exerciseSearchController =
      TextEditingController();

  Timer? _sessionTimer;
  Timer? _restTimer;

  Exercise? _activeExercise;

  late final DateTime _sessionStartedAt;
  DateTime? _sessionFinishedAt;

  int _elapsedSeconds = 0;

  final int _restSeconds = 90;
  int _restSecondsRemaining = 90;

  double _weightKg = 20;
  int _reps = 10;

  bool _isResting = false;
  bool _isSavingSession = false;

  String _exerciseNote = '';
  String _exerciseQuery = '';

  @override
  void initState() {
    super.initState();

    _sessionStartedAt = DateTime.now();
    _startSessionTimer();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _exerciseSearchController.dispose();

    super.dispose();
  }

  List<String> get _muscleGroups {
    final groups = exerciseSeedData
        .map((exercise) => exercise.muscleGroup)
        .toSet()
        .toList();

    groups.sort();

    return groups;
  }

  List<Exercise> get _filteredExercises {
    final normalizedQuery = _normalizeSearch(
      _exerciseQuery,
    );

    Iterable<Exercise> exercises;

    if (normalizedQuery.isNotEmpty) {
      exercises = exerciseSeedData.where((exercise) {
        final searchableText = _normalizeSearch(
          '${exercise.name} '
          '${exercise.muscleGroup} '
          '${exercise.equipment}',
        );

        return searchableText.contains(
          normalizedQuery,
        );
      });
    } else if (_selectedMuscleGroups.isEmpty) {
      exercises = exerciseSeedData;
    } else {
      exercises = exerciseSeedData.where((exercise) {
        return _selectedMuscleGroups.contains(
          exercise.muscleGroup,
        );
      });
    }

    final results = exercises.toList();

    results.sort((first, second) {
      final firstCompleted =
          _completedExerciseIds.contains(first.id);

      final secondCompleted =
          _completedExerciseIds.contains(second.id);

      if (firstCompleted != secondCompleted) {
        return firstCompleted ? 1 : -1;
      }

      return first.name.compareTo(second.name);
    });

    return results;
  }

  List<Exercise> get _quickExercises {
    if (_recentExercises.isNotEmpty) {
      return _recentExercises.take(5).toList();
    }

    return exerciseSeedData.where((exercise) {
      if (_selectedMuscleGroups.isEmpty) {
        return true;
      }

      return _selectedMuscleGroups.contains(
        exercise.muscleGroup,
      );
    }).take(5).toList();
  }

  double get _currentExerciseVolume {
    return _currentSets.fold<double>(
      0,
      (total, set) => total + set.volume,
    );
  }

  int get _totalCompletedSets {
    return _completedExerciseRecords.fold<int>(
      0,
      (total, exercise) =>
          total + exercise.sets.length,
    );
  }

  double get _totalCompletedVolume {
    return _completedExerciseRecords.fold<double>(
      0,
      (total, exercise) =>
          total + exercise.totalVolume,
    );
  }

  String get _phaseLabel {
    switch (_phase) {
      case WorkoutPhase.choosingFocus:
        return 'PREPARANDO SESIÓN';

      case WorkoutPhase.choosingExercise:
        return 'ELIGE UN EJERCICIO';

      case WorkoutPhase.performingExercise:
        return 'SESIÓN EN CURSO';

      case WorkoutPhase.exerciseCompleted:
        return 'EJERCICIO COMPLETADO';

      case WorkoutPhase.workoutCompleted:
        return 'SESIÓN COMPLETADA';
    }
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        final now = DateTime.now();

        setState(() {
          _elapsedSeconds = now
              .difference(_sessionStartedAt)
              .inSeconds;
        });
      },
    );
  }

  void _selectMuscleGroup(String group) {
    if (_selectedMuscleGroups.contains(group)) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _selectedMuscleGroups
        ..clear()
        ..add(group);
    });
  }

  void _continueFromFocus() {
    if (_selectedMuscleGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona un grupo muscular.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _phase = WorkoutPhase.choosingExercise;
    });
  }

  void _selectExercise(Exercise exercise) {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    _restTimer?.cancel();

    setState(() {
      _activeExercise = exercise;
      _currentSets.clear();

      _exerciseNote = '';
      _isResting = false;

      _weightKg = 20;
      _reps = 10;

      _phase = WorkoutPhase.performingExercise;
    });
  }

  void _clearExerciseSearch() {
    _exerciseSearchController.clear();

    setState(() {
      _exerciseQuery = '';
    });
  }

  void _showCreateExerciseMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'La creación de ejercicios propios será un módulo posterior.',
        ),
      ),
    );
  }

  void _completeSet() {
    HapticFeedback.mediumImpact();

    setState(() {
      _currentSets.add(
        SetEntry(
          weightKg: _weightKg,
          reps: _reps,
        ),
      );
    });

    _startRestTimer();
  }

  void _copySetValues(SetEntry set) {
    HapticFeedback.selectionClick();

    setState(() {
      _weightKg = set.weightKg;
      _reps = set.reps;
    });
  }

  void _decreaseWeight() {
    HapticFeedback.selectionClick();

    setState(() {
      _weightKg = (_weightKg - 2.5)
          .clamp(0.0, 1000.0)
          .toDouble();
    });
  }

  void _increaseWeight() {
    HapticFeedback.selectionClick();

    setState(() {
      _weightKg += 2.5;
    });
  }

  void _decreaseReps() {
    HapticFeedback.selectionClick();

    setState(() {
      _reps = (_reps - 1)
          .clamp(1, 999)
          .toInt();
    });
  }

  void _increaseReps() {
    HapticFeedback.selectionClick();

    setState(() {
      _reps++;
    });
  }

  void _startRestTimer() {
    _restTimer?.cancel();

    setState(() {
      _isResting = true;
      _restSecondsRemaining = _restSeconds;
    });

    _resumeRestTimer();
  }

  void _resumeRestTimer() {
    _restTimer?.cancel();

    _restTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_restSecondsRemaining <= 1) {
          timer.cancel();

          HapticFeedback.mediumImpact();

          setState(() {
            _restSecondsRemaining = 0;
          });

          return;
        }

        setState(() {
          _restSecondsRemaining--;
        });
      },
    );
  }

  void _addRestTime() {
    HapticFeedback.selectionClick();

    setState(() {
      _restSecondsRemaining += 15;
    });

    if (!(_restTimer?.isActive ?? false)) {
      _resumeRestTimer();
    }
  }

  void _prepareNextSet() {
    _restTimer?.cancel();

    HapticFeedback.selectionClick();

    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
  }

  void _finishExercise() {
    if (_currentSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa al menos una serie antes de terminar.',
          ),
        ),
      );

      return;
    }

    final completedExercise = _activeExercise;

    if (completedExercise == null) {
      return;
    }

    _restTimer?.cancel();
    HapticFeedback.mediumImpact();

    final exerciseRecord = WorkoutExerciseRecord(
      exerciseId: completedExercise.id,
      exerciseName: completedExercise.name,
      muscleGroup: completedExercise.muscleGroup,
      equipment: completedExercise.equipment,
      note: _exerciseNote,
      sets: List<SetEntry>.unmodifiable(
        _currentSets.map(
          (set) => SetEntry(
            weightKg: set.weightKg,
            reps: set.reps,
          ),
        ),
      ),
    );

    setState(() {
      _isResting = false;

      _completedExerciseRecords.add(
        exerciseRecord,
      );

      _completedExerciseIds.add(
        completedExercise.id,
      );

      _recentExercises.removeWhere(
        (exercise) =>
            exercise.id == completedExercise.id,
      );

      _recentExercises.insert(
        0,
        completedExercise,
      );

      if (_recentExercises.length > 5) {
        _recentExercises.removeLast();
      }

      _phase = WorkoutPhase.exerciseCompleted;
    });
  }

  void _chooseAnotherExercise() {
    _exerciseSearchController.clear();

    setState(() {
      _activeExercise = null;
      _currentSets.clear();
      _exerciseQuery = '';

      _phase = WorkoutPhase.choosingExercise;
    });
  }

  void _finishWorkout() {
    if (_completedExerciseRecords.isEmpty) {
      return;
    }

    _restTimer?.cancel();
    _sessionTimer?.cancel();

    HapticFeedback.mediumImpact();

    final finishedAt = DateTime.now();

    setState(() {
      _isResting = false;

      _sessionFinishedAt = finishedAt;

      _elapsedSeconds = finishedAt
          .difference(_sessionStartedAt)
          .inSeconds;

      _phase = WorkoutPhase.workoutCompleted;
    });
  }

  Future<void> _saveWorkoutAndExit() async {
    if (_isSavingSession ||
        _completedExerciseRecords.isEmpty) {
      return;
    }

    final finishedAt =
        _sessionFinishedAt ?? DateTime.now();

    final duration = finishedAt
        .difference(_sessionStartedAt)
        .inSeconds;

    final session = WorkoutSessionRecord(
      startedAt: _sessionStartedAt,
      finishedAt: finishedAt,
      durationSeconds: duration < 1 ? 1 : duration,
      exercises:
          List<WorkoutExerciseRecord>.unmodifiable(
        _completedExerciseRecords,
      ),
    );

    setState(() {
      _isSavingSession = true;
    });

    try {
      await WorkoutDatabase.instance.insertSession(
        session,
      );

      if (!mounted) {
        return;
      }

      HapticFeedback.mediumImpact();

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingSession = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible guardar la sesión: $error',
          ),
        ),
      );
    }
  }

  Future<void> _openNoteSheet() async {
  final note = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceAlt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(30),
      ),
    ),
    builder: (sheetContext) {
      return ExerciseNoteSheet(
        exerciseName:
            _activeExercise?.name ?? 'Ejercicio',
        initialNote: _exerciseNote,
      );
    },
  );

  if (!mounted || note == null) {
    return;
  }

  setState(() {
    _exerciseNote = note;
  });
}

  Future<void> _confirmExit() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceAlt,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¿Salir del entrenamiento?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Los ejercicios de esta sesión no se guardarán.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Salir sin guardar',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text(
                    'Seguir entrenando',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _SessionHeader(
              elapsedTime: _formatDuration(
                _elapsedSeconds,
              ),
              phaseLabel: _phaseLabel,
              onClose: _confirmExit,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 360,
                ),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (
                  child,
                  animation,
                ) {
                  final offsetAnimation =
                      Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
                child: _buildPhase(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case WorkoutPhase.choosingFocus:
        return _buildFocusSelection();

      case WorkoutPhase.choosingExercise:
        return _buildExerciseSelection();

      case WorkoutPhase.performingExercise:
        return _buildExerciseLoop();

      case WorkoutPhase.exerciseCompleted:
        return _buildExerciseSummary();

      case WorkoutPhase.workoutCompleted:
        return _buildWorkoutSummary();
    }
  }

  Widget _buildFocusSelection() {
    return ListView(
      key: const ValueKey('focus'),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        28,
      ),
      children: [
        const Text(
          '¿Qué quieres\ntrabajar hoy?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Elige el grupo muscular que quieres trabajar. Podrás cambiarlo después al seleccionar otro ejercicio.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final group in _muscleGroups)
              FilterChip(
                label: Text(group),
                selected:
                    _selectedMuscleGroups.contains(
                  group,
                ),
                onSelected: (_) {
                  _selectMuscleGroup(group);
                },
                selectedColor:
                    AppColors.wineStrong,
                backgroundColor:
                    AppColors.surface,
                side: BorderSide(
                  color:
                      _selectedMuscleGroups.contains(
                    group,
                  )
                      ? AppColors.wineStrong
                      : AppColors.border,
                ),
                labelStyle: TextStyle(
                  color:
                      _selectedMuscleGroups.contains(
                    group,
                  )
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _continueFromFocus,
          icon: const Icon(
            Icons.arrow_forward_rounded,
          ),
          label: const Text('Continuar'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseSelection() {
    final exercises = _filteredExercises;
    final quickExercises = _quickExercises;

    final hasQuery =
        _exerciseQuery.trim().isNotEmpty;

    return Column(
      key: const ValueKey(
        'exercise-selection',
      ),
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            0,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Elige un ejercicio',
                      style: TextStyle(
                        color:
                            AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Toca uno para comenzar inmediatamente.',
                      style: TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (_completedExerciseRecords
                  .isNotEmpty)
                TextButton(
                  onPressed: _finishWorkout,
                  child: const Text('Finalizar'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: TextField(
            controller:
                _exerciseSearchController,
            textInputAction:
                TextInputAction.search,
            onChanged: (value) {
              setState(() {
                _exerciseQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText:
                  'Buscar ejercicio, músculo o equipo',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon: hasQuery
                  ? IconButton(
                      tooltip:
                          'Limpiar búsqueda',
                      onPressed:
                          _clearExerciseSearch,
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(20),
                borderSide:
                    const BorderSide(
                  color: AppColors.border,
                ),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(20),
                borderSide:
                    const BorderSide(
                  color: AppColors.border,
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(20),
                borderSide:
                    const BorderSide(
                  color:
                      AppColors.wineStrong,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: _muscleGroups.length,
            separatorBuilder: (_, __) {
              return const SizedBox(width: 8);
            },
            itemBuilder: (context, index) {
              final group =
                  _muscleGroups[index];

              final selected =
                  _selectedMuscleGroups
                      .contains(group);

              return FilterChip(
                label: Text(group),
                selected: selected,
                onSelected: (_) {
                  _selectMuscleGroup(group);
                },
                selectedColor:
                    AppColors.wineDark,
                backgroundColor:
                    AppColors.surface,
                side: BorderSide(
                  color: selected
                      ? AppColors.wine
                      : AppColors.border,
                ),
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        if (!hasQuery &&
            quickExercises.isNotEmpty) ...[
          const SizedBox(height: 18),
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Text(
              _recentExercises.isEmpty
                  ? 'Sugeridos rápidos'
                  : 'Usados recientemente',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              scrollDirection:
                  Axis.horizontal,
              itemCount: quickExercises.length,
              separatorBuilder: (_, __) {
                return const SizedBox(
                  width: 10,
                );
              },
              itemBuilder: (
                context,
                index,
              ) {
                final exercise =
                    quickExercises[index];

                return _QuickExerciseCard(
                  exercise: exercise,
                  onTap: () {
                    _selectExercise(exercise);
                  },
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasQuery
                      ? 'Resultados'
                      : 'Ejercicios disponibles',
                  style: const TextStyle(
                    color:
                        AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${exercises.length}',
                style: const TextStyle(
                  color:
                      AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: exercises.isEmpty
              ? _EmptyExerciseResults(
                  query: _exerciseQuery,
                  onClear:
                      _clearExerciseSearch,
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    2,
                    20,
                    12,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior
                          .onDrag,
                  itemCount: exercises.length,
                  separatorBuilder: (_, __) {
                    return const SizedBox(
                      height: 9,
                    );
                  },
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    final exercise =
                        exercises[index];

                    return _ExerciseListTile(
                      exercise: exercise,
                      completed:
                          _completedExerciseIds
                              .contains(
                        exercise.id,
                      ),
                      onTap: () {
                        _selectExercise(
                          exercise,
                        );
                      },
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            4,
            20,
            12,
          ),
          child: OutlinedButton.icon(
            onPressed:
                _showCreateExerciseMessage,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'Crear ejercicio propio',
            ),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseLoop() {
    final exercise = _activeExercise;

    if (exercise == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      key: const ValueKey('exercise-loop'),
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        14,
      ),
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final isCompact =
              constraints.maxHeight < 620;

          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              _ExerciseLoopTitle(
                exercise: exercise,
                setCount: _currentSets.length,
                compact: isCompact,
              ),
              SizedBox(
                height: isCompact ? 8 : 14,
              ),
              Expanded(
                child: _ExerciseSeriesPanel(
                  setNumber:
                      _currentSets.length + 1,
                  weightKg: _weightKg,
                  reps: _reps,
                  sets: _currentSets,
                  hasNote:
                      _exerciseNote.isNotEmpty,
                  compact: isCompact,
                  onDecreaseWeight:
                      _decreaseWeight,
                  onIncreaseWeight:
                      _increaseWeight,
                  onDecreaseReps:
                      _decreaseReps,
                  onIncreaseReps:
                      _increaseReps,
                  onSelectSet:
                      _copySetValues,
                  onOpenNote:
                      _openNoteSheet,
                ),
              ),
              SizedBox(
                height: isCompact ? 8 : 12,
              ),
              AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 280,
                ),
                switchInCurve:
                    Curves.easeOutCubic,
                switchOutCurve:
                    Curves.easeInCubic,
                transitionBuilder: (
                  child,
                  animation,
                ) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: 1,
                      child: child,
                    ),
                  );
                },
                child: _isResting
                    ? _RestDecisionDock(
                        key: const ValueKey(
                          'rest-decision-dock',
                        ),
                        secondsRemaining:
                            _restSecondsRemaining,
                        compact: isCompact,
                        onAddTime:
                            _addRestTime,
                        onNextSet:
                            _prepareNextSet,
                        onFinishExercise:
                            _finishExercise,
                      )
                    : _CompleteSetDock(
                        key: const ValueKey(
                          'complete-set-dock',
                        ),
                        onComplete:
                            _completeSet,
                        compact: isCompact,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExerciseSummary() {
    return Padding(
      key: const ValueKey(
        'exercise-summary',
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.wineStrong,
            size: 72,
          ),
          const SizedBox(height: 22),
          Text(
            '${_activeExercise?.name ?? 'Ejercicio'} completado',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_currentSets.length} series · '
            '${_formatWeight(_currentExerciseVolume)} '
            'kg de volumen',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  _chooseAnotherExercise,
              icon: const Icon(
                Icons.arrow_forward_rounded,
              ),
              label: const Text(
                'Elegir otro ejercicio',
              ),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _finishWorkout,
            child: const Text(
              'Finalizar entrenamiento',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSummary() {
    return Padding(
      key: const ValueKey(
        'workout-summary',
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.wineStrong,
            size: 70,
          ),
          const SizedBox(height: 20),
          const Text(
            'Entrenamiento\ncompletado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              height: 1.08,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 26),
          _SummaryMetric(
            label: 'Tiempo',
            value: _formatDuration(
              _elapsedSeconds,
            ),
          ),
          _SummaryMetric(
            label: 'Ejercicios',
            value:
                '${_completedExerciseRecords.length}',
          ),
          _SummaryMetric(
            label: 'Series',
            value: '$_totalCompletedSets',
          ),
          _SummaryMetric(
            label: 'Volumen',
            value:
                '${_formatWeight(_totalCompletedVolume)} kg',
          ),
          const SizedBox(height: 18),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_rounded,
                  color:
                      AppColors.wineStrong,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'La sesión aparecerá en Historial',
                  style: TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSavingSession
                  ? null
                  : _saveWorkoutAndExit,
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 180,
                ),
                child: _isSavingSession
                    ? const Row(
                        key: ValueKey(
                          'saving',
                        ),
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          SizedBox(
                            width: 19,
                            height: 19,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Guardando...',
                          ),
                        ],
                      )
                    : const Row(
                        key: ValueKey(
                          'save',
                        ),
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Icon(
                            Icons
                                .check_rounded,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Guardar y salir',
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  final String elapsedTime;
  final String phaseLabel;
  final VoidCallback onClose;

  const _SessionHeader({
    required this.elapsedTime,
    required this.phaseLabel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        18,
        8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              phaseLabel,
              style: const TextStyle(
                color:
                    AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const Icon(
            Icons.timer_outlined,
            color: AppColors.wineStrong,
            size: 18,
          ),
          const SizedBox(width: 7),
          Text(
            elapsedTime,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickExerciseCard
    extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _QuickExerciseCard({
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 174,
      child: Material(
        color: AppColors.surfaceAlt,
        borderRadius:
            BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.wineDark,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    _iconForMuscleGroup(
                      exercise.muscleGroup,
                    ),
                    color:
                        AppColors.textPrimary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        exercise.name,
                        maxLines: 2,
                        overflow: TextOverflow
                            .ellipsis,
                        style: const TextStyle(
                          color: AppColors
                              .textPrimary,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        exercise.muscleGroup,
                        maxLines: 1,
                        overflow: TextOverflow
                            .ellipsis,
                        style: const TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseListTile
    extends StatelessWidget {
  final Exercise exercise;
  final bool completed;
  final VoidCallback onTap;

  const _ExerciseListTile({
    required this.exercise,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius:
          BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(19),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 72,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(19),
            border: Border.all(
              color: completed
                  ? AppColors.wine
                      .withValues(alpha: 0.65)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: completed
                      ? AppColors.wineDark
                      : AppColors.surfaceAlt,
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                  border: Border.all(
                    color: completed
                        ? AppColors.wine
                        : AppColors.border,
                  ),
                ),
                child: Icon(
                  _iconForMuscleGroup(
                    exercise.muscleGroup,
                  ),
                  color:
                      AppColors.textPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: AppColors
                            .textPrimary,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.muscleGroup} · '
                      '${exercise.equipment}',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: AppColors
                            .textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (completed) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets
                      .symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        AppColors.wineDark,
                    borderRadius:
                        BorderRadius.circular(
                      999,
                    ),
                  ),
                  child: const Text(
                    'HECHO',
                    style: TextStyle(
                      color: AppColors
                          .textPrimary,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ] else
                const Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  color:
                      AppColors.textSecondary,
                  size: 15,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyExerciseResults
    extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _EmptyExerciseResults({
    required this.query,
    required this.onClear,
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
              Icons.search_off_rounded,
              color: AppColors.textSecondary,
              size: 54,
            ),
            const SizedBox(height: 14),
            const Text(
              'No encontramos ejercicios',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              query.trim().isEmpty
                  ? 'Prueba seleccionando otro grupo muscular.'
                  : 'No hay coincidencias para '
                      '“${query.trim()}”.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:
                    AppColors.textSecondary,
              ),
            ),
            if (query.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onClear,
                child: const Text(
                  'Limpiar búsqueda',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseLoopTitle
    extends StatelessWidget {
  final Exercise exercise;
  final int setCount;
  final bool compact;

  const _ExerciseLoopTitle({
    required this.exercise,
    required this.setCount,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 42 : 48,
          height: compact ? 42 : 48,
          decoration: BoxDecoration(
            color: AppColors.wineDark,
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.wine,
            ),
          ),
          child: Icon(
            _iconForMuscleGroup(
              exercise.muscleGroup,
            ),
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      AppColors.textPrimary,
                  fontSize:
                      compact ? 21 : 24,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${exercise.muscleGroup} · '
                '${exercise.equipment}',
                style: const TextStyle(
                  color:
                      AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Text(
            '$setCount series',
            style: const TextStyle(
              color:
                  AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseSeriesPanel
    extends StatelessWidget {
  final int setNumber;
  final double weightKg;
  final int reps;
  final List<SetEntry> sets;

  final bool hasNote;
  final bool compact;

  final VoidCallback onDecreaseWeight;
  final VoidCallback onIncreaseWeight;
  final VoidCallback onDecreaseReps;
  final VoidCallback onIncreaseReps;

  final ValueChanged<SetEntry> onSelectSet;
  final VoidCallback onOpenNote;

  const _ExerciseSeriesPanel({
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.sets,
    required this.hasNote,
    required this.compact,
    required this.onDecreaseWeight,
    required this.onIncreaseWeight,
    required this.onDecreaseReps,
    required this.onIncreaseReps,
    required this.onSelectSet,
    required this.onOpenNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            'SERIE $setNumber',
            style: const TextStyle(
              color:
                  AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.15,
            ),
          ),
          SizedBox(
            height: compact ? 8 : 14,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child:
                      _QuickValueControl(
                    label: 'PESO',
                    value: _formatWeight(
                      weightKg,
                    ),
                    unit: 'kg',
                    compact: compact,
                    onDecrease:
                        onDecreaseWeight,
                    onIncrease:
                        onIncreaseWeight,
                  ),
                ),
                Container(
                  width: 1,
                  margin:
                      EdgeInsets.symmetric(
                    horizontal:
                        compact ? 8 : 14,
                    vertical: 10,
                  ),
                  color: AppColors.border,
                ),
                Expanded(
                  child:
                      _QuickValueControl(
                    label: 'REPETICIONES',
                    value: '$reps',
                    unit: 'reps',
                    compact: compact,
                    onDecrease:
                        onDecreaseReps,
                    onIncrease:
                        onIncreaseReps,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: compact ? 6 : 10,
          ),
          _SetHistoryStrip(
            sets: sets,
            compact: compact,
            onSelectSet: onSelectSet,
          ),
          SizedBox(
            height: compact ? 6 : 10,
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenNote,
              icon: Icon(
                hasNote
                    ? Icons
                        .check_circle_outline_rounded
                    : Icons
                        .edit_note_rounded,
                size: 18,
              ),
              label: Text(
                hasNote
                    ? 'Nota guardada'
                    : 'Nota rápida',
              ),
              style:
                  OutlinedButton.styleFrom(
                padding:
                    EdgeInsets.symmetric(
                  vertical:
                      compact ? 10 : 12,
                ),
                textStyle:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickValueControl
    extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool compact;

  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuickValueControl({
    required this.label,
    required this.value,
    required this.unit,
    required this.compact,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color:
                AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        SizedBox(
          height: compact ? 4 : 8,
        ),
        AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 160,
          ),
          child: Text(
            value,
            key: ValueKey(value),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: compact ? 27 : 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            color:
                AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        SizedBox(
          height: compact ? 5 : 10,
        ),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            _RoundControlButton(
              icon: Icons.remove_rounded,
              onPressed: onDecrease,
              compact: compact,
            ),
            SizedBox(
              width: compact ? 10 : 14,
            ),
            _RoundControlButton(
              icon: Icons.add_rounded,
              onPressed: onIncrease,
              compact: compact,
              emphasized: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundControlButton
    extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  final bool compact;
  final bool emphasized;

  const _RoundControlButton({
    required this.icon,
    required this.onPressed,
    required this.compact,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 44.0;

    return Material(
      color: emphasized
          ? AppColors.wineDark
          : AppColors.surfaceAlt,
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(14),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: emphasized
                  ? AppColors.wine
                  : AppColors.border,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.textPrimary,
            size: compact ? 20 : 23,
          ),
        ),
      ),
    );
  }
}

class _SetHistoryStrip
    extends StatelessWidget {
  final List<SetEntry> sets;
  final bool compact;

  final ValueChanged<SetEntry> onSelectSet;

  const _SetHistoryStrip({
    required this.sets,
    required this.compact,
    required this.onSelectSet,
  });

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) {
      return Container(
        height: compact ? 38 : 44,
        alignment: Alignment.center,
        child: const Text(
          'Tus series aparecerán aquí',
          style: TextStyle(
            color:
                AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      );
    }

    return SizedBox(
      height: compact ? 40 : 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sets.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (
          context,
          index,
        ) {
          final set = sets[index];

          return Material(
            color: AppColors.surfaceAlt,
            borderRadius:
                BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                onSelectSet(set);
              },
              borderRadius:
                  BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets
                    .symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Text(
                  '${index + 1} · '
                  '${_formatWeight(set.weightKg)}×'
                  '${set.reps}',
                  style: const TextStyle(
                    color:
                        AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompleteSetDock
    extends StatelessWidget {
  final VoidCallback onComplete;
  final bool compact;

  const _CompleteSetDock({
    super.key,
    required this.onComplete,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 66 : 76,
      child: FilledButton(
        onPressed: onComplete,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 18,
            vertical: compact ? 10 : 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 38 : 42,
              height: compact ? 38 : 42,
              decoration: BoxDecoration(
                color: AppColors.background
                    .withValues(alpha: 0.25),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color:
                    AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completar serie',
                    style: TextStyle(
                      color: AppColors
                          .textPrimary,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Confirma la serie y comienza el descanso',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors
                          .textPrimary,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RestDecisionDock
    extends StatelessWidget {
  final int secondsRemaining;
  final bool compact;

  final VoidCallback onAddTime;
  final VoidCallback onNextSet;
  final VoidCallback onFinishExercise;

  const _RestDecisionDock({
    super.key,
    required this.secondsRemaining,
    required this.compact,
    required this.onAddTime,
    required this.onNextSet,
    required this.onFinishExercise,
  });

  bool get _restFinished =>
      secondsRemaining <= 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.wine,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.25,
            ),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: compact ? 38 : 42,
                height: compact ? 38 : 42,
                decoration: BoxDecoration(
                  color:
                      AppColors.wineDark,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  _restFinished
                      ? Icons.check_rounded
                      : Icons
                          .hourglass_bottom_rounded,
                  color:
                      AppColors.textPrimary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _restFinished
                          ? 'LISTO PARA CONTINUAR'
                          : 'DESCANSO',
                      style:
                          const TextStyle(
                        color: AppColors
                            .textSecondary,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: 180,
                      ),
                      child: Text(
                        _restFinished
                            ? '¿Qué quieres hacer ahora?'
                            : _formatDuration(
                                secondsRemaining,
                              ),
                        key: ValueKey(
                          _restFinished
                              ? 'finished'
                              : secondsRemaining,
                        ),
                        style: TextStyle(
                          color: AppColors
                              .textPrimary,
                          fontSize:
                              _restFinished
                                  ? 15
                                  : 20,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_restFinished)
                TextButton(
                  onPressed: onAddTime,
                  child:
                      const Text('+15s'),
                ),
            ],
          ),
          SizedBox(
            height: compact ? 10 : 12,
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNextSet,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'Otra serie',
                  ),
                  style:
                      FilledButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(
                      vertical:
                          compact ? 11 : 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      onFinishExercise,
                  icon: const Icon(
                    Icons.flag_outlined,
                    size: 19,
                  ),
                  label: const Text(
                    'Terminar',
                  ),
                  style: OutlinedButton
                      .styleFrom(
                    padding:
                        EdgeInsets.symmetric(
                      vertical:
                          compact ? 11 : 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric
    extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color:
                    AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
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

String _normalizeSearch(String value) {
  return value
      .toLowerCase()
      .trim()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');
}

String _formatDuration(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String _formatWeight(double weight) {
  if (weight == weight.roundToDouble()) {
    return weight.toInt().toString();
  }

  return weight.toStringAsFixed(1);
}