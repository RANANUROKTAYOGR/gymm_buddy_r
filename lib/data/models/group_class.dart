class GroupClass {
  final int? id;
  final int gymBranchId;
  final String className;
  final String? instructorName;
  final int maxCapacity;
  final String? schedule;
  final int duration;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? classDateTime; // Ders tarihi ve saati

  GroupClass({
    this.id,
    required this.gymBranchId,
    required this.className,
    this.instructorName,
    required this.maxCapacity,
    this.schedule,
    this.duration = 60,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.classDateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gym_branch_id': gymBranchId,
      'class_name': className,
      'instructor_name': instructorName,
      'max_capacity': maxCapacity,
      'schedule': schedule,
      'duration': duration,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'class_date_time': classDateTime?.toIso8601String(),
    };
  }

  factory GroupClass.fromMap(Map<String, dynamic> map) {
    return GroupClass(
      id: map['id'] as int?,
      gymBranchId: map['gym_branch_id'] as int,
      className: map['class_name'] as String,
      instructorName: map['instructor_name'] as String?,
      maxCapacity: map['max_capacity'] as int,
      schedule: map['schedule'] as String?,
      duration: map['duration'] as int? ?? 60,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      classDateTime: map['class_date_time'] != null
          ? DateTime.parse(map['class_date_time'] as String)
          : null,
    );
  }

  GroupClass copyWith({
    int? id,
    int? gymBranchId,
    String? className,
    String? instructorName,
    int? maxCapacity,
    String? schedule,
    int? duration,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? classDateTime,
  }) {
    return GroupClass(
      id: id ?? this.id,
      gymBranchId: gymBranchId ?? this.gymBranchId,
      className: className ?? this.className,
      instructorName: instructorName ?? this.instructorName,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      schedule: schedule ?? this.schedule,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      classDateTime: classDateTime ?? this.classDateTime,
    );
  }
}
