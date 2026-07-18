import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/set_entry.dart';
import '../models/workout_exercise_record.dart';
import '../models/workout_session_record.dart';

class WorkoutDatabase {
  WorkoutDatabase._();

  static final WorkoutDatabase instance =
      WorkoutDatabase._();

  static const String _databaseName =
      'mr_fittracker.db';

  static const int _databaseVersion = 1;

  static const String _sessionsTable =
      'workout_sessions';

  static const String _exercisesTable =
      'workout_exercises';

  static const String _setsTable =
      'workout_sets';

  Database? _database;

  /// Cada vez que se guarda o elimina una sesión,
  /// este valor cambia.
  ///
  /// Más adelante Historial escuchará este notifier
  /// para actualizarse automáticamente.
  final ValueNotifier<int> revision =
      ValueNotifier<int>(0);

  Future<Database> get database async {
    final existingDatabase = _database;

    if (existingDatabase != null) {
      return existingDatabase;
    }

    final openedDatabase = await _openDatabase();

    _database = openedDatabase;

    return openedDatabase;
  }

  Future<Database> _openDatabase() async {
    final databasesDirectory =
        await getDatabasesPath();

    final databasePath = path.join(
      databasesDirectory,
      _databaseName,
    );

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onConfigure: (database) async {
        await database.execute(
          'PRAGMA foreign_keys = ON',
        );
      },
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(
    Database database,
    int version,
  ) async {
    await database.execute(
      '''
      CREATE TABLE $_sessionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started_at TEXT NOT NULL,
        finished_at TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL
      )
      ''',
    );

    await database.execute(
      '''
      CREATE TABLE $_exercisesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        equipment TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        order_index INTEGER NOT NULL,
        FOREIGN KEY (session_id)
          REFERENCES $_sessionsTable (id)
          ON DELETE CASCADE
      )
      ''',
    );

    await database.execute(
      '''
      CREATE TABLE $_setsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        reps INTEGER NOT NULL,
        FOREIGN KEY (workout_exercise_id)
          REFERENCES $_exercisesTable (id)
          ON DELETE CASCADE
      )
      ''',
    );

    await database.execute(
      '''
      CREATE INDEX index_exercises_session
      ON $_exercisesTable (session_id)
      ''',
    );

    await database.execute(
      '''
      CREATE INDEX index_sets_exercise
      ON $_setsTable (workout_exercise_id)
      ''',
    );
  }

  Future<int> insertSession(
    WorkoutSessionRecord session,
  ) async {
    if (session.exercises.isEmpty) {
      throw ArgumentError(
        'No se puede guardar una sesión sin ejercicios.',
      );
    }

    final database = await this.database;

    final sessionId = await database.transaction(
      (transaction) async {
        final insertedSessionId =
            await transaction.insert(
          _sessionsTable,
          {
            'started_at':
                session.startedAt.toIso8601String(),
            'finished_at':
                session.finishedAt.toIso8601String(),
            'duration_seconds':
                session.durationSeconds,
          },
        );

        for (
          var exerciseIndex = 0;
          exerciseIndex < session.exercises.length;
          exerciseIndex++
        ) {
          final exercise =
              session.exercises[exerciseIndex];

          final workoutExerciseId =
              await transaction.insert(
            _exercisesTable,
            {
              'session_id': insertedSessionId,
              'exercise_id': exercise.exerciseId,
              'exercise_name':
                  exercise.exerciseName,
              'muscle_group':
                  exercise.muscleGroup,
              'equipment': exercise.equipment,
              'note': exercise.note,
              'order_index': exerciseIndex,
            },
          );

          for (
            var setIndex = 0;
            setIndex < exercise.sets.length;
            setIndex++
          ) {
            final set = exercise.sets[setIndex];

            await transaction.insert(
              _setsTable,
              {
                'workout_exercise_id':
                    workoutExerciseId,
                'set_number': setIndex + 1,
                'weight_kg': set.weightKg,
                'reps': set.reps,
              },
            );
          }
        }

        return insertedSessionId;
      },
    );

    revision.value++;

    return sessionId;
  }

  Future<List<WorkoutSessionRecord>>
      getSessions() async {
    final database = await this.database;

    final sessionRows = await database.query(
      _sessionsTable,
      orderBy: 'started_at DESC',
    );

    final sessions = <WorkoutSessionRecord>[];

    for (final sessionRow in sessionRows) {
      final sessionId = sessionRow['id'] as int;

      final exerciseRows = await database.query(
        _exercisesTable,
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'order_index ASC',
      );

      final exercises =
          <WorkoutExerciseRecord>[];

      for (final exerciseRow in exerciseRows) {
        final workoutExerciseId =
            exerciseRow['id'] as int;

        final setRows = await database.query(
          _setsTable,
          where: 'workout_exercise_id = ?',
          whereArgs: [workoutExerciseId],
          orderBy: 'set_number ASC',
        );

        final sets = setRows.map((setRow) {
          return SetEntry(
            id: setRow['id'] as int,
            weightKg:
                (setRow['weight_kg'] as num)
                    .toDouble(),
            reps: setRow['reps'] as int,
          );
        }).toList();

        exercises.add(
          WorkoutExerciseRecord(
            id: workoutExerciseId,
            exerciseId:
                exerciseRow['exercise_id']
                    as String,
            exerciseName:
                exerciseRow['exercise_name']
                    as String,
            muscleGroup:
                exerciseRow['muscle_group']
                    as String,
            equipment:
                exerciseRow['equipment']
                    as String,
            note:
                exerciseRow['note'] as String,
            sets: sets,
          ),
        );
      }

      sessions.add(
        WorkoutSessionRecord(
          id: sessionId,
          startedAt: DateTime.parse(
            sessionRow['started_at'] as String,
          ),
          finishedAt: DateTime.parse(
            sessionRow['finished_at'] as String,
          ),
          durationSeconds:
              sessionRow['duration_seconds']
                  as int,
          exercises: exercises,
        ),
      );
    }

    return sessions;
  }

  Future<WorkoutSessionRecord?> getSessionById(
    int sessionId,
  ) async {
    final sessions = await getSessions();

    for (final session in sessions) {
      if (session.id == sessionId) {
        return session;
      }
    }

    return null;
  }

  Future<int> getSessionCount() async {
    final database = await this.database;

    final result = await database.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM $_sessionsTable
      ''',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteSession(
    int sessionId,
  ) async {
    final database = await this.database;

    await database.delete(
      _sessionsTable,
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    revision.value++;
  }

  Future<void> deleteAllSessions() async {
    final database = await this.database;

    await database.delete(
      _sessionsTable,
    );

    revision.value++;
  }

  Future<void> close() async {
    final database = _database;

    if (database == null) {
      return;
    }

    await database.close();

    _database = null;
  }
}