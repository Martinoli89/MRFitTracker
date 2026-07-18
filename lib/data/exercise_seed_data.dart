import '../models/exercise.dart';

const exerciseSeedData = <Exercise>[
  // ─────────────────────────────────────────────
  // PECHO
  // ─────────────────────────────────────────────
  Exercise(
    id: 'bench_press',
    name: 'Press banca',
    muscleGroup: 'Pecho',
    equipment: 'Barra',
  ),
  Exercise(
    id: 'incline_bench_press',
    name: 'Press inclinado',
    muscleGroup: 'Pecho',
    equipment: 'Barra',
  ),
  Exercise(
    id: 'dumbbell_bench_press',
    name: 'Press con mancuernas',
    muscleGroup: 'Pecho',
    equipment: 'Mancuernas',
  ),
  Exercise(
    id: 'incline_dumbbell_press',
    name: 'Press inclinado con mancuernas',
    muscleGroup: 'Pecho',
    equipment: 'Mancuernas',
  ),
  Exercise(
    id: 'chest_fly_machine',
    name: 'Aperturas en máquina',
    muscleGroup: 'Pecho',
    equipment: 'Máquina',
  ),
  Exercise(
    id: 'cable_chest_fly',
    name: 'Cruce de poleas',
    muscleGroup: 'Pecho',
    equipment: 'Polea',
  ),
  Exercise(
    id: 'push_up',
    name: 'Flexiones',
    muscleGroup: 'Pecho',
    equipment: 'Peso corporal',
  ),

  // ─────────────────────────────────────────────
  // ESPALDA
  // ─────────────────────────────────────────────
  Exercise(
    id: 'deadlift',
    name: 'Peso muerto',
    muscleGroup: 'Espalda',
    equipment: 'Barra',
  ),
  Exercise(
    id: 'lat_pulldown',
    name: 'Jalón al pecho',
    muscleGroup: 'Espalda',
    equipment: 'Polea',
  ),
  Exercise(
    id: 'seated_cable_row',
    name: 'Remo sentado',
    muscleGroup: 'Espalda',
    equipment: 'Polea',
  ),
  Exercise(
    id: 'barbell_row',
    name: 'Remo con barra',
    muscleGroup: 'Espalda',
    equipment: 'Barra',
  ),
  Exercise(
    id: 'one_arm_dumbbell_row',
    name: 'Remo con mancuerna',
    muscleGroup: 'Espalda',
    equipment: 'Mancuerna',
  ),
  Exercise(
    id: 'pull_up',
    name: 'Dominadas',
    muscleGroup: 'Espalda',
    equipment: 'Peso corporal',
  ),
  Exercise(
    id: 'chest_supported_row',
    name: 'Remo con pecho apoyado',
    muscleGroup: 'Espalda',
    equipment: 'Máquina',
  ),

  // ─────────────────────────────────────────────
  // PIERNAS
  // ─────────────────────────────────────────────
  Exercise(
    id: 'squat',
    name: 'Sentadilla',
    muscleGroup: 'Piernas',
    equipment: 'Barra',
  ),
  Exercise(
    id: 'leg_press',
    name: 'Prensa de piernas',
    muscleGroup: 'Piernas',
    equipment: 'Máquina',
  ),
  Exercise(
    id: 'leg_extension',
    name: 'Extensión de cuádriceps',
    muscleGroup: 'Piernas',
    equipment: 'Máquina',
  ),
  Exercise(
    id: 'lying_leg_curl',
    name: 'Curl femoral acostado',
    muscleGroup: 'Piernas',
    equipment: 'Máquina',
  ),
  Exercise(
    id: 'romanian_deadlift',
    name: 'Peso muerto rumano',
    muscleGroup: 'Piernas',
    equipment: 'Barra',
  ),
  Exercise(
    id: 'bulgarian_split_squat',
    name: 'Sentadilla búlgara',
    muscleGroup: 'Piernas',
    equipment: 'Mancuernas',
  ),
  Exercise(
    id: 'walking_lunges',
    name: 'Zancadas caminando',
    muscleGroup: 'Piernas',
    equipment: 'Mancuernas',
  ),
  Exercise(
    id: 'standing_calf_raise',
    name: 'Elevación de pantorrillas',
    muscleGroup: 'Piernas',
    equipment: 'Máquina',
  ),

  // ─────────────────────────────────────────────
  // HOMBROS
  // ─────────────────────────────────────────────
  Exercise(
    id: 'overhead_press',
    name: 'Press militar',
    muscleGroup: 'Hombros',
    equipment: 'Barra',
  ),
  Exercise(
    id: 'dumbbell_shoulder_press',
    name: 'Press de hombros',
    muscleGroup: 'Hombros',
    equipment: 'Mancuernas',
  ),
  Exercise(
    id: 'lateral_raise',
    name: 'Elevaciones laterales',
    muscleGroup: 'Hombros',
    equipment: 'Mancuernas',
  ),
  Exercise(
    id: 'cable_lateral_raise',
    name: 'Elevación lateral en polea',
    muscleGroup: 'Hombros',
    equipment: 'Polea',
  ),
  Exercise(
    id: 'rear_delt_fly',
    name: 'Pájaros',
    muscleGroup: 'Hombros',
    equipment: 'Mancuernas',
  ),
  Exercise(
    id: 'face_pull',
    name: 'Face pull',
    muscleGroup: 'Hombros',
    equipment: 'Polea',
  ),

  // ─────────────────────────────────────────────
  // BRAZOS
  // ─────────────────────────────────────────────
  Exercise(
    id: 'dumbbell_biceps_curl',
    name: 'Curl de bíceps',
    muscleGroup: 'Brazos',
    equipment: 'Mancuernas',
  ),
  Exercise(
    id: 'barbell_biceps_curl',
    name: 'Curl con barra',
    muscleGroup: 'Brazos',
    equipment: 'Barra',
  ),
  Exercise(
    id: 'hammer_curl',
    name: 'Curl martillo',
    muscleGroup: 'Brazos',
    equipment: 'Mancuernas',
  ),
  Exercise(
    id: 'preacher_curl',
    name: 'Curl predicador',
    muscleGroup: 'Brazos',
    equipment: 'Máquina',
  ),
  Exercise(
    id: 'triceps_pushdown',
    name: 'Extensión de tríceps',
    muscleGroup: 'Brazos',
    equipment: 'Polea',
  ),
  Exercise(
    id: 'overhead_triceps_extension',
    name: 'Extensión sobre la cabeza',
    muscleGroup: 'Brazos',
    equipment: 'Mancuerna',
  ),
  Exercise(
    id: 'close_grip_bench_press',
    name: 'Press banca cerrado',
    muscleGroup: 'Brazos',
    equipment: 'Barra',
  ),
  Exercise(
    id: 'bench_dips',
    name: 'Fondos en banco',
    muscleGroup: 'Brazos',
    equipment: 'Peso corporal',
  ),

  // ─────────────────────────────────────────────
  // ABDOMEN
  // ─────────────────────────────────────────────
  Exercise(
    id: 'crunch',
    name: 'Crunch abdominal',
    muscleGroup: 'Abdomen',
    equipment: 'Peso corporal',
  ),
  Exercise(
    id: 'cable_crunch',
    name: 'Crunch en polea',
    muscleGroup: 'Abdomen',
    equipment: 'Polea',
  ),
  Exercise(
    id: 'plank',
    name: 'Plancha',
    muscleGroup: 'Abdomen',
    equipment: 'Peso corporal',
  ),
  Exercise(
    id: 'hanging_leg_raise',
    name: 'Elevación de piernas',
    muscleGroup: 'Abdomen',
    equipment: 'Peso corporal',
  ),
  Exercise(
    id: 'russian_twist',
    name: 'Giro ruso',
    muscleGroup: 'Abdomen',
    equipment: 'Peso corporal',
  ),
  Exercise(
    id: 'ab_wheel',
    name: 'Rueda abdominal',
    muscleGroup: 'Abdomen',
    equipment: 'Rueda',
  ),

  // ─────────────────────────────────────────────
  // CARDIO
  // ─────────────────────────────────────────────
  Exercise(
    id: 'treadmill_walk',
    name: 'Caminata en cinta',
    muscleGroup: 'Cardio',
    equipment: 'Cinta',
  ),
  Exercise(
    id: 'treadmill_run',
    name: 'Carrera en cinta',
    muscleGroup: 'Cardio',
    equipment: 'Cinta',
  ),
  Exercise(
    id: 'stationary_bike',
    name: 'Bicicleta estática',
    muscleGroup: 'Cardio',
    equipment: 'Bicicleta',
  ),
  Exercise(
    id: 'elliptical',
    name: 'Elíptica',
    muscleGroup: 'Cardio',
    equipment: 'Máquina',
  ),
  Exercise(
    id: 'rowing_machine',
    name: 'Remo cardiovascular',
    muscleGroup: 'Cardio',
    equipment: 'Remo',
  ),
  Exercise(
    id: 'jump_rope',
    name: 'Saltar la cuerda',
    muscleGroup: 'Cardio',
    equipment: 'Cuerda',
  ),
];