import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../data/database/database_helper.dart';
import '../data/models.dart';

class GamificationManager {
  GamificationManager._();
  static final GamificationManager _instance = GamificationManager._();
  factory GamificationManager() => _instance;

  final DatabaseHelper _db = DatabaseHelper.instance;

  static const String badgeHydrationCode = 'SU_SAVASCISI';
  static const String badgeHydrationTitle = 'Su Savaşçısı';
  static const String badgeWorkoutCode = 'ILK_ADIM';
  static const String badgeWorkoutTitle = 'İlk Adım';

  Future<void> checkBadges(int userId, BuildContext context) async {
    final List<String> newlyEarned = [];

    // Su Rozeti: Bugün 3000ml üzeri ise ve daha önce alınmadıysa
    final todayTotal = await _db.getTodayHydration(userId);
    final hasHydration = await _db.hasUserBadge(userId, badgeHydrationCode);
    if (todayTotal >= 3000 && !hasHydration) {
      await _db.createUserBadge(
        UserBadge(
          userId: userId,
          badgeCode: badgeHydrationCode,
          title: badgeHydrationTitle,
          description: 'Bugün 3000ml su hedefine ulaştın! Kahramansın!',
          earnedAt: DateTime.now(),
        ),
      );
      newlyEarned.add(badgeHydrationTitle);
    }

    // Antrenman Rozeti: Toplam oturum sayısı 1 ise (ilk antrenman)
    final workoutCount = await _db.getWorkoutSessionCount(userId);
    final hasWorkoutBadge = await _db.hasUserBadge(userId, badgeWorkoutCode);
    if (workoutCount == 1 && !hasWorkoutBadge) {
      await _db.createUserBadge(
        UserBadge(
          userId: userId,
          badgeCode: badgeWorkoutCode,
          title: badgeWorkoutTitle,
          description: 'İlk antrenmanını tamamladın! Devam! 💪',
          earnedAt: DateTime.now(),
        ),
      );
      newlyEarned.add(badgeWorkoutTitle);
    }

    if (newlyEarned.isNotEmpty) {
      _showCelebration(context, newlyEarned);
    }
  }

  void _showCelebration(BuildContext context, List<String> badges) {
    final confettiController = ConfettiController(duration: const Duration(seconds: 2));
    confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.8,
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFF1FD9C1), size: 40),
                  const SizedBox(height: 8),
                  const Text('Tebrikler!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Yeni rozet(ler): ${badges.join(', ')}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      confettiController.dispose();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1FD9C1),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Harika!'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).then((_) => confettiController.dispose());
  }
}
