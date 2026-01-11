class WorkoutSession {
  final int? id;
  final int userId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? sessionType;
  final int? totalDuration;
  final String? notes;
  final DateTime createdAt;

  WorkoutSession({
    this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.sessionType,
    this.totalDuration,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'session_type': sessionType,
      'total_duration': totalDuration,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
      sessionType: map['session_type'] as String?,
      totalDuration: map['total_duration'] as int?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
