class User {
  final int? id;
  final String name;
  final String? email;
  final DateTime? dateOfBirth;
  final double? height;
  final double? weight;
  final DateTime createdAt;

  User({
    this.id,
    required this.name,
    this.email,
    this.dateOfBirth,
    this.height,
    this.weight,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'height': height,
      'weight': weight,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String?,
      dateOfBirth: map['date_of_birth'] != null ? DateTime.parse(map['date_of_birth'] as String) : null,
      height: map['height'] as double?,
      weight: map['weight'] as double?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    DateTime? dateOfBirth,
    double? height,
    double? weight,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
