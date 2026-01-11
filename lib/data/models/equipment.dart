class Equipment {
  final int? id;
  final int? gymBranchId; // Foreign Key to GYM_BRANCH
  final String name;
  final String? type; // Cardio, Strength, Free Weight, etc.
  final String? brand;
  final String? model;
  final String? qrCode; // For AR scanning
  final String? videoUrl; // YouTube video URL for exercise tutorial
  final String? description;
  final bool isAvailable;
  final DateTime? lastMaintenanceDate;
  final DateTime createdAt;

  Equipment({
    this.id,
    this.gymBranchId,
    required this.name,
    this.type,
    this.brand,
    this.model,
    this.qrCode,
    this.videoUrl,
    this.description,
    this.isAvailable = true,
    this.lastMaintenanceDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gym_branch_id': gymBranchId,
      'name': name,
      'type': type,
      'brand': brand,
      'model': model,
      'qr_code': qrCode,
      'video_url': videoUrl,
      'description': description,
      'is_available': isAvailable ? 1 : 0,
      'last_maintenance_date': lastMaintenanceDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'] as int?,
      gymBranchId: map['gym_branch_id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String?,
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      qrCode: map['qr_code'] as String?,
      videoUrl: map['video_url'] as String?,
      description: map['description'] as String?,
      isAvailable: (map['is_available'] as int) == 1,
      lastMaintenanceDate: map['last_maintenance_date'] != null
          ? DateTime.parse(map['last_maintenance_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Equipment{id: $id, name: $name, type: $type, brand: $brand}';
  }
}
