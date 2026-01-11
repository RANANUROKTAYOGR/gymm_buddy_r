import 'package:flutter/material.dart';
import '../data/database/database_helper.dart';
import '../data/seed_data.dart';

/// Harita özelliklerini test etmek için yardımcı sınıf
class MapTestHelper {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  /// Tüm salonları listele ve konsola yazdır
  static Future<void> printAllGyms() async {
    debugPrint('=== TÜMU SALONLAR ===');
    final gyms = await _db.getAllGymBranches();
    if (gyms.isEmpty) {
      debugPrint('❌ Hiç salon bulunamadı!');
      debugPrint('💡 SeedData.seedGymBranches() çalıştırılmalı');
    } else {
      for (var i = 0; i < gyms.length; i++) {
        final gym = gyms[i];
        debugPrint('${i + 1}. ${gym.name}');
        debugPrint('   📍 ${gym.latitude}, ${gym.longitude}');
        debugPrint('   📍 ${gym.address}, ${gym.city}');
        debugPrint('   🕐 ${gym.openingTime} - ${gym.closingTime}');
        debugPrint('');
      }
      debugPrint('✅ Toplam ${gyms.length} salon bulundu');
    }
  }

  /// Veritabanını temizle ve test verilerini yeniden ekle
  static Future<void> resetTestData() async {
    debugPrint('🔄 Test verileri sıfırlanıyor...');
    
    // Önce tüm salonları sil
    final gyms = await _db.getAllGymBranches();
    for (var gym in gyms) {
      if (gym.id != null) {
        await _db.deleteGymBranch(gym.id!);
      }
    }
    
    debugPrint('🗑️ ${gyms.length} salon silindi');
    
    // Yeni test verilerini ekle
    await SeedData.seedGymBranches();
    
    debugPrint('✅ Test verileri başarıyla sıfırlandı!');
  }

  /// Belirli bir konuma yakın salonları bul
  static Future<void> findNearbyGyms({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    debugPrint('=== YAKIN SALONLAR ===');
    debugPrint('📍 Konum: $latitude, $longitude');
    debugPrint('🔍 Yarıçap: $radiusKm km');
    debugPrint('');

    final gyms = await _db.getAllGymBranches();
    final nearbyGyms = <Map<String, dynamic>>[];

    for (var gym in gyms) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        gym.latitude,
        gym.longitude,
      );

      if (distance <= radiusKm) {
        nearbyGyms.add({
          'gym': gym,
          'distance': distance,
        });
      }
    }

    // Mesafeye göre sırala
    nearbyGyms.sort((a, b) => 
      (a['distance'] as double).compareTo(b['distance'] as double));

    if (nearbyGyms.isEmpty) {
      debugPrint('❌ $radiusKm km içinde salon bulunamadı');
    } else {
      for (var i = 0; i < nearbyGyms.length; i++) {
        final item = nearbyGyms[i];
        final gym = item['gym'];
        final distance = item['distance'] as double;
        
        debugPrint('${i + 1}. ${gym.name}');
        debugPrint('   📏 ${distance.toStringAsFixed(2)} km uzaklıkta');
        debugPrint('   📍 ${gym.address}');
        debugPrint('');
      }
      debugPrint('✅ ${nearbyGyms.length} salon bulundu');
    }
  }

  /// İki konum arasındaki mesafeyi hesapla (km cinsinden)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = (dLat / 2) * (dLat / 2) +
        _degreesToRadians(lat1) *
            _degreesToRadians(lat2) *
            (dLon / 2) *
            (dLon / 2);

    final c = 2 * (a < 0 ? -1 : 1) * (1 - a).abs();
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  /// Test senaryolarını çalıştır
  static Future<void> runAllTests() async {
    debugPrint('');
    debugPrint('╔═══════════════════════════════════╗');
    debugPrint('║   HARİTA TEST SENARYOLARİ        ║');
    debugPrint('╚═══════════════════════════════════╝');
    debugPrint('');

    // Test 1: Tüm salonları listele
    await printAllGyms();
    debugPrint('');

    // Test 2: İstanbul Kadıköy yakınındaki salonları bul
    await findNearbyGyms(
      latitude: 40.9876,
      longitude: 29.0234,
      radiusKm: 10.0,
    );
    debugPrint('');

    // Test 3: Ankara merkez yakınındaki salonları bul
    await findNearbyGyms(
      latitude: 39.9189,
      longitude: 32.8540,
      radiusKm: 20.0,
    );
    debugPrint('');

    debugPrint('✅ Tüm testler tamamlandı!');
  }
}
