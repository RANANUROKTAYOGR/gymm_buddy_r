class BodyMeasurements {
  final int? id;
  final int userId; // Foreign Key to USER
  final DateTime measurementDate;
  final double? weight; // kg
  final double? height; // cm
  final double? bodyFatPercentage;
  final double? muscleMass; // kg
  final double? bmi;
  final double? chest; // cm
  final double? waist; // cm
  final double? hips; // cm
  final double? biceps; // cm
  final double? thighs; // cm
  final double? calves; // cm
  final String? photoPath; // Local file path for progress photo
  final String? notes;
  final DateTime createdAt;

  BodyMeasurements({
    this.id,
    required this.userId,
    required this.measurementDate,
    this.weight,
    this.height,
    this.bodyFatPercentage,
    this.muscleMass,
    this.bmi,
    this.chest,
    this.waist,
    this.hips,
    this.biceps,
    this.thighs,
    this.calves,
    this.photoPath,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'measurement_date': measurementDate.toIso8601String(),
      'weight': weight,
      'height': height,
      'body_fat_percentage': bodyFatPercentage,
      'muscle_mass': muscleMass,
      'bmi': bmi,
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'biceps': biceps,
      'thighs': thighs,
      'calves': calves,
      'photo_path': photoPath,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BodyMeasurements.fromMap(Map<String, dynamic> map) {
    return BodyMeasurements(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      measurementDate: DateTime.parse(map['measurement_date'] as String),
      weight: map['weight'] as double?,
      height: map['height'] as double?,
      bodyFatPercentage: map['body_fat_percentage'] as double?,
      muscleMass: map['muscle_mass'] as double?,
      bmi: map['bmi'] as double?,
      chest: map['chest'] as double?,
      waist: map['waist'] as double?,
      hips: map['hips'] as double?,
      biceps: map['biceps'] as double?,
      thighs: map['thighs'] as double?,
      calves: map['calves'] as double?,
      photoPath: map['photo_path'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'BodyMeasurements{id: $id, userId: $userId, date: $measurementDate, weight: $weight kg, height: $height cm}';
  }
}
