class SetDetails {
  final int? id;
  final int exerciseLogId;
  final int setNumber;
  final double? weight;
  final int? reps;
  final DateTime createdAt;

  SetDetails({
    this.id,
    required this.exerciseLogId,
    required this.setNumber,
    this.weight,
    this.reps,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_log_id': exerciseLogId,
      'set_number': setNumber,
      'weight': weight,
      'reps': reps,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SetDetails.fromMap(Map<String, dynamic> map) {
    return SetDetails(
      id: map['id'] as int?,
      exerciseLogId: map['exercise_log_id'] as int,
      setNumber: map['set_number'] as int,
      weight: map['weight'] as double?,
      reps: map['reps'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
