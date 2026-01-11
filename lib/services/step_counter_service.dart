import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepCounterService {
  static final StepCounterService _instance = StepCounterService._internal();
  factory StepCounterService() => _instance;
  StepCounterService._internal();

  StreamSubscription<StepCount>? _stepCountSubscription;
  int _todaySteps = 0;
  int _initialSteps = 0;
  bool _isInitialized = false;
  DateTime? _lastResetDate;

  // Stream controller for steps
  final _stepsController = StreamController<int>.broadcast();
  Stream<int> get stepsStream => _stepsController.stream;

  int get todaySteps => _todaySteps;

  // Her 1000 adımda +100ml bonus
  static const int stepsPerBonus = 1000;
  static const int bonusPerSteps = 100;

  // Adım bonusunu hesapla
  int getStepBonus() {
    return (_todaySteps ~/ stepsPerBonus) * bonusPerSteps;
  }

  // İzin kontrolü ve isteği
  Future<bool> requestPermission() async {
    if (await Permission.activityRecognition.isGranted) {
      return true;
    }

    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  // Adım sayacını başlat
  Future<void> initStepCounter() async {
    if (_isInitialized) return;

    // İzin kontrolü
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      print('Activity Recognition izni reddedildi');
      return;
    }

    // Günü sıfırla (gece yarısı kontrolü)
    _checkAndResetDay();

    try {
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );
      _isInitialized = true;
    } catch (e) {
      print('Adım sayacı başlatılamadı: $e');
    }
  }

  void _onStepCount(StepCount event) {
    final now = DateTime.now();

    // Gün değişti mi kontrol et
    if (_lastResetDate == null ||
        _lastResetDate!.day != now.day ||
        _lastResetDate!.month != now.month ||
        _lastResetDate!.year != now.year) {
      _resetDailySteps(event.steps);
    } else {
      // Günlük adımları hesapla
      _todaySteps = event.steps - _initialSteps;
      if (_todaySteps < 0) _todaySteps = 0;
    }

    _stepsController.add(_todaySteps);
  }

  void _onStepCountError(error) {
    print('Adım sayacı hatası: $error');
  }

  void _checkAndResetDay() {
    final now = DateTime.now();
    if (_lastResetDate == null ||
        _lastResetDate!.day != now.day ||
        _lastResetDate!.month != now.month ||
        _lastResetDate!.year != now.year) {
      _todaySteps = 0;
      _lastResetDate = now;
    }
  }

  void _resetDailySteps(int currentTotalSteps) {
    _initialSteps = currentTotalSteps;
    _todaySteps = 0;
    _lastResetDate = DateTime.now();
  }

  // Servisi durdur
  void dispose() {
    _stepCountSubscription?.cancel();
    _stepsController.close();
    _isInitialized = false;
  }
}
