class UserBadge {
  final int? id;
  final int userId;
  final String badgeCode; // e.g., SU_SAVASCISI, ILK_ADIM
  final String title; // Display name
  final String? description;
  final DateTime earnedAt;

  UserBadge({
    this.id,
    required this.userId,
    required this.badgeCode,
    required this.title,
    this.description,
    required this.earnedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'badge_code': badgeCode,
      'title': title,
      'description': description,
      'earned_at': earnedAt.toIso8601String(),
    };
  }

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      badgeCode: map['badge_code'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      earnedAt: DateTime.parse(map['earned_at'] as String),
    );
  }
}
