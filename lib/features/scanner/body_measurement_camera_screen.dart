import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../../data/database/database_helper.dart';
import '../../data/models.dart';

class BodyMeasurementCameraScreen extends StatefulWidget {
  final int userId;

  const BodyMeasurementCameraScreen({
    super.key,
    required this.userId,
  });

  @override
  State<BodyMeasurementCameraScreen> createState() =>
      _BodyMeasurementCameraScreenState();
}

class _BodyMeasurementCameraScreenState
    extends State<BodyMeasurementCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras!.isEmpty) {
        _showError('Kamera bulunamadı');
        return;
      }

      // Use front camera if available, otherwise back camera
      CameraDescription camera = _cameras!.first;
      for (var cam in _cameras!) {
        if (cam.lensDirection == CameraLensDirection.front) {
          camera = cam;
          break;
        }
      }

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('Kamera başlatılamadı: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();
      
      // Save to permanent location
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'body_measurement_$timestamp.jpg';
      final permanentPath = path.join(directory.path, 'measurements', fileName);
      
      // Create measurements directory if it doesn't exist
      final measurementsDir = Directory(path.join(directory.path, 'measurements'));
      if (!await measurementsDir.exists()) {
        await measurementsDir.create(recursive: true);
      }

      // Copy file to permanent location
      await File(photo.path).copy(permanentPath);

      setState(() {
        _capturedImagePath = permanentPath;
        _isProcessing = false;
      });

      // Show preview screen
      _showPreviewScreen(permanentPath);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Fotoğraf çekilemedi: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentDirection = _controller?.description.lensDirection;
    CameraDescription newCamera;

    if (currentDirection == CameraLensDirection.back) {
      newCamera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
    } else {
      newCamera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
    }

    await _controller?.dispose();

    _controller = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  void _showPreviewScreen(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MeasurementPreviewScreen(
          imagePath: imagePath,
          userId: widget.userId,
        ),
      ),
    ).then((saved) {
      if (saved == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF6B9D),
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
          if (_isInitialized && _controller != null)
            SizedBox.expand(
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00FFA3),
              ),
            ),

          // UI Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),
                
                const Spacer(),
                
                // Bottom Controls
                _buildBottomControls(),
              ],
            ),
          ),

          // Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00FFA3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'Vücut Ölçümü Fotoğrafı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Instructions
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.person_outline,
                  color: const Color(0xFF00FFA3),
                  size: 32.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Tam boy fotoğraf çekin',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'İlerlemenizi görselleştirin',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          
          // Camera Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Switch Camera Button
              if (_cameras != null && _cameras!.length > 1)
                IconButton(
                  onPressed: _switchCamera,
                  icon: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 2),
                    ),
                    child: Icon(
                      Icons.flip_camera_android,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                )
              else
                SizedBox(width: 60.w),

              // Capture Button
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                      ),
                    ),
                  ),
                ),
              ),

              // Placeholder for symmetry
              SizedBox(width: 60.w),
            ],
          ),
        ],
      ),
    );
  }
}

// Preview Screen for measurement photo
class _MeasurementPreviewScreen extends StatefulWidget {
  final String imagePath;
  final int userId;

  const _MeasurementPreviewScreen({
    required this.imagePath,
    required this.userId,
  });

  @override
  State<_MeasurementPreviewScreen> createState() =>
      _MeasurementPreviewScreenState();
}

class _MeasurementPreviewScreenState extends State<_MeasurementPreviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = DatabaseHelper.instance;
      
      final weight = double.tryParse(_weightController.text);
      final height = double.tryParse(_heightController.text);
      
      // Calculate BMI if both values provided
      double? bmi;
      if (weight != null && height != null && height > 0) {
        bmi = weight / ((height / 100) * (height / 100));
      }

      final measurement = BodyMeasurements(
        userId: widget.userId,
        measurementDate: DateTime.now(),
        weight: weight,
        height: height,
        bmi: bmi,
        notes: '${_notesController.text}\nFoto: ${widget.imagePath}',
        createdAt: DateTime.now(),
      );

      await db.createBodyMeasurement(measurement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ölçüm kaydedildi! ✓'),
            backgroundColor: Color(0xFF00FFA3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: const Color(0xFFFF6B9D),
          ),
        );
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
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF0A0E27)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Ölçüm Detayları',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Photo Preview
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: Image.file(
                            File(widget.imagePath),
                            height: 300.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Weight Input
                        TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Kilo (kg)',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            prefixIcon: const Icon(
                              Icons.monitor_weight_outlined,
                              color: Color(0xFF00FFA3),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF00FFA3),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Height Input
                        TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Boy (cm)',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            prefixIcon: const Icon(
                              Icons.height,
                              color: Color(0xFF00D4FF),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF00D4FF),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Notes Input
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Notlar (opsiyonel)',
                            labelStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            prefixIcon: const Icon(
                              Icons.note_outlined,
                              color: Color(0xFFFF6B9D),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFFF6B9D),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveMeasurement,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FFA3),
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.save, color: Colors.white),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Kaydet',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }
}
