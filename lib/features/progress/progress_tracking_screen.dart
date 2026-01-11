import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/body_measurements.dart';
import '../../utils/error_handler.dart';
import '../../utils/permission_helper.dart';

class ProgressTrackingScreen extends StatefulWidget {
  final int userId;

  const ProgressTrackingScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dbHelper = DatabaseHelper.instance;
  List<BodyMeasurements> _measurements = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadMeasurements();
  }

  void _handleTabSelection() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  /// Kullanıcının vücut ölçümlerini veritabanından yükler
  /// Try-catch ile veritabanı hatalarını yakalar
  Future<void> _loadMeasurements() async {
    try {
      setState(() => _isLoading = true);

      // Veritabanından ölçümleri getir
      final measurements = await _dbHelper.getBodyMeasurementsByUser(
        widget.userId,
      );

      // Başarılı - state'i güncelle
      if (mounted) {
        setState(() {
          _measurements = measurements;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Hata durumunda loading'i kapat ve kullanıcıya bildir
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.handleDatabaseError(context, e);
      }
    }
  }

  /// Ölçüm silme işlemi
  Future<void> _deleteMeasurement(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ölçümü Sil'),
        content: const Text('Bu ölçümü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteBodyMeasurement(id);

        // Önceki ölçümün fotoğrafı varsa silinebilir (opsiyonel, şu an sadece veritabanından siliyor)
        // Eğer dosyayı da silmek isterseniz burada measurement.photoPath kontrolü yapılabilir

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ölçüm silindi')));
          _loadMeasurements();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  /// Kamera ekranına yönlendirir
  /// Önce izin kontrolü yapar, sonra kamera listesini alır
  void _navigateToCamera() async {
    try {
      // Adım 1: Kamera iznini kontrol et ve gerekirse iste
      final hasPermission = await PermissionHelper.requestCameraPermission(
        context,
      );

      if (!hasPermission) {
        // İzin verilmedi - kullanıcıya bilgi ver
        if (mounted) {
          ErrorHandler.showError(
            context,
            'İzin reddedildi',
            customMessage: 'Kamera izni olmadan fotoğraf çekilemez.',
          );
        }
        return;
      }

      // Adım 2: Kullanılabilir kameraları listele
      final cameras = await availableCameras();

      // Kamera bulunamadı kontrolü
      if (cameras.isEmpty) {
        if (mounted) {
          ErrorHandler.showError(
            context,
            'Kamera yok',
            customMessage: 'Cihazınızda kullanılabilir kamera bulunamadı.',
          );
        }
        return;
      }

      // Adım 3: Kamera ekranına git
      if (mounted) {
        final result = await Navigator.of(context).push<bool>(
          PageRouteBuilder(
            fullscreenDialog: true,
            pageBuilder: (context, animation, secondaryAnimation) =>
                CameraCapturePage(camera: cameras.first, userId: widget.userId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );

        // Fotoğraf başarıyla kaydedildiyse ölçümleri yenile
        if (result == true) {
          await _loadMeasurements();
        }
      }
    } catch (e) {
      // Beklenmeyen kamera hatalarını yakala ve kullanıcıya bildir
      if (mounted) {
        ErrorHandler.handleCameraError(context, e);
      }
    }
  }

  /// Ölçüm ekleme/düzenleme dialog penceresi
  void _showAddMeasurementDialog({
    BodyMeasurements? existingMeasurement,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMeasurementSheet(
        userId: widget.userId,
        existingMeasurement: existingMeasurement,
      ),
    );

    if (result == true) {
      await _loadMeasurements();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gelişim Takibi'),
        backgroundColor: const Color(0xFF1FD9C1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMeasurementDialog(),
              backgroundColor: const Color(0xFF1FD9C1),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Ölçüm Ekle',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF1FD9C1),
                  borderRadius: BorderRadius.circular(16),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                tabs: const [
                  Tab(text: 'Fotoğraflar'),
                  Tab(text: 'Ölçümler'),
                ],
              ),
            ),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Fotoğraflar Tab'ı
                  _buildPhotosTab(),
                  // Ölçümler Tab'ı
                  _buildMeasurementsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fotoğraflar Tab'ının UI'ı
  Widget _buildPhotosTab() {
    // Fotoğrafı olan ölçümleri filtrele
    final photos = _measurements
        .where((m) => m.photoPath != null && File(m.photoPath!).existsSync())
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fotoğraflarla ilerlemenizi kaydedin',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToCamera,
              icon: Icon(Icons.camera_alt, size: 24.w),
              label: Text('Fotoğraf Çek', style: TextStyle(fontSize: 16.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1FD9C1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

          if (photos.isNotEmpty) ...[
            SizedBox(height: 24.h),
            // Karşılaştırma (Eğer en az 2 fotoğraf varsa)
            if (photos.length >= 2) ...[
              Text(
                'Karşılaştırma',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              _buildComparisonView(),
              SizedBox(height: 24.h),
            ],

            // Galeri Grid
            Text(
              'Galeri',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.7,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return _buildProgressCard(photos[index]);
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Grafik widget'ı
  Widget _buildProgressChart() {
    if (_measurements.isEmpty) return const SizedBox.shrink();

    // Verileri tarihe göre sırala (eskiden yeniye)
    final sortedData = List<BodyMeasurements>.from(_measurements)
      ..sort((a, b) => a.measurementDate.compareTo(b.measurementDate));

    // Noktaları oluştur
    final spots = <FlSpot>[];
    double minWeight = double.infinity;
    double maxWeight = double.negativeInfinity;

    for (int i = 0; i < sortedData.length; i++) {
      final m = sortedData[i];
      if (m.weight != null && m.weight! > 0) {
        spots.add(FlSpot(i.toDouble(), m.weight!));
        if (m.weight! < minWeight) minWeight = m.weight!;
        if (m.weight! > maxWeight) maxWeight = m.weight!;
      }
    }

    if (spots.length < 2) return const SizedBox.shrink();

    // Y ekseni aralığını ayarla (biraz boşluk bırak)
    final minY = (minWeight - 5).clamp(0.0, double.infinity);
    final maxY = maxWeight + 5;

    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(20.w),
      height: 250.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.06 * 255).toInt()),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.withAlpha((0.2 * 255).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kilo Değişimi',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedData.length) {
                          // Sadece başı, ortayı ve sonu göster
                          if (index == 0 ||
                              index == sortedData.length - 1 ||
                              index == (sortedData.length / 2).round()) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat(
                                  'd MMM',
                                  'tr',
                                ).format(sortedData[index].measurementDate),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sortedData.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF1FD9C1),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1FD9C1).withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} kg',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ölçümler Tab'ının UI'ı
  Widget _buildMeasurementsTab() {
    if (_measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.straighten, size: 80.w, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'Henüz ölçüm yok',
              style: TextStyle(color: Colors.grey[700], fontSize: 18.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              'Vücut ölçümlerinizi kaydetmeye başlayın',
              style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
            ),
          ],
        ),
      );
    }

    // En yeni ölçüm en üstte görünsün
    final sorted = List<BodyMeasurements>.from(_measurements)
      ..sort((a, b) => b.measurementDate.compareTo(a.measurementDate));

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: sorted.length + 1, // +1 for chart
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildProgressChart();
        }
        final measurementIndex = index - 1;
        final current = sorted[measurementIndex];
        final previous = measurementIndex < sorted.length - 1
            ? sorted[measurementIndex + 1]
            : null;

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildMeasurementCard(current, previous),
        );
      },
    );
  }

  Widget _buildMeasurementCard(
    BodyMeasurements current,
    BodyMeasurements? previous,
  ) {
    final dateText = DateFormat(
      'dd MMM yyyy',
      'tr',
    ).format(current.measurementDate);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.06 * 255).toInt()),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
        border: Border.all(color: Colors.grey.withAlpha((0.2 * 255).toInt())),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık (Tarih)
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Color(0xFF1FD9C1),
                  size: 18.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (current.photoPath != null &&
                    File(current.photoPath!).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.file(
                      File(current.photoPath!),
                      height: 40.h,
                      width: 40.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () =>
                      _showAddMeasurementDialog(existingMeasurement: current),
                  tooltip: 'Düzenle',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => current.id != null
                      ? _deleteMeasurement(current.id!)
                      : null,
                  tooltip: 'Sil',
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Öne çıkan metrikler (Kilo, Yağ, BMI)
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _metricChip(
                  label: 'Kilo',
                  value: current.weight,
                  unit: 'kg',
                  prev: previous?.weight,
                  icon: Icons.monitor_weight,
                ),
                _metricChip(
                  label: 'Yağ',
                  value: current.bodyFatPercentage,
                  unit: '%',
                  prev: previous?.bodyFatPercentage,
                  icon: Icons.percent,
                ),
                _metricChip(
                  label: 'BMI',
                  value: current.bmi,
                  unit: '',
                  prev: previous?.bmi,
                  icon: Icons.analytics,
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Çevre ölçümleri (Göğüs, Bel, Kalça)
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _metricChip(
                  label: 'Göğüs',
                  value: current.chest,
                  unit: 'cm',
                  prev: previous?.chest,
                  icon: Icons.straighten,
                ),
                _metricChip(
                  label: 'Bel',
                  value: current.waist,
                  unit: 'cm',
                  prev: previous?.waist,
                  icon: Icons.straighten,
                ),
                _metricChip(
                  label: 'Kalça',
                  value: current.hips,
                  unit: 'cm',
                  prev: previous?.hips,
                  icon: Icons.straighten,
                ),
              ],
            ),

            if (current.notes != null && current.notes!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, color: Colors.black54, size: 18.w),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        current.notes!,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricChip({
    required String label,
    required double? value,
    required String unit,
    required double? prev,
    required IconData icon,
  }) {
    final hasValue = value != null;
    final delta = (hasValue && prev != null) ? (value! - prev) : null;
    final deltaText = delta == null
        ? null
        : (delta > 0
              ? '+${delta.toStringAsFixed(1)}'
              : delta.toStringAsFixed(1));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withAlpha((0.2 * 255).toInt())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.w, color: const Color(0xFF1FD9C1)),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(fontSize: 13.sp, color: Colors.black54),
          ),
          SizedBox(width: 6.w),
          Text(
            hasValue ? '${value!.toStringAsFixed(1)} $unit' : '-',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
          if (deltaText != null) ...[
            SizedBox(width: 6.w),
            Icon(
              (delta! >= 0) ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14.w,
              color: Colors.black45,
            ),
            SizedBox(width: 2.w),
            Text(
              deltaText!,
              style: TextStyle(fontSize: 12.sp, color: Colors.black45),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(BodyMeasurements measurement) {
    final dateFormat = DateFormat('dd MMM yyyy', 'tr');

    return GestureDetector(
      onTap: () => _showDetailDialog(measurement),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha((0.1 * 255).toInt()),
              Colors.white.withAlpha((0.05 * 255).toInt()),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Colors.white.withAlpha((0.2 * 255).toInt()),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                child:
                    measurement.photoPath != null &&
                        File(measurement.photoPath!).existsSync()
                    ? Image.file(
                        File(measurement.photoPath!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.white.withAlpha((0.05 * 255).toInt()),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40.w,
                            color: Colors.white24,
                          ),
                        ),
                      ),
              ),
            ),

            // Info
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(measurement.measurementDate),
                    style: TextStyle(
                      color: Color(0xFF00FFA3),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  if (measurement.weight != null)
                    Row(
                      children: [
                        Icon(
                          Icons.monitor_weight,
                          size: 14.w,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${measurement.weight!.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  if (measurement.bodyFatPercentage != null)
                    Row(
                      children: [
                        Icon(Icons.percent, size: 14.w, color: Colors.white70),
                        SizedBox(width: 4.w),
                        Text(
                          '${measurement.bodyFatPercentage!.toStringAsFixed(1)}% Yağ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonView() {
    if (_measurements.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 80.w,
              color: Colors.white.withAlpha((0.3 * 255).toInt()),
            ),
            SizedBox(height: 16.h),
            Text(
              'Karşılaştırma için en az 2 fotoğraf gerekli',
              style: TextStyle(
                color: Colors.white.withAlpha((0.5 * 255).toInt()),
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      );
    }

    // Show first and last measurement side by side
    final first = _measurements.last;
    final last = _measurements.first;
    final dateFormat = DateFormat('dd MMM yyyy', 'tr');

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Side by side comparison
          Row(
            children: [
              Expanded(
                child: _buildComparisonPhoto(first, 'Başlangıç', dateFormat),
              ),
              SizedBox(width: 16.w),
              Expanded(child: _buildComparisonPhoto(last, 'Son', dateFormat)),
            ],
          ),

          SizedBox(height: 30.h),

          // Stats comparison
          _buildStatsComparison(first, last),
        ],
      ),
    );
  }

  Widget _buildComparisonPhoto(
    BodyMeasurements measurement,
    String label,
    DateFormat dateFormat,
  ) {
    return Column(
      children: [
        Container(
          height: 300.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha((0.1 * 255).toInt()),
                Colors.white.withAlpha((0.05 * 255).toInt()),
              ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child:
                measurement.photoPath != null &&
                    File(measurement.photoPath!).existsSync()
                ? Image.file(File(measurement.photoPath!), fit: BoxFit.cover)
                : Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 60.w,
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                    ),
                  ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF00FFA3),
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          dateFormat.format(measurement.measurementDate),
          style: TextStyle(color: Colors.white60, fontSize: 12.sp),
        ),
      ],
    );
  }

  Widget _buildStatsComparison(BodyMeasurements first, BodyMeasurements last) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha((0.1 * 255).toInt()),
            Colors.white.withAlpha((0.05 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withAlpha((0.2 * 255).toInt()),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İlerleme İstatistikleri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20.h),
          if (first.weight != null && last.weight != null)
            _buildStatRow(
              'Kilo',
              first.weight!,
              last.weight!,
              'kg',
              Icons.monitor_weight,
            ),
          if (first.bodyFatPercentage != null && last.bodyFatPercentage != null)
            _buildStatRow(
              'Yağ Oranı',
              first.bodyFatPercentage!,
              last.bodyFatPercentage!,
              '%',
              Icons.percent,
            ),
          if (first.muscleMass != null && last.muscleMass != null)
            _buildStatRow(
              'Kas Kütlesi',
              first.muscleMass!,
              last.muscleMass!,
              'kg',
              Icons.fitness_center,
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    double firstValue,
    double lastValue,
    String unit,
    IconData icon,
  ) {
    final difference = lastValue - firstValue;
    final isPositive = difference >= 0;
    final color = label == 'Yağ Oranı'
        ? (isPositive ? Colors.red : const Color(0xFF00FFA3))
        : (isPositive ? const Color(0xFF00FFA3) : Colors.red);

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.w, color: Colors.white70),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${firstValue.toStringAsFixed(1)} $unit',
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
              Icon(
                Icons.arrow_forward,
                color: Colors.white.withAlpha((0.3 * 255).toInt()),
                size: 20.w,
              ),
              Text(
                '${lastValue.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16.w,
                color: color,
              ),
              SizedBox(width: 4.w),
              Text(
                '${difference.abs().toStringAsFixed(1)} $unit',
                style: TextStyle(
                  color: color,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BodyMeasurements measurement) {
    final dateFormat = DateFormat('dd MMMM yyyy HH:mm', 'tr');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: 400.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1F3A), Color(0xFF0A0E27)],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              width: 1,
            ),
          ),
          child: SingleChildScrollView(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Photo
                  if (measurement.photoPath != null &&
                      File(measurement.photoPath!).existsSync())
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24.r),
                      ),
                      child: Image.file(
                        File(measurement.photoPath!),
                        height: 300.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Color(0xFF00FFA3),
                              size: 20.w,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              dateFormat.format(measurement.measurementDate),
                              style: TextStyle(
                                color: Color(0xFF00FFA3),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        if (measurement.weight != null)
                          _buildDetailRow(
                            'Kilo',
                            '${measurement.weight!.toStringAsFixed(1)} kg',
                            Icons.monitor_weight,
                          ),
                        if (measurement.bodyFatPercentage != null)
                          _buildDetailRow(
                            'Yağ Oranı',
                            '${measurement.bodyFatPercentage!.toStringAsFixed(1)}%',
                            Icons.percent,
                          ),
                        if (measurement.muscleMass != null)
                          _buildDetailRow(
                            'Kas Kütlesi',
                            '${measurement.muscleMass!.toStringAsFixed(1)} kg',
                            Icons.fitness_center,
                          ),
                        if (measurement.bmi != null)
                          _buildDetailRow(
                            'BMI',
                            measurement.bmi!.toStringAsFixed(1),
                            Icons.analytics,
                          ),
                        if (measurement.chest != null)
                          _buildDetailRow(
                            'Göğüs',
                            '${measurement.chest!.toStringAsFixed(1)} cm',
                            Icons.straighten,
                          ),
                        if (measurement.waist != null)
                          _buildDetailRow(
                            'Bel',
                            '${measurement.waist!.toStringAsFixed(1)} cm',
                            Icons.straighten,
                          ),
                        if (measurement.hips != null)
                          _buildDetailRow(
                            'Kalça',
                            '${measurement.hips!.toStringAsFixed(1)} cm',
                            Icons.straighten,
                          ),

                        if (measurement.notes != null &&
                            measurement.notes!.isNotEmpty) ...[
                          SizedBox(height: 16.h),
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(
                                (0.05 * 255).toInt(),
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.note,
                                  color: Colors.white70,
                                  size: 20.w,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    measurement.notes!,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: 20.h),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context); // Dialog'u kapat
                                  if (measurement.id != null) {
                                    _deleteMeasurement(
                                      measurement.id!,
                                    ); // Silme onayını başlat
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withAlpha(
                                    (0.2 * 255).toInt(),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                ),
                                child: Text(
                                  'Sil',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00FFA3),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Text(
                                  'Kapat',
                                  style: TextStyle(
                                    color: Color(0xFF0A0E27),
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20.w),
          SizedBox(width: 12.w),
          Text(
            '$label:',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Camera Capture Page
class CameraCapturePage extends StatefulWidget {
  final CameraDescription camera;
  final int userId;

  const CameraCapturePage({
    Key? key,
    required this.camera,
    required this.userId,
  }) : super(key: key);

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    // Kamera kontrolcüsünü başlat
    _initializeCamera();
  }

  /// Kamerayı başlatır
  /// Try-catch ile başlatma hatalarını yakalar
  void _initializeCamera() {
    try {
      _controller = CameraController(
        widget.camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _initializeControllerFuture = _controller.initialize();
    } catch (e) {
      debugPrint('❌ Kamera başlatma hatası: $e');
      // Hata durumunda kullanıcıya bildir
      if (mounted) {
        ErrorHandler.handleCameraError(context, e);
      }
    }
  }

  @override
  void dispose() {
    // Kamera kontrolcüsünü temizle
    try {
      _controller.dispose();
    } catch (e) {
      debugPrint('❌ Kamera dispose hatası: $e');
    }
    super.dispose();
  }

  /// Flash modunu açıp kapatır
  Future<void> _toggleFlash() async {
    try {
      if (_isFlashOn) {
        await _controller.setFlashMode(FlashMode.off);
      } else {
        await _controller.setFlashMode(FlashMode.torch);
      }
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      // Flash hatası - kullanıcıya bildir
      debugPrint('❌ Flash toggle hatası: $e');
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: 'Flash açılamadı.');
      }
    }
  }

  /// Fotoğraf çeker ve önizleme ekranına gönderir
  Future<void> _takePicture() async {
    try {
      // Kameranın hazır olmasını bekle
      await _initializeControllerFuture;

      // Fotoğrafı çek
      final image = await _controller.takePicture();

      if (mounted) {
        // Önizleme ekranına git
        final result = await Navigator.of(context).push<bool>(
          PageRouteBuilder(
            fullscreenDialog: true,
            pageBuilder: (context, animation, secondaryAnimation) =>
                PhotoPreviewPage(imagePath: image.path, userId: widget.userId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );

        // Fotoğraf kaydedildiyse geri dön
        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      // Fotoğraf çekme hatası - kullanıcıya bildir
      debugPrint('❌ Fotoğraf çekme hatası: $e');
      if (mounted) {
        ErrorHandler.handleCameraError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Camera Preview
                Positioned.fill(child: CameraPreview(_controller)),

                // Top Controls
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((0.5 * 255).toInt()),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),

                        // Flash Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((0.5 * 255).toInt()),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isFlashOn ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                            ),
                            onPressed: _toggleFlash,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha((0.7 * 255).toInt()),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Capture Button
                        GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            width: 80.w,
                            height: 80.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4.w,
                              ),
                            ),
                            child: Container(
                              margin: EdgeInsets.all(5.w),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Grid lines (non-interactive overlay)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: GridPainter()),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FFA3)),
            );
          }
        },
      ),
    );
  }
}

// Grid Painter for camera guidelines
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha((0.3 * 255).toInt())
      ..strokeWidth = 1;

    // Vertical lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Photo Preview and Data Entry Page
class PhotoPreviewPage extends StatefulWidget {
  final String imagePath;
  final int userId;

  const PhotoPreviewPage({
    Key? key,
    required this.imagePath,
    required this.userId,
  }) : super(key: key);

  @override
  State<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _notesController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Fotoğrafı ve ölçüm verilerini kaydeder
  /// Try-catch ile dosya işlemleri ve veritabanı hatalarını yakalar
  Future<void> _saveProgress() async {
    // Form validasyonu
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Adım 1: Uygulama dizinini al
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'progress_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${appDir.path}/$fileName';

      // Adım 2: Fotoğrafı kalıcı konuma kopyala
      try {
        await File(widget.imagePath).copy(savedPath);
      } catch (e) {
        debugPrint('❌ Dosya kopyalama hatası: $e');
        throw Exception('Fotoğraf kaydedilemedi');
      }

      // Adım 3: BMI hesapla (kilo girilmişse)
      double? bmi;
      final weight = double.tryParse(_weightController.text);
      if (weight != null) {
        // Not: Gerçek uygulamada boy kullanıcı profilinden alınmalı
        // Şimdilik ortalama 170cm varsayıyoruz
        bmi = weight / (1.70 * 1.70);
      }

      // Adım 4: Ölçüm kaydı oluştur
      final measurement = BodyMeasurements(
        userId: widget.userId,
        measurementDate: DateTime.now(),
        weight: weight,
        bodyFatPercentage: double.tryParse(_bodyFatController.text),
        bmi: bmi,
        chest: double.tryParse(_chestController.text),
        waist: double.tryParse(_waistController.text),
        hips: double.tryParse(_hipsController.text),
        photoPath: savedPath,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: DateTime.now(),
      );

      // Adım 5: Veritabanına kaydet
      await _dbHelper.createBodyMeasurement(measurement);

      // Başarılı - kullanıcıya bildir ve geri dön
      if (mounted) {
        ErrorHandler.showSuccess(
          context,
          'Gelişim kaydı başarıyla kaydedildi!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Hata durumunda kullanıcıya bildir
      debugPrint('❌ Progress kaydetme hatası: $e');
      if (mounted) {
        ErrorHandler.handleDatabaseError(context, e);
      }
    } finally {
      // Loading durumunu kapat
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24.w,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        'Gelişim Kaydı',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Photo Preview
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Image.file(
                      File(widget.imagePath),
                      height: 300.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(height: 30.h),

                // Form
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ölçüm Bilgileri',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Weight
                        _buildTextField(
                          controller: _weightController,
                          label: 'Kilo (kg)',
                          icon: Icons.monitor_weight,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen kilonuzu girin';
                            }
                            final val = double.tryParse(value);
                            if (val == null) {
                              return 'Geçerli bir sayı girin';
                            }
                            if (val < 20 || val > 300) {
                              return 'Geçersiz değer (20-300)';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),

                        // Body Fat
                        _buildTextField(
                          controller: _bodyFatController,
                          label: 'Yağ Oranı (%)',
                          icon: Icons.percent,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            final val = double.tryParse(value);
                            if (val == null) return 'Sayı giriniz';
                            if (val < 2 || val > 70) return 'Geçersiz (2-70)';
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),

                        // Measurements (Chest, Waist, Hips)
                        Text(
                          'Vücut Ölçüleri (Opsiyonel)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _chestController,
                                label: 'Göğüs (cm)',
                                icon: Icons.straighten,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return null;
                                  final val = double.tryParse(value);
                                  if (val == null) return 'Sayı giriniz';
                                  if (val < 30 || val > 300) return 'Mantıksız';
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildTextField(
                                controller: _waistController,
                                label: 'Bel (cm)',
                                icon: Icons.straighten,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return null;
                                  final val = double.tryParse(value);
                                  if (val == null) return 'Sayı giriniz';
                                  if (val < 30 || val > 300) return 'Mantıksız';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _hipsController,
                                label: 'Kalça (cm)',
                                icon: Icons.straighten,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return null;
                                  final val = double.tryParse(value);
                                  if (val == null) return 'Sayı giriniz';
                                  if (val < 30 || val > 300) return 'Mantıksız';
                                  return null;
                                },
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        SizedBox(height: 16.h),

                        // Notes
                        _buildTextField(
                          controller: _notesController,
                          label: 'Notlar (Opsiyonel)',
                          icon: Icons.note,
                          maxLines: 3,
                        ),
                        SizedBox(height: 30.h),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProgress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FFA3),
                              padding: EdgeInsets.symmetric(vertical: 18.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              disabledBackgroundColor: Colors.grey,
                            ),
                            child: _isSaving
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0A0E27),
                                    ),
                                  )
                                : Text(
                                    'Kaydet',
                                    style: TextStyle(
                                      color: Color(0xFF0A0E27),
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFF00FFA3)),
        filled: true,
        fillColor: Colors.white.withAlpha((0.1 * 255).toInt()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: Colors.white.withAlpha((0.2 * 255).toInt()),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Color(0xFF00FFA3), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: validator,
    );
  }
}

class _AddMeasurementSheet extends StatefulWidget {
  final int userId;
  final BodyMeasurements? existingMeasurement;

  const _AddMeasurementSheet({
    Key? key,
    required this.userId,
    this.existingMeasurement,
  }) : super(key: key);

  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMeasurement != null) {
      final m = widget.existingMeasurement!;
      if (m.weight != null) _weightController.text = m.weight.toString();
      if (m.bodyFatPercentage != null)
        _bodyFatController.text = m.bodyFatPercentage.toString();
      if (m.chest != null) _chestController.text = m.chest.toString();
      if (m.waist != null) _waistController.text = m.waist.toString();
      if (m.hips != null) _hipsController.text = m.hips.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isUpdate = widget.existingMeasurement != null;

      final m = BodyMeasurements(
        id: isUpdate ? widget.existingMeasurement!.id : null,
        userId: widget.userId,
        measurementDate: isUpdate
            ? widget.existingMeasurement!.measurementDate
            : DateTime.now(),
        createdAt: isUpdate
            ? widget.existingMeasurement!.createdAt
            : DateTime.now(),
        weight: double.tryParse(_weightController.text) ?? 0,
        bodyFatPercentage: double.tryParse(_bodyFatController.text),
        chest: double.tryParse(_chestController.text),
        waist: double.tryParse(_waistController.text),
        hips: double.tryParse(_hipsController.text),
        photoPath: isUpdate ? widget.existingMeasurement!.photoPath : null,
        notes: isUpdate ? widget.existingMeasurement!.notes : null,
      );

      if (isUpdate) {
        await DatabaseHelper.instance.updateBodyMeasurement(m);
      } else {
        await DatabaseHelper.instance.createBodyMeasurement(m);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.existingMeasurement != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(
        16.w,
        16.h,
        16.w,
        MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isUpdate ? 'Ölçümü Düzenle' : 'Yeni Ölçüm Ekle',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _CustomTextField(
                    controller: _weightController,
                    label: 'Kilo (kg)',
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Gerekli';
                      final val = double.tryParse(v!);
                      if (val == null) return 'Sayı giriniz';
                      if (val < 20 || val > 300) return 'Geçersiz';
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _CustomTextField(
                    controller: _bodyFatController,
                    label: 'Yağ Oranı (%)',
                    icon: Icons.percent,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final val = double.tryParse(v);
                      if (val == null) return 'Sayı giriniz';
                      if (val < 2 || val > 70) return 'Geçersiz';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _CustomTextField(
              controller: _chestController,
              label: 'Göğüs Çevresi (cm)',
              icon: Icons.straighten,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final val = double.tryParse(v);
                if (val == null) return 'Sayı giriniz';
                if (val < 30 || val > 300) return 'Mantıksız değer';
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _CustomTextField(
              controller: _waistController,
              label: 'Bel Çevresi (cm)',
              icon: Icons.straighten,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final val = double.tryParse(v);
                if (val == null) return 'Sayı giriniz';
                if (val < 30 || val > 300) return 'Mantıksız değer';
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _CustomTextField(
              controller: _hipsController,
              label: 'Kalça Çevresi (cm)',
              icon: Icons.straighten,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final val = double.tryParse(v);
                if (val == null) return 'Sayı giriniz';
                if (val < 30 || val > 300) return 'Mantıksız değer';
                return null;
              },
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1FD9C1),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 24.h,
                      width: 24.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Kaydet',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 20.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF1FD9C1), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
    );
  }
}
