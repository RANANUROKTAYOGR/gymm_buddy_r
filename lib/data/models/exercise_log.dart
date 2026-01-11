class ExerciseLog {
  final int? id;
  final int workoutSessionId;
  final int exerciseId;
  final int orderInSession;
  final DateTime createdAt;

  ExerciseLog({
    this.id,
    required this.workoutSessionId,
    required this.exerciseId,
    required this.orderInSession,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_session_id': workoutSessionId,
      'exercise_id': exerciseId,
      'order_in_session': orderInSession,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      id: map['id'] as int?,
      workoutSessionId: map['workout_session_id'] as int,
      exerciseId: map['exercise_id'] as int,
      orderInSession: map['order_in_session'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
