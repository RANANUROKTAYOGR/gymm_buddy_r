class UserDiet {
  final int? id;
  final int userId;
  final int dietPlanId;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? createdAt;

  UserDiet({
    this.id,
    required this.userId,
    required this.dietPlanId,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'diet_plan_id': dietPlanId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory UserDiet.fromMap(Map<String, dynamic> map) {
    return UserDiet(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      dietPlanId: map['diet_plan_id'] as int,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  UserDiet copyWith({
    int? id,
    int? userId,
    int? dietPlanId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserDiet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dietPlanId: dietPlanId ?? this.dietPlanId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
