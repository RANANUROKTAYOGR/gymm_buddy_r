import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/database/database_helper.dart';

class DetailedDashboardScreen extends StatefulWidget {
  final int userId;

  const DetailedDashboardScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<DetailedDashboardScreen> createState() =>
      _DetailedDashboardScreenState();
}

class _DetailedDashboardScreenState extends State<DetailedDashboardScreen> {
  final _dbHelper = DatabaseHelper.instance;
  bool _isLoading = true;

  List<Map<String, dynamic>> _volumeData = [];
  List<Map<String, dynamic>> _weightData = [];
  List<Map<String, dynamic>> _muscleGroupData = [];

  double _totalVolume = 0;
  double _weightChange = 0;
  int _totalWorkouts = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final volumeData = await _dbHelper.getMonthlyVolumeData(widget.userId);
      final weightData = await _dbHelper.getBodyWeightHistory(
        widget.userId,
        30,
      );
      final muscleGroupData = await _dbHelper.getMuscleGroupDistribution(
        widget.userId,
      );
      final sessions = await _dbHelper.getLastDaysActivity(widget.userId, 30);

      // Calculate stats
      double totalVolume = 0;
      for (var item in volumeData) {
        totalVolume += (item['volume'] as double);
      }

      double weightChange = 0;
      if (weightData.length >= 2) {
        final firstWeight = weightData.first['weight'] as double;
        final lastWeight = weightData.last['weight'] as double;
        weightChange = lastWeight - firstWeight;
      }

      setState(() {
        _volumeData = volumeData;
        _weightData = weightData;
        _muscleGroupData = muscleGroupData;
        _totalVolume = totalVolume;
        _weightChange = weightChange;
        _totalWorkouts = sessions.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Veri yüklenirken hata: $e')));
      }
    }
  }

  @override
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
                  colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
                ),
              )
            : BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00FFA3)),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  color: const Color(0xFF00FFA3),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        _buildStatsCards(),
                        _buildVolumeChart(),
                        _buildWeightChart(),
                        _buildMuscleGroupChart(),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white60 : Colors.black54;

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.all(12.w),
                child: Icon(
                  Icons.analytics,
                  color: const Color(0xFF0A0E27),
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İlerleme Panosu',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Son 30 günlük performansınız',
                      style: TextStyle(color: subTextColor, fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Toplam Hacim',
              '${(_totalVolume / 1000).toStringAsFixed(1)}K kg',
              Icons.fitness_center,
              [const Color(0xFF00FFA3), const Color(0xFF00D4FF)],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              'Kilo Değişimi',
              '${_weightChange >= 0 ? '+' : ''}${_weightChange.toStringAsFixed(1)} kg',
              _weightChange >= 0 ? Icons.trending_up : Icons.trending_down,
              _weightChange >= 0
                  ? [const Color(0xFF00FFA3), const Color(0xFF00D4FF)]
                  : [const Color(0xFFFF6B9D), const Color(0xFFC86DD7)],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              'Antrenman',
              '$_totalWorkouts',
              Icons.calendar_today,
              [const Color(0xFFFF6B9D), const Color(0xFFC86DD7)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> gradient,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withAlpha((0.3 * 255).toInt()),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.white70, fontSize: 11.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeChart() {
    if (_volumeData.isEmpty) {
      return _buildEmptyChart('Hacim verisi bulunamadı');
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white60 : Colors.black54;
    final gridColor = isDarkMode ? Colors.white.withAlpha((0.1 * 255).toInt()) : Colors.black.withAlpha((0.1 * 255).toInt());

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: isDarkMode 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withAlpha((0.1 * 255).toInt()),
                  Colors.white.withAlpha((0.05 * 255).toInt()),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
              ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDarkMode 
              ? Colors.white.withAlpha((0.2 * 255).toInt()) 
              : Colors.grey.shade300, 
            width: 1
          ),
          boxShadow: isDarkMode ? [] : [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).toInt()),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FFA3).withAlpha((0.2 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.show_chart,
                    color: const Color(0xFF00FFA3),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ağırlık Hacmi Trendi',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Günlük toplam hacim (kg)',
                        style: TextStyle(color: subTextColor, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            SizedBox(
              height: 220.h,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: gridColor,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30.h,
                        interval: (_volumeData.length / 5).ceil().toDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _volumeData.length) {
                            final date = DateTime.parse(
                              _volumeData[index]['date'],
                            );
                            return Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 10.sp,
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
                        reservedSize: 45.w,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}K',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 10.sp,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (_volumeData.length - 1).toDouble(),
                  minY: 0,
                  maxY: _getMaxVolume() * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _volumeData.asMap().entries.map((e) {
                        return FlSpot(
                          e.key.toDouble(),
                          e.value['volume'] as double,
                        );
                      }).toList(),
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4.r,
                            color: isDarkMode ? Colors.white : const Color(0xFF0A0E27),
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF00FFA3),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00FFA3).withAlpha((0.3 * 255).toInt()),
                            const Color(0xFF00D4FF).withAlpha((0.1 * 255).toInt()),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                      tooltipRoundedRadius: 12.r,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = DateTime.parse(
                            _volumeData[spot.x.toInt()]['date'],
                          );
                          return LineTooltipItem(
                            '${date.day}/${date.month}\n${spot.y.toStringAsFixed(0)} kg',
                            TextStyle(
                              color: const Color(0xFF00FFA3),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    if (_weightData.isEmpty) {
      return _buildEmptyChart('Kilo ölçümü bulunamadı');
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white60 : Colors.black54;
    final gridColor = isDarkMode ? Colors.white.withAlpha((0.1 * 255).toInt()) : Colors.black.withAlpha((0.1 * 255).toInt());

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: isDarkMode 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withAlpha((0.1 * 255).toInt()),
                  Colors.white.withAlpha((0.05 * 255).toInt()),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
              ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
             color: isDarkMode 
              ? Colors.white.withAlpha((0.2 * 255).toInt()) 
              : Colors.grey.shade300, 
            width: 1
          ),
          boxShadow: isDarkMode ? [] : [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).toInt()),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B9D).withAlpha((0.2 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.monitor_weight,
                    color: const Color(0xFFFF6B9D),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vücut Ağırlığı Değişimi',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ölçüm geçmişi (kg)',
                        style: TextStyle(color: subTextColor, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            SizedBox(
              height: 220.h,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxWeight() * 1.1,
                  minY: _getMinWeight() * 0.95,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: isDarkMode ? const Color(0xFF1A1F3A) : Colors.white,
                      tooltipRoundedRadius: 12.r,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date =
                            _weightData[groupIndex]['date'] as DateTime;
                        return BarTooltipItem(
                          '${date.day}/${date.month}\n${rod.toY.toStringAsFixed(1)} kg',
                          const TextStyle(
                            color: Color(0xFFFF6B9D),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30.h,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _weightData.length) {
                            final date = _weightData[index]['date'] as DateTime;
                            return Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 10.sp,
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
                        reservedSize: 40.w,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 10.sp,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: gridColor,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: _weightData.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value['weight'] as double,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 16.w,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(6.r),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleGroupChart() {
    if (_muscleGroupData.isEmpty) {
      return _buildEmptyChart('Kas grubu verisi bulunamadı');
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white60 : Colors.black54;

    final total = _muscleGroupData.fold(
      0,
      (sum, item) => sum + (item['count'] as int),
    );
    final colors = [
      const Color(0xFF00FFA3),
      const Color(0xFF00D4FF),
      const Color(0xFFFF6B9D),
      const Color(0xFFC86DD7),
      const Color(0xFFFFAB40),
      const Color(0xFF536DFE),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: isDarkMode 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withAlpha((0.1 * 255).toInt()),
                  Colors.white.withAlpha((0.05 * 255).toInt()),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
              ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDarkMode 
              ? Colors.white.withAlpha((0.2 * 255).toInt()) 
              : Colors.grey.shade300, 
            width: 1
          ),
          boxShadow: isDarkMode ? [] : [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).toInt()),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withAlpha((0.2 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.pie_chart,
                    color: const Color(0xFF00D4FF),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kas Grubu Dağılımı',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'En çok çalışılan kaslar',
                        style: TextStyle(color: subTextColor, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                // Pie Chart
                SizedBox(
                  height: 180.h,
                  width: 180.h,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50.r,
                      sections: _muscleGroupData.asMap().entries.map((e) {
                        final index = e.key;
                        final data = e.value;
                        final count = data['count'] as int;
                        final percentage = (count / total * 100);

                        return PieChartSectionData(
                          color: colors[index % colors.length],
                          value: count.toDouble(),
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: 50.r,
                          titleStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          // Optional: Handle touch events
                        },
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 20.w),

                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _muscleGroupData.asMap().entries.map((e) {
                      final index = e.key;
                      final data = e.value;
                      final muscleGroup = data['muscleGroup'] as String;
                      final count = data['count'] as int;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Row(
                          children: [
                            Container(
                              width: 16.w,
                              height: 16.w,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                muscleGroup,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '$count',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Container(
        padding: EdgeInsets.all(40.w),
        decoration: BoxDecoration(
          gradient: isDarkMode 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withAlpha((0.05 * 255).toInt()),
                  Colors.white.withOpacity(0.02),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
              ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDarkMode 
              ? Colors.white.withAlpha((0.1 * 255).toInt()) 
              : Colors.grey.shade300, 
            width: 1
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.insert_chart_outlined,
                size: 48.sp,
                color: isDarkMode ? Colors.white.withAlpha((0.3 * 255).toInt()) : Colors.black26,
              ),
              SizedBox(height: 12.h),
              Text(
                message,
                style: TextStyle(
                  color: isDarkMode ? Colors.white.withAlpha((0.5 * 255).toInt()) : Colors.black54,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getMaxVolume() {
    if (_volumeData.isEmpty) return 5000;
    return _volumeData
        .map((e) => e['volume'] as double)
        .reduce((a, b) => a > b ? a : b);
  }

  double _getMaxWeight() {
    if (_weightData.isEmpty) return 100;
    return _weightData
        .map((e) => e['weight'] as double)
        .reduce((a, b) => a > b ? a : b);
  }

  double _getMinWeight() {
    if (_weightData.isEmpty) return 50;
    return _weightData
        .map((e) => e['weight'] as double)
        .reduce((a, b) => a < b ? a : b);
  }
}
