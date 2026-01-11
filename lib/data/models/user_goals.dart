class UserGoals {
  final int? id;
  final int userId; // Foreign Key to USER
  final String goalType; // Weight Loss, Muscle Gain, Strength, Endurance, etc.
  final String? targetMetric; // weight, body_fat, muscle_mass, etc.
  final double? currentValue;
  final double? targetValue;
  final DateTime? targetDate;
  final String? description;
  final String status; // active, completed, cancelled, paused
  final double? progress; // percentage 0-100
  final DateTime createdAt;
  final DateTime? completedAt;

  UserGoals({
    this.id,
    required this.userId,
    required this.goalType,
    this.targetMetric,
    this.currentValue,
    this.targetValue,
    this.targetDate,
    this.description,
    this.status = 'active',
    this.progress = 0.0,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'goal_type': goalType,
      'target_metric': targetMetric,
      'current_value': currentValue,
      'target_value': targetValue,
      'target_date': targetDate?.toIso8601String(),
      'description': description,
      'status': status,
      'progress': progress,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory UserGoals.fromMap(Map<String, dynamic> map) {
    return UserGoals(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      goalType: map['goal_type'] as String,
      targetMetric: map['target_metric'] as String?,
      currentValue: map['current_value'] as double?,
      targetValue: map['target_value'] as double?,
      targetDate: map['target_date'] != null
          ? DateTime.parse(map['target_date'] as String)
          : null,
      description: map['description'] as String?,
      status: map['status'] as String? ?? 'active',
      progress: map['progress'] as double? ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'UserGoals{id: $id, userId: $userId, goalType: $goalType, status: $status, progress: $progress%}';
  }
}
