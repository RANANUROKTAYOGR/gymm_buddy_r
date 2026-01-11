class DietPlan {
  final int? id;
  final String name;
  final String description;
  final int dailyCalories;
  final int proteinPercentage;
  final int carbsPercentage;
  final int fatPercentage;
  final bool isActive;
  final DateTime? createdAt;

  DietPlan({
    this.id,
    required this.name,
    required this.description,
    required this.dailyCalories,
    required this.proteinPercentage,
    required this.carbsPercentage,
    required this.fatPercentage,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'daily_calories': dailyCalories,
      'protein_percentage': proteinPercentage,
      'carbs_percentage': carbsPercentage,
      'fat_percentage': fatPercentage,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory DietPlan.fromMap(Map<String, dynamic> map) {
    return DietPlan(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      dailyCalories: map['daily_calories'] as int,
      proteinPercentage: map['protein_percentage'] as int,
      carbsPercentage: map['carbs_percentage'] as int,
      fatPercentage: map['fat_percentage'] as int,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  DietPlan copyWith({
    int? id,
    String? name,
    String? description,
    int? dailyCalories,
    int? proteinPercentage,
    int? carbsPercentage,
    int? fatPercentage,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return DietPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      proteinPercentage: proteinPercentage ?? this.proteinPercentage,
      carbsPercentage: carbsPercentage ?? this.carbsPercentage,
      fatPercentage: fatPercentage ?? this.fatPercentage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
