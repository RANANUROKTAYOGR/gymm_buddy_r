import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/database/database_helper.dart';
import '../../data/models.dart';
import '../workout/workout_session_screen.dart';
import '../workout/workout_detail_screen.dart';
import 'widgets/step_counter_widget.dart';
import 'report_screen.dart';

class ActivityDashboardScreen extends StatefulWidget {
  const ActivityDashboardScreen({super.key, required this.userId});

  final int userId;

  @override
  State<ActivityDashboardScreen> createState() =>
      _ActivityDashboardScreenState();
}

class _ActivityDashboardScreenState extends State<ActivityDashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late Future<List<WorkoutSession>> _recentSessions;
  int _weeklyWorkouts = 0;

  @override
  void initState() {
    super.initState();
    _recentSessions = _db.getWorkoutSessionsByUser(widget.userId, 10);
    _loadWeeklyStats();
  }

  Future<void> _loadWeeklyStats() async {
    final weeklyData = await _db.getLastDaysActivity(widget.userId, 7);
    setState(() {
      _weeklyWorkouts = weeklyData.length;
    });
  }

  void _refreshData() {
    setState(() {
      _recentSessions = _db.getWorkoutSessionsByUser(widget.userId, 10);
      _loadWeeklyStats();
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
                  colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF0A0E27)],
                ),
              )
            : BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                            ).createShader(bounds),
                            child: Text(
                              'Aktivite Panosu',
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReportScreen(userId: widget.userId),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1FD9C1), Color(0xFF5B9BCC)],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1FD9C1).withOpacity(0.3),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.assessment_rounded,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          'Son antrenmanlarınız',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 14.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '$_weeklyWorkouts Bu Hafta',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white,
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
              ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF00FFA3),
                  onRefresh: () async {
                    _refreshData();
                  },
                  child: FutureBuilder<List<WorkoutSession>>(
                    future: _recentSessions,
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

                      final sessions = snapshot.data ?? [];

                      if (sessions.isEmpty) {
                        return ListView(
                          padding: EdgeInsets.all(20.w),
                          children: [
                            const StepCounterWidget(),
                            SizedBox(height: 40.h),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(30.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(
                                      (0.1 * 255).toInt(),
                                    ),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Icon(
                                    Icons.fitness_center_outlined,
                                    size: 64.sp,
                                    color: Colors.white38,
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  'Henüz antrenman yok',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                    fontSize: 18.sp,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  'Yeni bir antrenman başlat!',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white54 : Colors.black54,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return ListView(
                        padding: EdgeInsets.all(20.w),
                        children: [
                          // Step Counter Widget
                          const StepCounterWidget(),
                          SizedBox(height: 20.h),
                          // Weekly Activity Chart
                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1A1F3A).withOpacity(0.8),
                                  const Color(0xFF0A0E27).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: Colors.white.withAlpha(
                                  (0.1 * 255).toInt(),
                                ),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10.w),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF00FFA3),
                                            Color(0xFF00D4FF),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Icon(
                                        Icons.show_chart_rounded,
                                        color: Colors.white,
                                        size: 20.sp,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'Son 7 Gün Aktivitesi',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _db.getLastDaysActivityChart(
                                    widget.userId,
                                    7,
                                  ),
                                  builder: (context, chartSnapshot) {
                                    if (chartSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return SizedBox(
                                        height: 200.h,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF00FFA3),
                                          ),
                                        ),
                                      );
                                    }

                                    final chartData = chartSnapshot.data ?? [];

                                    return SizedBox(
                                      height: 200.h,
                                      child: BarChart(
                                        BarChartData(
                                          alignment:
                                              BarChartAlignment.spaceAround,
                                          maxY: (chartData.isNotEmpty
                                              ? (chartData
                                                        .map(
                                                          (e) =>
                                                              (e['count']
                                                                      as int)
                                                                  .toDouble(),
                                                        )
                                                        .reduce(
                                                          (a, b) =>
                                                              a > b ? a : b,
                                                        ) +
                                                    2)
                                              : 5),
                                          barTouchData: BarTouchData(
                                            enabled: true,
                                            touchTooltipData: BarTouchTooltipData(
                                              tooltipBgColor: const Color(
                                                0xFF1A1F3A,
                                              ),
                                              tooltipRoundedRadius: 10.r,
                                              getTooltipItem:
                                                  (
                                                    group,
                                                    groupIndex,
                                                    rod,
                                                    rodIndex,
                                                  ) {
                                                    return BarTooltipItem(
                                                      '${rod.toY.toInt()} antrenman',
                                                      TextStyle(
                                                        color: const Color(
                                                          0xFF00FFA3,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                            fontSize: 12.sp,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                          gridData: FlGridData(show: false),
                                          borderData: FlBorderData(show: false),
                                          titlesData: FlTitlesData(
                                            show: true,
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (value, meta) {
                                                  final index = value.toInt();
                                                  if (index >= 0 &&
                                                      index <
                                                          chartData.length) {
                                                    final day =
                                                        chartData[index]['day'];
                                                    return Padding(
                                                      padding:
                                                          EdgeInsets.only(
                                                            top: 8.h,
                                                          ),
                                                      child: Text(
                                                        day,
                                                        style: TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 12.sp,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  return const SizedBox();
                                                },
                                              ),
                                            ),
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (value, meta) {
                                                  return Text(
                                                    '${value.toInt()}',
                                                    style: TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 12.sp,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          barGroups: chartData.asMap().entries.map((
                                            e,
                                          ) {
                                            final index = e.key;
                                            final data = e.value;
                                            final count = (data['count'] as int)
                                                .toDouble();

                                            return BarChartGroupData(
                                              x: index,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: count,
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xFF00FFA3),
                                                          Color(0xFF00D4FF),
                                                        ],
                                                        begin: Alignment
                                                            .bottomCenter,
                                                        end:
                                                            Alignment.topCenter,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                        top: Radius.circular(8.r),
                                                      ),
                                                  width: 20.w,
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Padding(
                            padding: EdgeInsets.only(left: 4.w, bottom: 16.h),
                            child: Text(
                              'Son Antrenmanlar',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              return _SessionCard(session: session);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'workoutFAB',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutSessionScreen(userId: widget.userId),
            ),
          );

          // Antrenman kaydedildiyse listeyi yenile
          if (result == true) {
            _refreshData();
          }
        },
        backgroundColor: const Color(0xFF00FFA3),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Antrenman'),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}';
    final timeStr =
        '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailScreen(session: session),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1F3A).withAlpha((0.7 * 255).toInt()),
              const Color(0xFF1A1F3A).withAlpha((0.5 * 255).toInt()),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Colors.white.withAlpha((0.1 * 255).toInt()),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                ),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Icon(
                Icons.fitness_center_rounded,
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
                    session.sessionType ?? 'Antrenman',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14.sp,
                        color: Colors.white.withAlpha((0.5 * 255).toInt()),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withAlpha((0.5 * 255).toInt()),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.access_time_rounded,
                        size: 14.sp,
                        color: Colors.white.withAlpha((0.5 * 255).toInt()),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withAlpha((0.5 * 255).toInt()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withAlpha((0.3 * 255).toInt()),
            ),
          ],
        ),
      ),
    );
  }
}
