class Exercise {
  final int? id;
  final String name;
  final String? description;
  final String? muscleGroup;
  final String? equipment;
  final String? videoUrl;
  final String? thumbnailImage;
  final String? stepImage1;
  final String? stepImage2;
  final DateTime createdAt;

  Exercise({
    this.id,
    required this.name,
    this.description,
    this.muscleGroup,
    this.equipment,
    this.videoUrl,
    this.thumbnailImage,
    this.stepImage1,
    this.stepImage2,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'video_url': videoUrl,
      'thumbnail_image': thumbnailImage,
      'step_image_1': stepImage1,
      'step_image_2': stepImage2,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      muscleGroup: map['muscle_group'] as String?,
      equipment: map['equipment'] as String?,
      videoUrl: map['video_url'] as String?,
      thumbnailImage: map['thumbnail_image'] as String?,
      stepImage1: map['step_image_1'] as String?,
      stepImage2: map['step_image_2'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Exercise copyWith({
    int? id,
    String? name,
    String? description,
    String? muscleGroup,
    String? equipment,
    String? videoUrl,
    String? thumbnailImage,
    String? stepImage1,
    String? stepImage2,
    DateTime? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailImage: thumbnailImage ?? this.thumbnailImage,
      stepImage1: stepImage1 ?? this.stepImage1,
      stepImage2: stepImage2 ?? this.stepImage2,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
