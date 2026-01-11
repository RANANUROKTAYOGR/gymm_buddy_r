import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF0A0E27) : Colors.grey[50];

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.h,
            pinned: true,
            backgroundColor: isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                exercise.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              background: exercise.thumbnailImage != null
                  ? Image.asset(
                      exercise.thumbnailImage!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [const Color(0xFF1A1F3A), const Color(0xFF0A0E27)]
                              : [const Color(0xFF00FFA3), const Color(0xFF00D4FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.fitness_center,
                          size: 80.sp,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTags(context),
                  SizedBox(height: 24.h),
                  if (exercise.description != null) ...[
                    Text(
                      'Açıklama',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      exercise.description!,
                      style: TextStyle(
                        fontSize: 16.sp,
                        height: 1.5,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ],
                  if (exercise.stepImage1 != null || exercise.stepImage2 != null) ...[
                    Text(
                      'Hareket Adımları',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  if (exercise.stepImage1 != null) ...[
                    _buildStepImage(context, 'Adım 1', exercise.stepImage1!),
                    SizedBox(height: 16.h),
                  ],
                  if (exercise.stepImage2 != null) ...[
                    _buildStepImage(context, 'Adım 2', exercise.stepImage2!),
                    SizedBox(height: 16.h),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    return Row(
      children: [
        if (exercise.muscleGroup != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFF00FFA3).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.accessibility_new, size: 18.sp, color: const Color(0xFF00FFA3)),
                SizedBox(width: 8.w),
                Text(
                  exercise.muscleGroup!,
                  style: const TextStyle(
                    color: Color(0xFF00FFA3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(width: 12.w),
        if (exercise.equipment != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.fitness_center, size: 18.sp, color: Colors.blue),
                SizedBox(width: 8.w),
                Text(
                  exercise.equipment!,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStepImage(BuildContext context, String label, String imagePath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF00FFA3),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 300.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: Colors.black.withOpacity(0.2),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10.r,
                offset: Offset(0, 5.h),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
