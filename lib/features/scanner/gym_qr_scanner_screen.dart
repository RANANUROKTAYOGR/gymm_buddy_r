import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/database/database_helper.dart';
import '../../services/gym_entry_service.dart';

class GymQRScannerScreen extends StatefulWidget {
  final int userId;

  const GymQRScannerScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<GymQRScannerScreen> createState() => _GymQRScannerScreenState();
}

class _GymQRScannerScreenState extends State<GymQRScannerScreen> {
  MobileScannerController? cameraController;
  final _dbHelper = DatabaseHelper.instance;
  final _gymEntryService = GymEntryService();
  bool isProcessing = false;
  String? lastScannedCode;

  // Giriş QR kodları (assets/images/giris klasöründeki)
  final List<String> _entryQRCodes = [
    'https://gym.com/uye/ali',
    'https://gym.com/uye/ayse',
    'https://gym.com/uye/mehmet',
    'https://gym.com/uye/yeni_kisi_1',
    'https://gym.com/uye/yeni_kisi_2',
  ];

  // Çıkış QR kodları (assets/images/cikis klasöründeki)
  final List<String> _exitQRCodes = [
    'https://gym.com/program/cardio',
    'https://gym.com/program/zayiflama',
    'https://gym.com/program/bulk',
    'https://gym.com/program/yoga',
    'https://gym.com/ekipman/kullanim_klavuzu',
  ];

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

  Future<void> _handleScannedCode(String qrCode) async {
    if (isProcessing || lastScannedCode == qrCode) return;

    setState(() {
      isProcessing = true;
      lastScannedCode = qrCode;
    });

    print('📱 QR Kod Okundu: $qrCode');

    try {
      // Giriş QR kodu mu kontrol et
      if (_entryQRCodes.contains(qrCode)) {
        await _handleEntry();
      }
      // Çıkış QR kodu mu kontrol et
      else if (_exitQRCodes.contains(qrCode)) {
        await _handleExit();
      }
      // Tanınmayan QR kod
      else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Geçersiz QR kod!\n$qrCode'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          _resetScanner();
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

  Future<void> _handleEntry() async {
    try {
      // Zaten giriş yapmış mı kontrol et
      if (_gymEntryService.isCheckedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Zaten ${_gymEntryService.currentGymName} salonuna giriş yaptınız!',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context);
        }
        return;
      }

      // İlk salonu al (Kadıköy şubesi varsayılan olsun)
      final branches = await _dbHelper.getAllGymBranches();
      if (branches.isEmpty) {
        throw Exception('Salon bulunamadı');
      }

      final defaultGym = branches.first; // İlk salon varsayılan

      // Salona giriş yap
      await _gymEntryService.checkIn(defaultGym.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${defaultGym.name} salonuna hoş geldiniz!',
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

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Giriş hatası: $e');
      rethrow;
    }
  }

  Future<void> _handleExit() async {
    try {
      // Giriş yapmamış mı kontrol et
      if (!_gymEntryService.isCheckedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Henüz salona giriş yapmadınız!'),
              backgroundColor: Colors.orange,
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context);
        }
        return;
      }

      final gymName = _gymEntryService.currentGymName;

      // Çıkış yap
      await _gymEntryService.checkOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.exit_to_app, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$gymName salonundan çıkış yaptınız. Görüşmek üzere!',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF6B9D),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Çıkış hatası: $e');
      rethrow;
    }
  }

  void _resetScanner() {
    setState(() {
      isProcessing = false;
      lastScannedCode = null;
    });
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
                            horizontal: 20.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((0.7 * 255).toInt()),
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                          child: Text(
                            'Salon Giriş/Çıkış QR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Instructions
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.7 * 255).toInt()),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: const Color(0xFF00FFA3),
                          size: 60.sp,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          isProcessing
                              ? 'QR Kod İşleniyor...'
                              : 'QR Kodu Kare İçine Alın',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Giriş veya çıkış QR kodunu okutun',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scan area overlay
          Center(
            child: Container(
              width: 250.w,
              height: 250.w,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF00FFA3),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
