import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/database/database_helper.dart';
import '../../data/models.dart';
import '../../utils/one_rep_max_calculator.dart';

class WorkoutDetailScreen extends StatefulWidget {
  const WorkoutDetailScreen({
    super.key,
    required this.session,
  });

  final WorkoutSession session;

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<_ExerciseDetail> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutDetails();
  }

  Future<void> _loadWorkoutDetails() async {
    final exerciseLogs = await _db.getExerciseLogsBySession(widget.session.id!);
    
    List<_ExerciseDetail> details = [];
    for (var log in exerciseLogs) {
      final exercise = await _db.getExercise(log.exerciseId);
      final sets = await _db.getSetDetailsByLog(log.id!);
      
      if (exercise != null) {
        details.add(_ExerciseDetail(
          exercise: exercise,
          sets: sets,
        ));
      }
    }
    
    setState(() {
      _exercises = details;
      _isLoading = false;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF0A0E27) : Colors.white;
    
    final duration = widget.session.totalDuration ?? 0;
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    final durationStr = hours > 0 ? '${hours}s ${minutes}dk' : '${minutes}dk';

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.white.withAlpha((0.1 * 255).toInt())
                  : Colors.black.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.arrow_back_rounded, 
                size: 24.sp,
                color: isDarkMode ? Colors.white : Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Antrenman Detayı',
          style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold, 
              color: isDarkMode ? Colors.white : Colors.black),
        ),
      ),
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00FFA3),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.all(20.w),
                  children: [
                    _buildHeaderCard(durationStr),
                    SizedBox(height: 24.h),
                    if (_exercises.isEmpty)
                      _buildEmptyState()
                    else
                      ..._exercises.map((detail) => Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: _ExerciseDetailCard(detail: detail),
                          )),
                    SizedBox(height: 40.h),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String durationStr) {
    final dateStr = '${widget.session.startTime.day}/${widget.session.startTime.month}/${widget.session.startTime.year}';
    final timeStr = '${widget.session.startTime.hour.toString().padLeft(2, '0')}:${widget.session.startTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F3A).withOpacity(0.8),
            const Color(0xFF1A1F3A).withAlpha((0.6 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withAlpha((0.1 * 255).toInt()), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFA3).withAlpha((0.1 * 255).toInt()),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(Icons.fitness_center_rounded, color: Colors.white, size: 32.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.sessionType ?? 'Antrenman',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$dateStr • $timeStr',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withAlpha((0.6 * 255).toInt()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.05 * 255).toInt()),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.timer_rounded, 'Süre', durationStr),
                Container(
                  width: 1.w,
                  height: 40.h,
                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                ),
                _buildStatItem(Icons.fitness_center_rounded, 'Egzersiz', '${_exercises.length}'),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                ),
                _buildStatItem(
                  Icons.repeat_rounded,
                  'Set',
                  '${_exercises.fold<int>(0, (sum, e) => sum + e.sets.length)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00FFA3), size: 24.sp),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withAlpha((0.6 * 255).toInt()),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F3A).withAlpha((0.5 * 255).toInt()),
            const Color(0xFF1A1F3A).withAlpha((0.3 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withAlpha((0.1 * 255).toInt()), width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48.sp, color: Colors.white.withAlpha((0.3 * 255).toInt())),
            SizedBox(height: 12.h),
            Text(
              'Bu antrenman için veri bulunamadı',
              style: TextStyle(color: Colors.white.withAlpha((0.5 * 255).toInt()), fontSize: 15.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseDetail {
  final Exercise exercise;
  final List<SetDetails> sets;

  _ExerciseDetail({required this.exercise, required this.sets});
}

class _ExerciseDetailCard extends StatelessWidget {
  const _ExerciseDetailCard({required this.detail});

  final _ExerciseDetail detail;

  @override
  Widget build(BuildContext context) {
    double totalWeight = detail.sets.fold(0.0, (sum, set) => sum + (set.weight ?? 0) * (set.reps ?? 0));
    int totalReps = detail.sets.fold(0, (sum, set) => sum + (set.reps ?? 0));
    
    // En ağır setin 1RM'ini hesapla (maksimum ağırlık ve o setteki tekrar)
    double maxWeight = 0;
    int repsAtMaxWeight = 0;
    for (var set in detail.sets) {
      if ((set.weight ?? 0) > maxWeight) {
        maxWeight = set.weight ?? 0;
        repsAtMaxWeight = set.reps ?? 0;
      }
    }
    double oneRepMax = OneRepMaxCalculator.calculate(maxWeight, repsAtMaxWeight);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F3A).withAlpha((0.7 * 255).toInt()),
            const Color(0xFF1A1F3A).withAlpha((0.5 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withAlpha((0.1 * 255).toInt()), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.fitness_center_rounded, color: Colors.white, size: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.exercise.name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (detail.exercise.muscleGroup != null)
                            Text(
                              detail.exercise.muscleGroup!,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.white.withAlpha((0.6 * 255).toInt()),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (detail.exercise.videoUrl != null && detail.exercise.videoUrl!.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.play_circle_fill,
                          color: Colors.red,
                          size: 32.sp,
                        ),
                        tooltip: 'Kullanım Videosunu İzle',
                        onPressed: () async {
                          final Uri uri = Uri.parse(detail.exercise.videoUrl!);
                          try {
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Video açılamadı')),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Video açılırken hata: $e')),
                              );
                            }
                          }
                        },
                      ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FFA3).withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${detail.sets.length} set',
                        style: TextStyle(
                          color: const Color(0xFF00FFA3),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        Icons.scale_rounded,
                        'Toplam Hacim',
                        '${totalWeight.toStringAsFixed(1)} kg',
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        Icons.repeat_rounded,
                        'Toplam Tekrar',
                        '$totalReps',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // Maksimum Güç Hesaplayıcı
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1FD9C1).withOpacity(0.2),
                        const Color(0xFF5B9BCC).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFF1FD9C1).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1FD9C1), Color(0xFF5B9BCC)],
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.analytics_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maksimum Güç Hesaplayıcı',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF1FD9C1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              oneRepMax > 0
                                  ? 'Tahmini 1RM: ${oneRepMax.toStringAsFixed(1)} kg'
                                  : 'Tahmini 1RM: - kg',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (maxWeight > 0 && repsAtMaxWeight > 0)
                              Text(
                                'En ağır set: ${maxWeight.toStringAsFixed(1)} kg × $repsAtMaxWeight tekrar',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
            ),
            child: Column(
              children: detail.sets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                final isLast = index == detail.sets.length - 1;
                
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    border: !isLast
                        ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withAlpha((0.05 * 255).toInt()),
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            '${set.setNumber}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 16.sp,
                              color: Colors.white.withAlpha((0.5 * 255).toInt()),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${set.weight ?? 0} kg',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            size: 16.sp,
                            color: Colors.white.withAlpha((0.5 * 255).toInt()),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${set.reps ?? 0} tekrar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.05 * 255).toInt()),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withAlpha((0.6 * 255).toInt()), size: 20.sp),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withAlpha((0.5 * 255).toInt()),
            ),
          ),
        ],
      ),
    );
  }
}
