import 'package:flutter/foundation.dart';
import '../data/database/database_helper.dart';
import '../data/models.dart';
import 'step_counter_service.dart';

class HydrationService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final StepCounterService _stepService = StepCounterService();

  // Günlük su hedefi (ml)
  static const int baseWaterGoal = 2500;
  static const int workoutBonus = 500;
  static const int waterIncrement = 200;
  
  // Su değişikliklerini tüm widget'lara bildirmek için
  static final ValueNotifier<int> waterChangeNotifier = ValueNotifier<int>(0);

  // Kullanıcının günlük su hedefini hesapla (antrenman + adım bonusu)
  Future<int> getDailyWaterGoal(int userId) async {
    final hasWorkout = await _db.hasWorkoutToday(userId);
    final stepBonus = _stepService.getStepBonus();

    int goal = baseWaterGoal;
    if (hasWorkout) goal += workoutBonus;
    goal += stepBonus;

    return goal;
  }

  // Bugün içilen su miktarını getir
  Future<int> getTodayWaterIntake(int userId) async {
    return await _db.getTodayHydration(userId);
  }

  // Su ekle (200ml)
  Future<void> addWater(int userId) async {
    final today = DateTime.now();
    await _db.createHydrationLog(
      HydrationLog(userId: userId, amountMl: waterIncrement, date: today),
    );
    // Değişikliği bildir
    waterChangeNotifier.value++;
  }

  // Su çıkar (200ml)
  Future<void> removeWater(int userId) async {
    final today = DateTime.now();
    final currentAmount = await _db.getTodayHydration(userId);

    if (currentAmount >= waterIncrement) {
      await _db.createHydrationLog(
        HydrationLog(userId: userId, amountMl: -waterIncrement, date: today),
      );
      // Değişikliği bildir
      waterChangeNotifier.value++;
    }
  }

  // İlerleme yüzdesini hesapla (0.0 - 1.0)
  Future<double> getProgress(int userId) async {
    final goal = await getDailyWaterGoal(userId);
    final intake = await getTodayWaterIntake(userId);
    return (intake / goal).clamp(0.0, 1.0);
  }
}
