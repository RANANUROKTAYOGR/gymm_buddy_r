class ExerciseImages {
  final int? id;
  final int exerciseId; // Foreign Key to EXERCISE
  final String imageUrl; // Local path or remote URL
  final String? imageType; // thumbnail, step1, step2, demo, ar_marker, etc.
  final int? orderIndex; // For ordering multiple images
  final String? caption;
  final bool isPrimary; // Main image for the exercise
  final DateTime createdAt;

  ExerciseImages({
    this.id,
    required this.exerciseId,
    required this.imageUrl,
    this.imageType,
    this.orderIndex,
    this.caption,
    this.isPrimary = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'image_url': imageUrl,
      'image_type': imageType,
      'order_index': orderIndex,
      'caption': caption,
      'is_primary': isPrimary ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExerciseImages.fromMap(Map<String, dynamic> map) {
    return ExerciseImages(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as int,
      imageUrl: map['image_url'] as String,
      imageType: map['image_type'] as String?,
      orderIndex: map['order_index'] as int?,
      caption: map['caption'] as String?,
      isPrimary: (map['is_primary'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'ExerciseImages{id: $id, exerciseId: $exerciseId, imageType: $imageType, isPrimary: $isPrimary}';
  }
}
