import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService instance = LocationService._internal();
  factory LocationService() => instance;
  LocationService._internal();

  Position? _lastPosition;
  Stream<Position>? _positionStream;

  /// Konum izinlerini kontrol et ve iste
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Konum servisleri açık mı kontrol et
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Kullanıcının güncel konumunu al
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      _lastPosition = await Geolocator.getCurrentPosition();
      return _lastPosition;
    } catch (e) {
      debugPrint('❌ Konum alınırken hata: $e');
      return null;
    }
  }

  /// Konum değişikliklerini dinle
  Stream<Position> getPositionStream() {
    _positionStream ??= Geolocator.getPositionStream();
    return _positionStream!;
  }

  /// İki nokta arasındaki mesafeyi hesapla (metre cinsinden)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Kullanıcının belirli bir noktaya olan mesafesini hesapla
  double? getDistanceToPoint(double targetLat, double targetLon) {
    if (_lastPosition == null) return null;
    return calculateDistance(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      targetLat,
      targetLon,
    );
  }

  /// İki nokta arasındaki mesafeyi formatla (örn: "1.5 km", "250 m")
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Son bilinen konumu döndür
  Position? get lastPosition => _lastPosition;

  /// Kullanıcı belirli bir yarıçap içinde mi kontrol et
  bool isWithinRadius(double targetLat, double targetLon, double radiusMeters) {
    final distance = getDistanceToPoint(targetLat, targetLon);
    if (distance == null) return false;
    return distance <= radiusMeters;
  }
}
