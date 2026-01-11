import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/database/database_helper.dart';
import '../../data/models.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final Equipment equipment;

  const EquipmentDetailScreen({super.key, required this.equipment});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = true;
  List<_WorkoutHistory> _workoutHistory = [];

  @override
  void initState() {
    super.initState();
    _loadLastWorkouts();
  }

  Future<void> _loadLastWorkouts() async {
    setState(() => _isLoading = true);

    try {
      // Get all users (for now we assume first user)
      final users = await _db.getAllUsers();
      if (users.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final userId = users.first.id!;

      // Get all workout sessions for this user
      final sessions = await _db.getWorkoutSessionsByUser(userId, 10);

      // Get all exercises to match equipment name
      final exercises = await _db.getAllExercises();
      final matchingExercises = exercises
          .where(
            (e) =>
                e.equipment?.toLowerCase() ==
                    widget.equipment.name.toLowerCase() ||
                e.name.toLowerCase().contains(
                  widget.equipment.name.toLowerCase(),
                ),
          )
          .toList();

      List<_WorkoutHistory> history = [];

      // For each matching exercise, get the workout data
      for (var exercise in matchingExercises) {
        for (var session in sessions) {
          final logs = await _db.getExerciseLogsBySession(session.id!);

          for (var log in logs) {
            if (log.exerciseId == exercise.id) {
              final sets = await _db.getSetDetailsByLog(log.id!);

              if (sets.isNotEmpty) {
                history.add(
                  _WorkoutHistory(
                    session: session,
                    exercise: exercise,
                    sets: sets,
                  ),
                );
              }
            }
          }
        }
      }

      // Sort by date (newest first)
      history.sort(
        (a, b) => b.session.startTime.compareTo(a.session.startTime),
      );

      // Take last 10 workouts
      if (history.length > 10) {
        history = history.sublist(0, 10);
      }

      setState(() {
        _workoutHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Hata - Antrenman geçmişi yüklenemedi: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF0A0E27)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Equipment Info
              _buildEquipmentInfo(),

              // Workout History
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00FFA3),
                        ),
                      )
                    : _workoutHistory.isEmpty
                    ? _buildEmptyState()
                    : _buildWorkoutList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
              ).createShader(bounds),
              child: Text(
                'Ekipman Detayları',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentInfo() {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FFA3).withOpacity(0.2),
            const Color(0xFF00D4FF).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF00FFA3).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFA3),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.equipment.name,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.equipment.type != null)
                      Text(
                        widget.equipment.type!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.equipment.brand != null ||
              widget.equipment.model != null) ...[
            SizedBox(height: 16.h),
            const Divider(color: Colors.white24),
            SizedBox(height: 16.h),
            Row(
              children: [
                if (widget.equipment.brand != null) ...[
                  Icon(
                    Icons.business,
                    size: 16.sp,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    widget.equipment.brand!,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 14.sp),
                  ),
                  SizedBox(width: 20.w),
                ],
                if (widget.equipment.model != null) ...[
                  Icon(
                    Icons.info_outline,
                    size: 16.sp,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    widget.equipment.model!,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 14.sp),
                  ),
                ],
              ],
            ),
          ],
          if (widget.equipment.description != null) ...[
            SizedBox(height: 16.h),
            Text(
              widget.equipment.description!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
          child: Text(
            'Son Antrenmanlar (${_workoutHistory.length})',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
            itemCount: _workoutHistory.length,
            itemBuilder: (context, index) {
              return _WorkoutHistoryCard(history: _workoutHistory[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80.sp, color: Colors.white.withOpacity(0.3)),
          SizedBox(height: 16.h),
          Text(
            'Henüz antrenman kaydı yok',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Bu ekipmanda yaptığınız antrenmanlar\nburada görünecek',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutHistory {
  final WorkoutSession session;
  final Exercise exercise;
  final List<SetDetails> sets;

  _WorkoutHistory({
    required this.session,
    required this.exercise,
    required this.sets,
  });
}

class _WorkoutHistoryCard extends StatelessWidget {
  final _WorkoutHistory history;

  const _WorkoutHistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final totalVolume = history.sets.fold<double>(
      0,
      (sum, set) => sum + ((set.weight ?? 0) * (set.reps ?? 0)),
    );
    final totalReps = history.sets.fold<int>(
      0,
      (sum, set) => sum + (set.reps ?? 0),
    );
    final maxWeight = history.sets
        .map((s) => s.weight ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F3A).withOpacity(0.7),
            const Color(0xFF1A1F3A).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.exercise.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _formatDate(history.session.startTime),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _StatChip(
                icon: Icons.repeat,
                label: '${history.sets.length} Set',
                color: const Color(0xFF00FFA3),
              ),
              SizedBox(width: 8.w),
              _StatChip(
                icon: Icons.fitness_center,
                label: '${maxWeight.toStringAsFixed(1)} kg',
                color: const Color(0xFF00D4FF),
              ),
              SizedBox(width: 8.w),
              _StatChip(
                icon: Icons.speed,
                label: '$totalReps reps',
                color: const Color(0xFFFF6B9D),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Toplam Volüm',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13.sp,
                  ),
                ),
                Text(
                  '${totalVolume.toStringAsFixed(0)} kg',
                  style: TextStyle(
                    color: const Color(0xFF00FFA3),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Bugün ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
