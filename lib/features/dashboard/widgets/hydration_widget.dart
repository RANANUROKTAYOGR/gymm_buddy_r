import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/hydration_service.dart';
import '../../../services/step_counter_service.dart';
import '../../../services/gamification_manager.dart';

class HydrationWidget extends StatefulWidget {
  const HydrationWidget({
    super.key,
    required this.userId,
    this.isCompact = false,
  });

  final int userId;
  final bool isCompact;

  @override
  State<HydrationWidget> createState() => _HydrationWidgetState();
}

class _HydrationWidgetState extends State<HydrationWidget>
    with SingleTickerProviderStateMixin {
  final HydrationService _hydrationService = HydrationService();
  final StepCounterService _stepService = StepCounterService();
  int _currentIntake = 0;
  int _dailyGoal = 2500;
  double _progress = 0.0;
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
    
    // Su değişikliklerini dinle
    HydrationService.waterChangeNotifier.addListener(_onWaterChanged);
  }

  @override
  void dispose() {
    HydrationService.waterChangeNotifier.removeListener(_onWaterChanged);
    _animationController.dispose();
    super.dispose();
  }
  
  void _onWaterChanged() {
    _loadData();
  }

  Future<void> _loadData() async {
    final intake = await _hydrationService.getTodayWaterIntake(widget.userId);
    final goal = await _hydrationService.getDailyWaterGoal(widget.userId);
    final progress = await _hydrationService.getProgress(widget.userId);

    if (!mounted) return;

    final oldProgress = _progressAnimation.value;
    
    setState(() {
      _currentIntake = intake;
      _dailyGoal = goal;
      _progress = progress;
      _isLoading = false;
    });

    _progressAnimation =
        Tween<double>(begin: oldProgress, end: progress).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
    
    await _animationController.forward(from: 0.0);
  }

  Future<void> _addWater() async {
    // Mevcut değerleri sakla
    final oldProgress = _progress;
    final newIntake = _currentIntake + HydrationService.waterIncrement;
    final newProgress = newIntake / _dailyGoal;
    
    // Hemen UI'da göster ve animasyonu ayarla
    setState(() {
      _currentIntake = newIntake;
      _progress = newProgress;
      
      // Animasyonu ayarla
      _progressAnimation = Tween<double>(
        begin: oldProgress, 
        end: newProgress
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
    });
    
    // Animasyonu başlat
    _animationController.forward(from: 0.0);
    
    // Servise kaydet
    await _hydrationService.addWater(widget.userId);
    
    // Check badges after water update
    if (mounted) {
      // Lazy import to avoid circular deps
      // ignore: avoid_dynamic_calls
      await GamificationManager().checkBadges(widget.userId, context);
    }
  }

  Future<void> _removeWater() async {
    if (_currentIntake < HydrationService.waterIncrement) return;
    
    // Mevcut değerleri sakla
    final oldProgress = _progress;
    final newIntake = _currentIntake - HydrationService.waterIncrement;
    final newProgress = newIntake / _dailyGoal;
    
    // Hemen UI'da göster ve animasyonu ayarla
    setState(() {
      _currentIntake = newIntake;
      _progress = newProgress;
      
      // Animasyonu ayarla
      _progressAnimation = Tween<double>(
        begin: oldProgress, 
        end: newProgress
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
    });
    
    // Animasyonu başlat
    _animationController.forward(from: 0.0);
    
    // Servise kaydet
    await _hydrationService.removeWater(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildCompactView() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1FD9C1).withOpacity(0.1),
            const Color(0xFF5B9BCC).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop_rounded,
            color: const Color(0xFF1FD9C1),
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            '$_currentIntake / $_dailyGoal ml',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 40.w,
            height: 40.w,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _MiniCircularProgressPainter(
                    progress: _progressAnimation.value,
                    strokeWidth: 3.w,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1FD9C1)),
      );
    }

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F3A).withOpacity(0.8),
            const Color(0xFF0A0E27).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1FD9C1).withOpacity(0.1),
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
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1FD9C1), Color(0xFF5B9BCC)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1FD9C1).withOpacity(0.3),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Su Takibi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Günlük su hedefiniz',
                      style: TextStyle(color: Colors.white60, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (_dailyGoal >
                      HydrationService.baseWaterGoal +
                          HydrationService.workoutBonus)
                    Container(
                      margin: EdgeInsets.only(bottom: 4.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xFFFF6B35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 12.sp,
                            color: const Color(0xFFFF6B35),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '+${_stepService.getStepBonus()}ml',
                            style: TextStyle(
                              color: const Color(0xFFFF6B35),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_dailyGoal > HydrationService.baseWaterGoal)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 12.sp,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '+500ml',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: 200.w,
            height: 200.w,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: _progressAnimation.value,
                    strokeWidth: 16.w,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF1FD9C1), Color(0xFF5B9BCC)],
                          ).createShader(bounds),
                          child: Text(
                            '$_currentIntake',
                            style: TextStyle(
                              fontSize: 48.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          'ml',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Hedef: $_dailyGoal ml',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white54,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${(_progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: const Color(0xFF1FD9C1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 32.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.remove,
                onPressed: _currentIntake >= HydrationService.waterIncrement
                    ? _removeWater
                    : null,
                label: '-200ml',
              ),
              SizedBox(width: 24.w),
              _buildActionButton(
                icon: Icons.add,
                onPressed: _addWater,
                label: '+200ml',
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String label,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF1FD9C1), Color(0xFF5B9BCC)],
                )
              : null,
          color: !isPrimary ? Colors.white.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF1FD9C1).withOpacity(0.2),
                    blurRadius: 12.r,
                    offset: Offset(0, 6.h),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: onPressed == null
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: onPressed == null
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _CircularProgressPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1FD9C1), Color(0xFF5B9BCC)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _MiniCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _MiniCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1FD9C1), Color(0xFF5B9BCC)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
