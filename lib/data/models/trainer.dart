class Trainer {
  final int? id;
  final int gymBranchId;
  final String name;
  final String specialization;
  final String phone;
  final String? email;
  final String? bio;
  final String? photoUrl;
  final int yearsOfExperience;
  final bool isActive;
  final DateTime? createdAt;

  Trainer({
    this.id,
    required this.gymBranchId,
    required this.name,
    required this.specialization,
    required this.phone,
    this.email,
    this.bio,
    this.photoUrl,
    this.yearsOfExperience = 0,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gym_branch_id': gymBranchId,
      'name': name,
      'specialization': specialization,
      'phone': phone,
      'email': email,
      'bio': bio,
      'photo_url': photoUrl,
      'years_of_experience': yearsOfExperience,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Trainer.fromMap(Map<String, dynamic> map) {
    return Trainer(
      id: map['id'] as int?,
      gymBranchId: map['gym_branch_id'] as int,
      name: map['name'] as String,
      specialization: map['specialization'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      bio: map['bio'] as String?,
      photoUrl: map['photo_url'] as String?,
      yearsOfExperience: map['years_of_experience'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Trainer copyWith({
    int? id,
    int? gymBranchId,
    String? name,
    String? specialization,
    String? phone,
    String? email,
    String? bio,
    String? photoUrl,
    int? yearsOfExperience,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Trainer(
      id: id ?? this.id,
      gymBranchId: gymBranchId ?? this.gymBranchId,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
