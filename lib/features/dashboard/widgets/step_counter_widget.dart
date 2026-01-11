import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/step_counter_service.dart';

class StepCounterWidget extends StatefulWidget {
  const StepCounterWidget({super.key});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget>
    with SingleTickerProviderStateMixin {
  final StepCounterService _stepService = StepCounterService();
  int _steps = 0;
  int _stepBonus = 0;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initStepCounter();
  }

  Future<void> _initStepCounter() async {
    await _stepService.initStepCounter();

    // Adım stream'ini dinle
    _stepService.stepsStream.listen((steps) {
      if (mounted) {
        setState(() {
          final oldSteps = _steps;
          _steps = steps;
          _stepBonus = _stepService.getStepBonus();

          // Her 10000 adımda animasyon oynat
          if (oldSteps ~/ 10000 != steps ~/ 10000) {
            _animationController.forward().then((_) {
              _animationController.reverse();
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_steps % 10000) / 10000.0;
    final completedTenThousands = _steps ~/ 10000;

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
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.3),
                            blurRadius: 12.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_walk_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adım Sayacı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Günlük adım hedefi',
                      style: TextStyle(color: Colors.white60, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              if (_stepBonus > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFF00D4FF),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.water_drop,
                        size: 12.sp,
                        color: const Color(0xFF00D4FF),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '+${_stepBonus}ml',
                        style: TextStyle(
                          color: const Color(0xFF00D4FF),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: 180.w,
            height: 180.w,
            child: CustomPaint(
              painter: _StepProgressPainter(
                progress: progress,
                completedThousands: completedTenThousands,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                      ).createShader(bounds),
                      child: Text(
                        '$_steps',
                        style: TextStyle(
                          fontSize: 42.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      'adım',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${(_steps % 10000)} / 10000',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white54,
                      ),
                    ),
                    if (completedTenThousands > 0) ...[
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.military_tech_rounded,
                              size: 14.sp,
                              color: const Color(0xFFFF6B35),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${completedTenThousands}K Tamamlandı',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: const Color(0xFFFF6B35),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white54,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    'Her 1000 adımda su hedefinize +100ml eklenir',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgressPainter extends CustomPainter {
  final double progress;
  final int completedThousands;

  _StepProgressPainter({
    required this.progress,
    required this.completedThousands,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16.w) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.w
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.w
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Completed thousands indicators
    if (completedThousands > 0) {
      final dotPaint = Paint()
        ..color = const Color(0xFFFF6B35)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < completedThousands && i < 10; i++) {
        final angle = -math.pi / 2 + (2 * math.pi * i / 10);
        final dotX = center.dx + (radius + 8.w) * math.cos(angle);
        final dotY = center.dy + (radius + 8.w) * math.sin(angle);
        canvas.drawCircle(Offset(dotX, dotY), 3.w, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StepProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.completedThousands != completedThousands;
  }
}
