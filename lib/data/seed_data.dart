import 'package:flutter/material.dart';
import '../data/database/database_helper.dart';
import '../data/models.dart';

/// Bu dosya, test amaçlı örnek GYM_BRANCH verileri eklemek için kullanılır
/// Ana uygulama başlangıcında veya geliştirme sırasında çağrılabilir
class SeedData {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  /// Örnek spor salonu verilerini ekler
  static Future<void> seedGymBranches() async {
    // Önce mevcut salonları kontrol et
    final existingGyms = await _db.getAllGymBranches();
    
    // Eğer Malatya dışında salonlar varsa veya salon sayısı 4'ten farklıysa, hepsini sil
    if (existingGyms.isNotEmpty) {
      bool needsReset = existingGyms.length != 4;
      if (!needsReset) {
        // Tüm salonların Malatya'da olup olmadığını kontrol et
        for (var gym in existingGyms) {
          if (gym.city != 'Malatya') {
            needsReset = true;
            break;
          }
        }
      }
      
      if (!needsReset) {
        debugPrint('✅ Salonlar zaten mevcut (${existingGyms.length} Malatya salonu)');
        return;
      }
      
      // Eski salonları sil
      debugPrint('🗑️ Eski salonlar siliniyor (${existingGyms.length} salon)...');
      for (var gym in existingGyms) {
        await _db.deleteGymBranch(gym.id!);
      }
      debugPrint('✅ Eski salonlar silindi');
    }

    debugPrint('🏋️ Malatya salon verileri ekleniyor...');

    final gyms = [

      // Malatya
      GymBranch(
        name: 'X Fitness Malatya',
        address: 'Şifa Mah. İnönü Cad. Doğa Cadde AVM Altı No:148',
        city: 'Malatya',
        phone: '+90 536 276 93 54',
        email: 'xfitmalatya@gmail.com',
        latitude: 38.3496,
        longitude: 38.3188,
        openingTime: '08:00',
        closingTime: '23:30',
        facilities: 'Fitness, Cardio, Sauna, Buhar Odası, Vitamin Bar',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      GymBranch(
        name: 'Mosk Gym (Olimpik Spor Kulübü)',
        address: 'Tecde Mah. Altınkayısı Bulvarı No:71/38',
        city: 'Malatya',
        phone: '+90 422 502 33 00',
        email: 'info@moskgym.com',
        latitude: 38.3268,
        longitude: 38.2562,
        openingTime: '07:00',
        closingTime: '22:30',
        facilities: 'Yüzme Havuzu, Fitness, Cimnastik, Pilates, Çocuk Grubu',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      GymBranch(
        name: 'Fitbull Gym Tecde',
        address: 'Tecde Mah. Biga Sok. Ukab 1A Blok No:2/1',
        city: 'Malatya',
        phone: '+90 539 777 13 06',
        email: 'info@fitbullgym.com',
        latitude: 38.3216,
        longitude: 38.2523,
        openingTime: '09:00',
        closingTime: '23:00',
        facilities: 'Bodybuilding, Crossfit, Cardio, Personal Training',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      GymBranch(
        name: 'Doğuş Spor Kulübü',
        address: 'Şeyh Bayram Mah. Hacı Bayram Veli Cad. No:12',
        city: 'Malatya',
        phone: '+90 501 245 54 54',
        email: 'info@malatyadogusspor.com',
        latitude: 38.3420,
        longitude: 38.2950,
        openingTime: '08:30',
        closingTime: '22:00',
        facilities: 'Taekwondo, Kick Boks, Fitness, Çocuk Jimnastik',
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];

    // Salonları veritabanına ekle
    for (var gym in gyms) {
      try {
        await _db.createGymBranch(gym);
        debugPrint('✅ Eklendi: ${gym.name}');
      } catch (e) {
        debugPrint('❌ Hata (${gym.name}): $e');
      }
    }

    debugPrint('🎉 ${gyms.length} salon başarıyla eklendi!');
  }

  /// Tüm örnek verileri ekler
  static Future<void> seedAllData() async {
    await seedGymBranches();
    await seedExercises();
    await seedEquipment();
  }

  /// Örnek ekipman verileri ekler (YouTube videoları ile)
  static Future<void> seedEquipment() async {
    final existingEquipment = await _db.getAllEquipment();
    final existingByQr = {
      for (final eq in existingEquipment) if (eq.qrCode != null) eq.qrCode!: eq,
    };

    if (existingEquipment.isNotEmpty) {
      debugPrint(
        'ℹ️ Ekipmanlar mevcut, eksik olanlar tamamlanacak (${existingEquipment.length} ekipman)',
      );
    } else {
      debugPrint('🏋️ Örnek ekipman verileri ekleniyor...');
    }

    final gyms = await _db.getAllGymBranches();
    final firstGymId = gyms.isNotEmpty ? gyms.first.id : null;

    final equipment = [
      Equipment(
        gymBranchId: firstGymId,
        name: 'Treadmill',
        type: 'Cardio',
        brand: 'Life Fitness',
        model: 'T5',
        qrCode: 'TREADMILL001',
        videoUrl: 'https://www.youtube.com/watch?v=Z5rJ1q3F1_k',
        description: 'Profesyonel koşu bandı. Hız ve eğim ayarlanabilir.',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      Equipment(
        gymBranchId: firstGymId,
        name: 'Chest Press Machine',
        type: 'Strength',
        brand: 'Technogym',
        model: 'Selection',
        qrCode: 'CHEST001',
        videoUrl: 'https://www.youtube.com/watch?v=EsE4n-cMJ4I',
        description: 'Göğüs presi makinesi. Güvenli ve etkili göğüs çalışması.',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      Equipment(
        gymBranchId: firstGymId,
        name: 'Leg Press Machine',
        type: 'Strength',
        brand: 'Matrix',
        model: 'G7',
        qrCode: 'LEG001',
        videoUrl: 'https://www.youtube.com/watch?v=WJqCq6Xf1u4',
        description:
            'Bacak presi makinesi. Quadriceps, hamstring ve glutes çalışır.',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      Equipment(
        gymBranchId: firstGymId,
        name: 'Lat Pulldown Machine',
        type: 'Strength',
        brand: 'Hammer Strength',
        model: 'Select',
        qrCode: 'LAT001',
        videoUrl: 'https://www.youtube.com/watch?v=CAwf7n6Luuc',
        description: 'Lat pulldown makinesi. Sırt kaslarını güçlendirir.',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      Equipment(
        gymBranchId: firstGymId,
        name: 'Smith Machine',
        type: 'Free Weight',
        brand: 'Cybex',
        model: 'VR2',
        qrCode: 'SMITH001',
        videoUrl: 'https://www.youtube.com/watch?v=wX-4y8b7i7k',
        description:
            'Smith machine. Squat, bench press ve omuz presi için ideal.',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      Equipment(
        gymBranchId: firstGymId,
        name: 'Cable Crossover Machine',
        type: 'Strength',
        brand: 'Life Fitness',
        model: 'Signature',
        qrCode: 'CABLE001',
        videoUrl: 'https://www.youtube.com/watch?v=IweDW-R8sMg',
        description: 'Kablo crossover makinesi. Çok yönlü egzersizler için.',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      Equipment(
        gymBranchId: firstGymId,
        name: 'Rowing Machine',
        type: 'Cardio',
        brand: 'Concept2',
        model: 'Model D',
        qrCode: 'ROW001',
        videoUrl: 'https://www.youtube.com/watch?v=UC_7O_h59v4',
        description:
            'Kürek çekme makinesi. Tüm vücudu çalıştıran kardio egzersizi.',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      Equipment(
        gymBranchId: firstGymId,
        name: 'Stationary Bike',
        type: 'Cardio',
        brand: 'Schwinn',
        model: 'IC4',
        qrCode: 'BIKE001',
        videoUrl: 'https://www.youtube.com/watch?v=4h-p4Ww7aCg',
        description: 'Sabit bisiklet. Düşük etkili kardio egzersizi.',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      Equipment(
        gymBranchId: firstGymId,
        name: 'Biceps Curl Machine',
        type: 'Strength',
        brand: 'Hammer Strength',
        model: 'Select',
        qrCode: 'BICEPS001',
        videoUrl: 'https://www.youtube.com/watch?v=qlC3Qn8WfVI',
        description: 'Biceps curl makinesi. İzole biceps çalışması için ideal.',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      Equipment(
        gymBranchId: firstGymId,
        name: 'Triceps Press Machine',
        type: 'Strength',
        brand: 'Life Fitness',
        model: 'Signature',
        qrCode: 'TRICEPS001',
        videoUrl: 'https://www.youtube.com/watch?v=GLqfwlVvYqI',
        description: 'Triceps press makinesi. Triceps kaslarını güçlendirir.',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      Equipment(
        gymBranchId: firstGymId,
        name: 'Crunch Machine',
        type: 'Strength',
        brand: 'Technogym',
        model: 'Selection',
        qrCode: 'CRUNCH001',
        videoUrl: 'https://www.youtube.com/watch?v=D-d6nB1e22s',
        description:
            'Crunch makinesi. Karın kaslarını izole şekilde çalıştırır.',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
    ];

    var addedCount = 0;
    for (final item in equipment) {
      final code = item.qrCode;
      if (code != null && existingByQr.containsKey(code)) {
        continue;
      }
      await _db.createEquipment(item);
      addedCount++;
    }

    debugPrint(
      '🎉 $addedCount yeni ekipman eklendi, toplam ${existingEquipment.length + addedCount} ekipman mevcut.',
    );
  }

  /// Kapsamlı egzersiz kütüphanesi ekler
  static Future<void> seedExercises() async {
    // GELİŞTİRME AMAÇLI: Mevcut egzersizleri kontrol et ve sil
    final existingExercises = await _db.getAllExercises();
    if (existingExercises.isNotEmpty) {
      debugPrint(
        '🗑️ Mevcut ${existingExercises.length} egzersiz siliniyor...',
      );
      for (final exercise in existingExercises) {
        if (exercise.id != null) {
          await _db.deleteExercise(exercise.id!);
        }
      }
      debugPrint('✅ Eski egzersizler silindi');
    }

    debugPrint('💪 Örnek egzersiz kütüphanesi ekleniyor...');

    final exercises = [
      // CHEST (Göğüs) Egzersizleri
      Exercise(
        name: 'Barbell Bench Press',
        description:
            'Klasik düz bench press. Göğüs kaslarının tamamını çalıştırır.',
        muscleGroup: 'Chest',
        equipment: 'Barbell',
        thumbnailImage: 'assets/images/exercises/barbell_bench_press_thumbnail.jpg',
        stepImage1: 'assets/images/exercises/barbell_bench_press_step1.jpg',
        stepImage2: 'assets/images/exercises/barbell_bench_press_step2.jpg',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Incline Dumbbell Press',
        description:
            'Üst göğüs kaslarına odaklanır. 30-45 derece açıyla yapılır.',
        muscleGroup: 'Chest',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Cable Chest Fly',
        description: 'İzole göğüs hareketi. Kasın gerilmesini sağlar.',
        muscleGroup: 'Chest',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Push-ups',
        description: 'Vücut ağırlığı ile yapılan temel göğüs egzersizi.',
        muscleGroup: 'Chest',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Decline Bench Press',
        description: 'Alt göğüs kaslarına odaklanır.',
        muscleGroup: 'Chest',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Dumbbell Chest Press',
        description:
            'Dumbbell ile yapılan göğüs presi, daha geniş hareket açısı sağlar.',
        muscleGroup: 'Chest',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),

      // BACK (Sırt) Egzersizleri
      Exercise(
        name: 'Deadlift',
        description:
            'Tüm vücudu çalıştıran kompound hareket. Sırt, bacak ve core.',
        muscleGroup: 'Back',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Pull-ups',
        description: 'Vücut ağırlığı ile sırt genişliği kazandıran egzersiz.',
        muscleGroup: 'Back',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Barbell Row',
        description: 'Sırt kalınlığı için etkili kompound hareket.',
        muscleGroup: 'Back',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Lat Pulldown',
        description: 'Latissimus dorsi kasını izole eder.',
        muscleGroup: 'Back',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Seated Cable Row',
        description: 'Orta sırt kaslarını hedefler.',
        muscleGroup: 'Back',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'T-Bar Row',
        description: 'Sırt kalınlığı için mükemmel egzersiz.',
        muscleGroup: 'Back',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Single Arm Dumbbell Row',
        description: 'Her iki tarafı ayrı ayrı çalıştırır, dengeyi geliştirir.',
        muscleGroup: 'Back',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),

      // LEGS (Bacak) Egzersizleri
      Exercise(
        name: 'Barbell Squat',
        description:
            'Bacak gelişimi için en etkili egzersiz. Quad, hamstring ve glute.',
        muscleGroup: 'Legs',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Leg Press',
        description: 'Makine ile güvenli şekilde bacak basma egzersizi.',
        muscleGroup: 'Legs',
        equipment: 'Machine',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Romanian Deadlift',
        description: 'Hamstring ve glute kaslarını izole eder.',
        muscleGroup: 'Legs',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Leg Extension',
        description: 'Quadriceps kasını izole eden makine egzersizi.',
        muscleGroup: 'Legs',
        equipment: 'Machine',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Leg Curl',
        description: 'Hamstring kaslarını izole eder.',
        muscleGroup: 'Legs',
        equipment: 'Machine',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Walking Lunges',
        description:
            'Fonksiyonel bacak egzersizi, denge ve koordinasyon geliştirir.',
        muscleGroup: 'Legs',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Bulgarian Split Squat',
        description: 'Tek bacak ile yapılan squat varyasyonu.',
        muscleGroup: 'Legs',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Calf Raises',
        description: 'Baldır kaslarını geliştiren egzersiz.',
        muscleGroup: 'Legs',
        equipment: 'Machine',
        createdAt: DateTime.now(),
      ),

      // SHOULDERS (Omuz) Egzersizleri
      Exercise(
        name: 'Overhead Press',
        description: 'Omuz kasları için temel kompound hareket.',
        muscleGroup: 'Shoulders',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Dumbbell Shoulder Press',
        description: 'Dumbbell ile omuz presi, geniş hareket açısı.',
        muscleGroup: 'Shoulders',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Lateral Raises',
        description: 'Omuz genişliği kazandıran izolasyon hareketi.',
        muscleGroup: 'Shoulders',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Front Raises',
        description: 'Ön omuz kaslarını izole eder.',
        muscleGroup: 'Shoulders',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Rear Delt Fly',
        description: 'Arka omuz kaslarını hedefler.',
        muscleGroup: 'Shoulders',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Face Pulls',
        description: 'Arka omuz ve duruş için mükemmel egzersiz.',
        muscleGroup: 'Shoulders',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Arnold Press',
        description: 'Arnold Schwarzenegger\'in ünlü omuz egzersizi.',
        muscleGroup: 'Shoulders',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),

      // ARMS (Kol) Egzersizleri - Biceps
      Exercise(
        name: 'Barbell Curl',
        description: 'Biceps geliştirmek için klasik egzersiz.',
        muscleGroup: 'Arms',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Dumbbell Hammer Curl',
        description: 'Biceps ve brachialis kaslarını çalıştırır.',
        muscleGroup: 'Arms',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Preacher Curl',
        description: 'Biceps izolasyonu için bench kullanılır.',
        muscleGroup: 'Arms',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Cable Bicep Curl',
        description: 'Sabit gerilim ile biceps çalışması.',
        muscleGroup: 'Arms',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),

      // ARMS (Kol) Egzersizleri - Triceps
      Exercise(
        name: 'Close Grip Bench Press',
        description: 'Triceps için kompound hareket.',
        muscleGroup: 'Arms',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Tricep Dips',
        description: 'Vücut ağırlığı ile triceps çalışması.',
        muscleGroup: 'Arms',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Overhead Tricep Extension',
        description: 'Triceps uzun başını hedefler.',
        muscleGroup: 'Arms',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Tricep Pushdown',
        description: 'Kablo ile triceps izolasyonu.',
        muscleGroup: 'Arms',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Skull Crushers',
        description: 'Lying tricep extension, yoğun triceps egzersizi.',
        muscleGroup: 'Arms',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),

      // CORE (Karın) Egzersizleri
      Exercise(
        name: 'Plank',
        description: 'Core stabilizasyonu için en etkili egzersiz.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Crunches',
        description: 'Klasik karın egzersizi.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Russian Twists',
        description: 'Oblik kasları çalıştıran rotasyon hareketi.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Hanging Leg Raises',
        description: 'Alt karın için zorlu egzersiz.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Cable Woodchoppers',
        description: 'Oblik kasları için fonksiyonel hareket.',
        muscleGroup: 'Core',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Ab Wheel Rollout',
        description: 'Core gücü için ileri seviye egzersiz.',
        muscleGroup: 'Core',
        equipment: 'Ab Wheel',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Mountain Climbers',
        description: 'Dinamik core egzersizi, kardio faydası da var.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),

      // CARDIO Egzersizleri
      Exercise(
        name: 'Treadmill Running',
        description: 'Koşu bandı ile kardiovasküler dayanıklılık.',
        muscleGroup: 'Cardio',
        equipment: 'Treadmill',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Stationary Bike',
        description: 'Düşük etkili kardio egzersizi.',
        muscleGroup: 'Cardio',
        equipment: 'Bike',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Rowing Machine',
        description: 'Tüm vücudu çalıştıran kardio egzersizi.',
        muscleGroup: 'Cardio',
        equipment: 'Rowing Machine',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Jump Rope',
        description: 'Koordinasyon ve kardio için ip atlama.',
        muscleGroup: 'Cardio',
        equipment: 'Jump Rope',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Elliptical Trainer',
        description: 'Eklemlere nazik kardio makinesi.',
        muscleGroup: 'Cardio',
        equipment: 'Elliptical',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Battle Ropes',
        description: 'Yüksek yoğunluklu kardio ve üst vücut çalışması.',
        muscleGroup: 'Cardio',
        equipment: 'Battle Ropes',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Burpees',
        description: 'Tüm vücudu çalıştıran yüksek yoğunluklu egzersiz.',
        muscleGroup: 'Cardio',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),

      // EK CHEST Egzersizleri
      Exercise(
        name: 'Chest Dips',
        description: 'Alt ve iç göğüs için etkili vücut ağırlığı hareketi.',
        muscleGroup: 'Chest',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Hex Press',
        description:
            'Dumbbell\'lar birbirine bastırılarak iç göğüs kasılması sağlanır.',
        muscleGroup: 'Chest',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Pec Deck Machine',
        description: 'İzole göğüs kasılması, makine güvenliği sağlar.',
        muscleGroup: 'Chest',
        equipment: 'Machine',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Landmine Press',
        description: 'Alternatif açıyla üst göğüs geliştirme.',
        muscleGroup: 'Chest',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Svend Press',
        description: 'Plakalar ile iç göğüs izolasyonu.',
        muscleGroup: 'Chest',
        equipment: 'Plate',
        createdAt: DateTime.now(),
      ),

      // EK BACK Egzersizleri
      Exercise(
        name: 'Chin-ups',
        description: 'Underhand grip ile biceps ve sırt çalışması.',
        muscleGroup: 'Back',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Face Pulls',
        description: 'Arka omuz ve üst sırt için mükemmel.',
        muscleGroup: 'Back',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Inverted Row',
        description: 'Barfiks alternatifi, yatay çekiş hareketi.',
        muscleGroup: 'Back',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Meadows Row',
        description: 'T-bar row varyasyonu, tek kol ile.',
        muscleGroup: 'Back',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Rack Pulls',
        description: 'Kısmi deadlift, üst sırt ve trapeze odaklanır.',
        muscleGroup: 'Back',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Straight Arm Pulldown',
        description: 'Latissimus dorsi izolasyonu.',
        muscleGroup: 'Back',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Hyperextensions',
        description: 'Alt sırt ve glute çalışması.',
        muscleGroup: 'Back',
        equipment: 'Machine',
        createdAt: DateTime.now(),
      ),

      // EK LEGS Egzersizleri
      Exercise(
        name: 'Front Squat',
        description: 'Ağırlık önde, quadriceps odaklı squat varyasyonu.',
        muscleGroup: 'Legs',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Hack Squat',
        description: 'Makine ile güvenli ve etkili bacak çalışması.',
        muscleGroup: 'Legs',
        equipment: 'Machine',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Goblet Squat',
        description: 'Dumbbell veya kettlebell ile squat formu geliştirme.',
        muscleGroup: 'Legs',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Sumo Deadlift',
        description: 'Geniş duruş ile iç bacak ve glute odaklı.',
        muscleGroup: 'Legs',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Sissy Squat',
        description: 'İleri seviye quad izolasyonu.',
        muscleGroup: 'Legs',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Box Jumps',
        description: 'Patlayıcı güç ve bacak gücü geliştirme.',
        muscleGroup: 'Legs',
        equipment: 'Box',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Glute Bridge',
        description: 'Kalça kaldırma, glute ve hamstring çalışması.',
        muscleGroup: 'Legs',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Hip Thrust',
        description: 'Glute geliştirmek için en etkili egzersiz.',
        muscleGroup: 'Legs',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Nordic Hamstring Curl',
        description: 'İleri seviye hamstring kuvvet çalışması.',
        muscleGroup: 'Legs',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Leg Press Calf Raise',
        description: 'Leg press makinesi ile baldır çalışması.',
        muscleGroup: 'Legs',
        equipment: 'Machine',
        createdAt: DateTime.now(),
      ),

      // EK SHOULDERS Egzersizleri
      Exercise(
        name: 'Military Press',
        description: 'Ayakta yapılan overhead press, core de çalışır.',
        muscleGroup: 'Shoulders',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Bradford Press',
        description: 'Önden arkaya geçiş yaparak tüm omuzları çalıştırır.',
        muscleGroup: 'Shoulders',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Cuban Press',
        description: 'Rotator cuff ve omuz sağlığı için kompleks hareket.',
        muscleGroup: 'Shoulders',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Cable Lateral Raise',
        description: 'Sürekli gerilim ile yan omuz çalışması.',
        muscleGroup: 'Shoulders',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Upright Row',
        description: 'Trapez ve yan omuz geliştirme.',
        muscleGroup: 'Shoulders',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Push Press',
        description: 'Bacak desteği ile ağır ağırlık kaldırma.',
        muscleGroup: 'Shoulders',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Band Pull Aparts',
        description: 'Arka omuz ve duruş düzeltme egzersizi.',
        muscleGroup: 'Shoulders',
        equipment: 'Band',
        createdAt: DateTime.now(),
      ),

      // EK ARMS Egzersizleri
      Exercise(
        name: 'Concentration Curl',
        description: 'Oturarak tek kol biceps izolasyonu.',
        muscleGroup: 'Arms',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Spider Curl',
        description: 'İncline bench üzerinde biceps izolasyonu.',
        muscleGroup: 'Arms',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Zottman Curl',
        description: 'Biceps ve forearm birlikte çalıştırma.',
        muscleGroup: 'Arms',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: '21s Curl',
        description: '7+7+7 tekrar ile biceps yoğun çalışması.',
        muscleGroup: 'Arms',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Diamond Push-ups',
        description: 'Triceps odaklı şınav varyasyonu.',
        muscleGroup: 'Arms',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Bench Dips',
        description: 'Bench kullanarak triceps çalışması.',
        muscleGroup: 'Arms',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Rope Tricep Pushdown',
        description: 'Halat ile triceps izolasyonu ve split.',
        muscleGroup: 'Arms',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'JM Press',
        description: 'Bench press ve skull crusher kombinasyonu.',
        muscleGroup: 'Arms',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Wrist Curl',
        description: 'Önkol geliştirme, grip gücü artırma.',
        muscleGroup: 'Arms',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Reverse Wrist Curl',
        description: 'Önkol ekstansörleri çalıştırma.',
        muscleGroup: 'Arms',
        equipment: 'Barbell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Farmers Walk',
        description: 'Grip gücü ve önkol dayanıklılığı.',
        muscleGroup: 'Arms',
        equipment: 'Dumbbell',
        createdAt: DateTime.now(),
      ),

      // EK CORE Egzersizleri
      Exercise(
        name: 'Side Plank',
        description: 'Oblik kasları ve yan core stabilizasyonu.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Bicycle Crunches',
        description: 'Dinamik karın ve oblik çalışması.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Dragon Flag',
        description: 'Bruce Lee\'nin ünlü ileri seviye core egzersizi.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Dead Bug',
        description: 'Core stabilizasyon ve koordinasyon.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Pallof Press',
        description: 'Anti-rotasyon core kuvvet çalışması.',
        muscleGroup: 'Core',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'L-Sit Hold',
        description: 'İleri seviye core ve hip flexor kuvveti.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Reverse Crunches',
        description: 'Alt karına odaklanan crunch varyasyonu.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Cable Crunches',
        description: 'Ağırlıklı karın çalışması, dirençli kasılma.',
        muscleGroup: 'Core',
        equipment: 'Cable',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'V-Ups',
        description: 'Tüm karın kaslarını birlikte çalıştırır.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Oblique Crunches',
        description: 'Yan karın kaslarına odaklanan crunch.',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),

      // EK CARDIO ve Fonksiyonel Egzersizler
      Exercise(
        name: 'Box Step-Ups',
        description: 'Kardio ve bacak gücü kombinasyonu.',
        muscleGroup: 'Cardio',
        equipment: 'Box',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Kettlebell Swings',
        description: 'Posterior chain ve kardio çalışması.',
        muscleGroup: 'Cardio',
        equipment: 'Kettlebell',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Sled Push',
        description: 'Yüksek yoğunluklu bacak ve kardio.',
        muscleGroup: 'Cardio',
        equipment: 'Sled',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Sled Pull',
        description: 'Posterior chain ve grip kuvveti.',
        muscleGroup: 'Cardio',
        equipment: 'Sled',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'High Knees',
        description: 'Kardio ve bacak kaldırma koordinasyonu.',
        muscleGroup: 'Cardio',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Jumping Jacks',
        description: 'Klasik ısınma ve kardio hareketi.',
        muscleGroup: 'Cardio',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Ski Erg',
        description: 'Üst vücut kardio, cross-country skiing simülasyonu.',
        muscleGroup: 'Cardio',
        equipment: 'Ski Erg',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Assault Bike',
        description: 'Tüm vücut yüksek yoğunluklu kardio.',
        muscleGroup: 'Cardio',
        equipment: 'Assault Bike',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Stair Climber',
        description: 'Merdiven çıkma simülasyonu, bacak ve kardio.',
        muscleGroup: 'Cardio',
        equipment: 'Machine',
        createdAt: DateTime.now(),
      ),
      Exercise(
        name: 'Shadow Boxing',
        description: 'Kardio ve üst vücut koordinasyonu.',
        muscleGroup: 'Cardio',
        equipment: 'Bodyweight',
        createdAt: DateTime.now(),
      ),
    ];

    int successCount = 0;
    for (final exercise in exercises) {
      try {
        await _db.createExercise(exercise);
        successCount++;
      } catch (e) {
        debugPrint('❌ Egzersiz ekleme hatası (${exercise.name}): $e');
      }
    }

    debugPrint('🎉 $successCount egzersiz başarıyla eklendi!');
  }
}
