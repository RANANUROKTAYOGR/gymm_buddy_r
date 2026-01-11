import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/database/database_helper.dart';
import '../../data/models.dart';

class QREquipmentScannerScreen extends StatefulWidget {
  final int userId;

  const QREquipmentScannerScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<QREquipmentScannerScreen> createState() =>
      _QREquipmentScannerScreenState();
}

class _QREquipmentScannerScreenState extends State<QREquipmentScannerScreen> {
  MobileScannerController? cameraController;
  final _dbHelper = DatabaseHelper.instance;
  bool isProcessing = false;
  String? lastScannedCode;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || 
           url.contains('youtu.be') ||
           url.contains('youtube');
  }

  Future<void> _handleScannedCode(String qrCode) async {
    // Aynı kodu tekrar okumayı engelle
    if (isProcessing || lastScannedCode == qrCode) return;

    setState(() {
      isProcessing = true;
      lastScannedCode = qrCode;
    });

    print('📱 QR Kod Okundu: $qrCode');

    try {
      // Search equipment by QR code
      final equipment = await _dbHelper.getEquipmentByQRCode(qrCode);

      if (equipment != null && mounted) {
        print('✅ Ekipman bulundu: ${equipment.name}');
        
        // Get or create today's workout session
        final workoutSession = await _dbHelper.getOrCreateTodayWorkoutSession(widget.userId);
        print('📝 Antrenman seansı: ${workoutSession.id}');
        
        // Find or create exercise for this equipment
        Exercise? exercise = await _dbHelper.getExerciseByEquipmentName(equipment.name);
        
        if (exercise == null) {
          // Create a new exercise based on equipment
          exercise = await _dbHelper.createExercise(Exercise(
            name: equipment.name,
            description: equipment.description ?? 'QR kodundan eklendi',
            muscleGroup: equipment.type,
            equipment: equipment.name,
            videoUrl: equipment.videoUrl,
            createdAt: DateTime.now(),
          ));
          print('🆕 Yeni egzersiz oluşturuldu: ${exercise.name}');
        } else if (exercise.videoUrl == null && equipment.videoUrl != null) {
          // Update exercise with video URL if it doesn't have one
          final updatedExercise = exercise.copyWith(videoUrl: equipment.videoUrl);
          await _dbHelper.database.then((db) => db.update(
            'exercises',
            updatedExercise.toMap(),
            where: 'id = ?',
            whereArgs: [exercise!.id],
          ));
          exercise = updatedExercise;
          print('🔄 Egzersiz video URL güncellendi');
        }
        
        // Get the current number of exercises in this session
        final existingLogs = await _dbHelper.getExerciseLogsBySession(workoutSession.id!);
        final orderInSession = existingLogs.length + 1;
        
        // Add exercise log to workout session
        await _dbHelper.createExerciseLog(ExerciseLog(
          workoutSessionId: workoutSession.id!,
          exerciseId: exercise.id!,
          orderInSession: orderInSession,
          createdAt: DateTime.now(),
        ));
        
        print('✅ Egzersiz antrenman seansına eklendi');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${equipment.name} antrenmana eklendi!',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF00FFA3),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Antrenmanı Gör',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          );
          
          // Reset scanner after a short delay
          await Future.delayed(const Duration(seconds: 2));
          _resetScanner();
        }
      } else if (mounted) {
        print('❌ Ekipman bulunamadı, yeni ekleme öneriliyor');
        // Check if QR code is a YouTube URL
        if (_isYouTubeUrl(qrCode)) {
          print('🎥 YouTube URL tespit edildi');
          _showAddNewEquipmentWithVideoDialog(qrCode);
        } else {
          // Equipment not found - offer to add new
          _showAddNewEquipmentDialog(qrCode);
        }
      }
    } catch (e) {
      print('❌ Hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _resetScanner();
      }
    }
  }

  Future<void> _openVideo(Equipment equipment) async {
    try {
      final videoUrl = equipment.videoUrl!;
      print('🎥 Video açılıyor: $videoUrl');
      
      final Uri uri = Uri.parse(videoUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (mounted) {
          // Video başarıyla açıldı, geri dön
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${equipment.name} videosu açılıyor...',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF00FFA3),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // 1 saniye bekleyip geri dön
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        throw 'Video açılamadı';
      }
    } catch (e) {
      print('❌ Video açma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video açılamadı: ${equipment.name}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Detaylar',
              textColor: Colors.white,
              onPressed: () {
                _showEquipmentFoundDialog(equipment, equipment.qrCode ?? '');
              },
            ),
          ),
        );
        _resetScanner();
      }
    }
  }

  void _resetScanner() {
    setState(() {
      isProcessing = false;
      lastScannedCode = null;
    });
  }

  void _showEquipmentFoundDialog(Equipment equipment, String qrCode) async {
    // Get exercises for this equipment
    final exercises = await _dbHelper.getExercisesByEquipment(equipment.name);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EquipmentDetailsDialog(
        equipment: equipment,
        exercises: exercises,
        userId: widget.userId,
        onClose: () {
          Navigator.pop(context);
          _resetScanner();
        },
        onOpenVideo: equipment.videoUrl != null && equipment.videoUrl!.isNotEmpty
            ? () {
                Navigator.pop(context);
                _openVideo(equipment);
              }
            : null,
      ),
    );
  }

  void _showAddNewEquipmentDialog(String qrCode) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddEquipmentDialog(
        qrCode: qrCode,
        videoUrl: null,
        onClose: () {
          Navigator.pop(context);
          _resetScanner();
        },
        onSaved: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yeni ekipman başarıyla eklendi!'),
              backgroundColor: Color(0xFF00FFA3),
            ),
          );
          _resetScanner();
        },
      ),
    );
  }

  void _showAddNewEquipmentWithVideoDialog(String videoUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddEquipmentDialog(
        qrCode: DateTime.now().millisecondsSinceEpoch.toString(),
        videoUrl: videoUrl,
        onClose: () {
          Navigator.pop(context);
          _resetScanner();
        },
        onSaved: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yeni ekipman başarıyla eklendi!'),
              backgroundColor: Color(0xFF00FFA3),
            ),
          );
          _resetScanner();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (cameraController != null)
            MobileScanner(
              controller: cameraController!,
              onDetect: (capture) {
                if (isProcessing) return;
                
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final rawValue = barcode.rawValue;
                  if (rawValue != null && rawValue.isNotEmpty) {
                    print('🔍 Barcode tespit edildi: $rawValue');
                    _handleScannedCode(rawValue);
                    break;
                  }
                }
              },
            ),

          // Overlay
          CustomPaint(painter: ScannerOverlayPainter(), child: Container()),

          // Top Controls
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha((0.7 * 255).toInt()),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((0.7 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'QR Kod Tara',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Ekipmanın QR kodunu okutun',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Bottom instruction
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.8 * 255).toInt()),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isProcessing ? Icons.hourglass_empty : Icons.qr_code_scanner,
                              color: const Color(0xFF00FFA3),
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Flexible(
                              child: Text(
                                isProcessing 
                                    ? 'İşleniyor...' 
                                    : 'QR kodu kare içine hizalayın',
                                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        if (!isProcessing) ...[
                          SizedBox(height: 8.h),
                          Text(
                            'Video otomatik olarak açılacak',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),

          // Processing Indicator
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00FFA3)),
                    SizedBox(height: 16.h),
                    Text(
                      'QR Kod İşleniyor...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Scanner Overlay Painter
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha((0.5 * 255).toInt())
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;

    // Draw overlay with transparent center
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
          Radius.circular(20.r),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = const Color(0xFF00FFA3)
      ..strokeWidth = 4.w
      ..style = PaintingStyle.stroke;

    final bracketLength = 30.w;

    // Top-left
    canvas.drawLine(
      Offset(left, top + bracketLength),
      Offset(left, top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + bracketLength, top),
      bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(left + scanAreaSize - bracketLength, top),
      Offset(left + scanAreaSize, top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + bracketLength),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(left, top + scanAreaSize - bracketLength),
      Offset(left, top + scanAreaSize),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + bracketLength, top + scanAreaSize),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(left + scanAreaSize - bracketLength, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize - bracketLength),
      Offset(left + scanAreaSize, top + scanAreaSize),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Equipment Details Dialog
class EquipmentDetailsDialog extends StatefulWidget {
  final Equipment equipment;
  final List<Exercise> exercises;
  final int userId;
  final VoidCallback onClose;
  final VoidCallback? onOpenVideo;

  const EquipmentDetailsDialog({
    Key? key,
    required this.equipment,
    required this.exercises,
    required this.userId,
    required this.onClose,
    this.onOpenVideo,
  }) : super(key: key);

  @override
  State<EquipmentDetailsDialog> createState() => _EquipmentDetailsDialogState();
}

class _EquipmentDetailsDialogState extends State<EquipmentDetailsDialog> {
  final _dbHelper = DatabaseHelper.instance;
  Map<int, Map<String, dynamic>?> _lastSetDetails = {};
  Future<void> _launchVideoUrl() async {
    final url = widget.equipment.videoUrl;
    if (url == null || url.isEmpty) return;

    try {
      final Uri videoUri = Uri.parse(url);
      if (await canLaunchUrl(videoUri)) {
        await launchUrl(videoUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video açılamadı. URL geçersiz olabilir.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLastSetDetails();
  }

  Future<void> _loadLastSetDetails() async {
    for (final exercise in widget.exercises) {
      final details = await _dbHelper.getLastSetDetailsForExercise(
        widget.userId,
        exercise.id!,
      );
      setState(() {
        _lastSetDetails[exercise.id!] = details;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500.w, maxHeight: 700.h),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: const Color(0xFF0A0E27),
                    size: 30.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.equipment.name,
                          style: TextStyle(
                            color: const Color(0xFF0A0E27),
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.equipment.brand != null)
                          Text(
                            '${widget.equipment.brand} ${widget.equipment.model ?? ''}',
                            style: TextStyle(
                              color: const Color(
                                0xFF0A0E27,
                              ).withAlpha((0.7 * 255).toInt()),
                              fontSize: 14.sp,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF0A0E27)),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),

            // Equipment Info
            if (widget.equipment.description != null)
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.05 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          widget.equipment.description!,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Exercises List
            Expanded(
              child: widget.exercises.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 60.sp,
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Bu ekipman için kayıtlı egzersiz yok',
                            style: TextStyle(
                              color: Colors.white.withAlpha(
                                (0.5 * 255).toInt(),
                              ),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: widget.exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = widget.exercises[index];
                        final lastSet = _lastSetDetails[exercise.id!];

                        return _buildExerciseCard(exercise, lastSet);
                      },
                    ),
            ),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  // Video Button (if available)
                  if (widget.onOpenVideo != null)
                    Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onOpenVideo,
                        icon: Icon(Icons.play_circle_outline, size: 24.sp),
                        label: Text(
                          'Kullanım Videosunu İzle',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  // Start Workout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FFA3),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Antrenmana Başla',
                        style: TextStyle(
                          color: const Color(0xFF0A0E27),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, Map<String, dynamic>? lastSet) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha((0.1 * 255).toInt()),
            Colors.white.withAlpha((0.05 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withAlpha((0.2 * 255).toInt()),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Name
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFA3).withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.fitness_center,
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
                      exercise.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      exercise.muscleGroup ?? 'Genel',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Last Set Details
          if (lastSet != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.05 * 255).toInt()),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.white54, size: 16.sp),
                      SizedBox(width: 8.w),
                      const Text(
                        'Son Performansınız',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatChip(
                          Icons.monitor_weight,
                          '${(lastSet['weight'] as num?)?.toStringAsFixed(1) ?? '0'} kg',
                          'Ağırlık',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildStatChip(
                          Icons.repeat,
                          '${lastSet['reps'] ?? 0} tekrar',
                          'Tekrar',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.05 * 255).toInt()),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withAlpha((0.3 * 255).toInt()),
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Bu egzersiz için henüz kayıt yok',
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.5 * 255).toInt()),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF00FFA3).withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00FFA3), size: 18.sp),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha((0.5 * 255).toInt()),
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// Add Equipment Dialog
class AddEquipmentDialog extends StatefulWidget {
  final String qrCode;
  final String? videoUrl;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  const AddEquipmentDialog({
    Key? key,
    required this.qrCode,
    this.videoUrl,
    required this.onClose,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<AddEquipmentDialog> createState() => _AddEquipmentDialogState();
}

class _AddEquipmentDialogState extends State<AddEquipmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;

  String? _selectedType;
  bool _isSaving = false;

  final List<String> _equipmentTypes = [
    'Cardio',
    'Strength',
    'Free Weight',
    'Cable',
    'Machine',
    'Functional',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final equipment = Equipment(
        name: _nameController.text,
        type: _selectedType,
        brand: _brandController.text.isEmpty ? null : _brandController.text,
        model: _modelController.text.isEmpty ? null : _modelController.text,
        qrCode: widget.qrCode,
        videoUrl: widget.videoUrl,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      await _dbHelper.createEquipment(equipment);

      if (mounted) {
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500.w),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.white, size: 30.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yeni Ekipman Tanımla',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Bu QR kod veritabanında kayıtlı değil',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),

              // QR Code Display
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.05 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.qr_code,
                            color: const Color(0xFF00FFA3),
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'QR Kod',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                Text(
                                  widget.qrCode,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.videoUrl != null) ...[
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.video_library,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'YouTube Video Tespit Edildi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Video URL otomatik olarak eklenecek',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_circle_filled, color: Colors.white),
                              onPressed: () async {
                                try {
                                  final Uri uri = Uri.parse(widget.videoUrl!);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Video açılamadı: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Form
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Equipment Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Ekipman Adı *',
                        icon: Icons.fitness_center,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ekipman adı gerekli';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Equipment Type
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Ekipman Tipi',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.category,
                            color: Color(0xFF00FFA3),
                          ),
                          filled: true,
                          fillColor: Colors.white.withAlpha(
                            (0.1 * 255).toInt(),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: Colors.white.withAlpha(
                                (0.2 * 255).toInt(),
                              ),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: Color(0xFF00FFA3),
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownColor: const Color(0xFF1A1F3A),
                        style: const TextStyle(color: Colors.white),
                        items: _equipmentTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedType = value);
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Brand
                      _buildTextField(
                        controller: _brandController,
                        label: 'Marka',
                        icon: Icons.business,
                      ),
                      SizedBox(height: 16.h),

                      // Model
                      _buildTextField(
                        controller: _modelController,
                        label: 'Model',
                        icon: Icons.info_outline,
                      ),
                      SizedBox(height: 16.h),

                      // Description
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Açıklama',
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              // Buttons
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : widget.onClose,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          side: BorderSide(
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'İptal',
                          style: TextStyle(color: Colors.white, fontSize: 16.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveEquipment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFA3),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: _isSaving
                            ? SizedBox(
                                height: 20.w,
                                width: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.w,
                                  color: const Color(0xFF0A0E27),
                                ),
                              )
                            : Text(
                                'Kaydet',
                                style: TextStyle(
                                  color: const Color(0xFF0A0E27),
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
          borderSide: const BorderSide(color: Color(0xFF00FFA3), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: validator,
    );
  }
}
