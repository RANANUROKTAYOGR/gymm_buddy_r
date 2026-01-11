import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/database/database_helper.dart';
import '../../data/models.dart';
import 'exercise_detail_screen.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late Future<List<Exercise>> _exercises;
  String _selectedFilter = 'Tümü';

  final List<String> _muscleGroups = [
    'Tümü',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
  ];

  @override
  void initState() {
    super.initState();
    _exercises = _db.getAllExercises();
  }

  void _refreshExercises() {
    setState(() {
      _exercises = _db.getAllExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF0A0E27) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: isDarkMode
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0E27),
                    Color(0xFF1A1F3A),
                    Color(0xFF0A0E27),
                  ],
                ),
              )
            : BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                      ).createShader(bounds),
                      child: Text(
                        'Egzersiz Kütüphanesi',
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildFilterChips(),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Exercise>>(
                  future: _exercises,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00FFA3),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    }

                    var exercises = snapshot.data ?? [];

                    if (_selectedFilter != 'Tümü') {
                      exercises = exercises
                          .where((e) => e.muscleGroup == _selectedFilter)
                          .toList();
                    }

                    if (exercises.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center_outlined,
                              size: 64.sp,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Henüz egzersiz yok',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18.sp,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        return _ExerciseCard(exercise: exercises[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExerciseDialog(),
        backgroundColor: const Color(0xFF00FFA3),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Egzersiz'),
      ),
    );
  }

  Widget _buildFilterChips() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _muscleGroups.length,
        itemBuilder: (context, index) {
          final group = _muscleGroups[index];
          final isSelected = _selectedFilter == group;

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(group),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = group;
                });
              },
              backgroundColor: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.1),
              selectedColor: const Color(0xFF00FFA3),
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14.sp,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF00FFA3)
                      : (isDarkMode
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.3)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddExerciseDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedMuscle = 'Chest';
    String selectedEquipment = 'Barbell';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
            ).createShader(bounds),
            child: Text(
              'Yeni Egzersiz',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20.sp,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    labelText: 'Egzersiz Adı',
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        color: Color(0xFF00FFA3),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: descController,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        color: Color(0xFF00FFA3),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  value: selectedMuscle,
                  dropdownColor: const Color(0xFF1A1F3A),
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    labelText: 'Kas Grubu',
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        color: Color(0xFF00FFA3),
                        width: 2,
                      ),
                    ),
                  ),
                  items: _muscleGroups
                      .where((g) => g != 'Tümü')
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedMuscle = value!);
                  },
                ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  value: selectedEquipment,
                  dropdownColor: const Color(0xFF1A1F3A),
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    labelText: 'Ekipman',
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        color: Color(0xFF00FFA3),
                        width: 2,
                      ),
                    ),
                  ),
                  items:
                      [
                            'Barbell',
                            'Dumbbell',
                            'Machine',
                            'Bodyweight',
                            'Cable',
                            'Other',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedEquipment = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Egzersiz adı gerekli!')),
                  );
                  return;
                }

                final exercise = Exercise(
                  name: nameController.text,
                  description: descController.text.isEmpty
                      ? null
                      : descController.text,
                  muscleGroup: selectedMuscle,
                  equipment: selectedEquipment,
                  createdAt: DateTime.now(),
                );

                await _db.createExercise(exercise);

                if (mounted) {
                  Navigator.pop(context);
                  _refreshExercises();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Egzersiz eklendi! ✓'),
                      backgroundColor: Color(0xFF00FFA3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFA3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text('Ekle', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(exercise: exercise),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1F3A).withOpacity(0.7),
              const Color(0xFF1A1F3A).withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              padding: exercise.thumbnailImage != null
                  ? EdgeInsets.zero
                  : EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                gradient: exercise.thumbnailImage != null
                    ? null
                    : _getMuscleGradient(exercise.muscleGroup),
                borderRadius: BorderRadius.circular(14.r),
                image: exercise.thumbnailImage != null
                    ? DecorationImage(
                        image: AssetImage(exercise.thumbnailImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: exercise.thumbnailImage != null
                  ? null
                  : Icon(
                      _getMuscleIcon(exercise.muscleGroup),
                      color: Colors.white,
                      size: 26.sp,
                    ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFA3).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          exercise.muscleGroup ?? 'Unknown',
                          style: TextStyle(
                            color: const Color(0xFF00FFA3),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        _getEquipmentIcon(exercise.equipment),
                        size: 14.sp,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        exercise.equipment ?? 'N/A',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  if (exercise.description != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      exercise.description!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getMuscleGradient(String? muscle) {
    switch (muscle) {
      case 'Chest':
        return const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
        );
      case 'Back':
        return const LinearGradient(
          colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
        );
      case 'Legs':
        return const LinearGradient(
          colors: [Color(0xFFFFB800), Color(0xFFFF6B00)],
        );
      case 'Shoulders':
        return const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
        );
      case 'Arms':
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF607D8B), Color(0xFF455A64)],
        );
    }
  }

  IconData _getMuscleIcon(String? muscle) {
    switch (muscle) {
      case 'Chest':
        return Icons.favorite_rounded;
      case 'Back':
        return Icons.fitness_center_rounded;
      case 'Legs':
        return Icons.directions_run_rounded;
      case 'Shoulders':
        return Icons.accessibility_new_rounded;
      case 'Arms':
        return Icons.back_hand_rounded;
      default:
        return Icons.sports_gymnastics_rounded;
    }
  }

  IconData _getEquipmentIcon(String? equipment) {
    switch (equipment) {
      case 'Barbell':
        return Icons.sports_bar_rounded;
      case 'Dumbbell':
        return Icons.fitness_center_rounded;
      case 'Machine':
        return Icons.precision_manufacturing_rounded;
      case 'Bodyweight':
        return Icons.accessibility_rounded;
      default:
        return Icons.sports_rounded;
    }
  }
}
