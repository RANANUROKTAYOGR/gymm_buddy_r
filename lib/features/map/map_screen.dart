import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../data/database/database_helper.dart';
import '../../data/models.dart';
import '../../services/location_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/permission_helper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.userId});

  final int userId;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final LocationService _locationService = LocationService.instance;

  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<GymBranch> _gymBranches = [];
  Set<Marker> _markers = {};
  GymBranch? _nearestGym;
  StreamSubscription<Position>? _positionSubscription;
  Set<int> _notifiedGyms = {}; // Daha önce bildirim gösterilen salonlar
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Haritayı başlatır
  /// Konum izni kontrol eder, salonları yükler ve marker'ları oluşturur
  Future<void> _initializeMap() async {
    try {
      // Adım 1: Konum iznini kontrol et ve gerekirse iste
      final hasPermission = await PermissionHelper.requestLocationPermission(
        context,
      );

      if (!hasPermission) {
        // İzin verilmedi - kullanıcıya bilgi ver
        if (mounted) {
          ErrorHandler.showError(
            context,
            'İzin reddedildi',
            customMessage: 'Konum izni olmadan harita kullanılamaz.',
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Adım 2: Mevcut konumu al
      _currentPosition = await _locationService.getCurrentLocation();

      if (_currentPosition == null) {
        // Konum alınamadı - GPS kapalı olabilir
        if (mounted) {
          ErrorHandler.handleLocationError(context, 'GPS kapalı');
        }
        setState(() => _isLoading = false);
        return;
      }

      // Adım 3: Veritabanından salon bilgilerini yükle
      try {
        _gymBranches = await _db.getAllGymBranches();
      } catch (e) {
        debugPrint('❌ Salon yükleme hatası: $e');
        throw Exception('Salon bilgileri yüklenemedi');
      }

      // Adım 4: Harita marker'larını oluştur
      _createMarkers();

      // Adım 5: En yakın salonu hesapla
      _findNearestGym();

      // Adım 6: Gerçek zamanlı konum takibini başlat
      _startLocationTracking();

      // Başarılı - loading'i kapat
      setState(() => _isLoading = false);
    } catch (e) {
      // Beklenmeyen hata - kullanıcıya bildir
      debugPrint('❌ Harita başlatma hatası: $e');
      if (mounted) {
        ErrorHandler.showError(
          context,
          e,
          customMessage: 'Harita yüklenirken bir hata oluştu.',
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _createMarkers() {
    _markers.clear();

    // Kullanıcı konumu marker'ı
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Konumunuz'),
        ),
      );
    }

    // Salon marker'ları
    for (var gym in _gymBranches) {
      final isNearest = _nearestGym?.id == gym.id;
      _markers.add(
        Marker(
          markerId: MarkerId('gym_${gym.id}'),
          position: LatLng(gym.latitude, gym.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isNearest ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: gym.name,
            snippet: _getDistanceText(gym),
          ),
          onTap: () => _showGymDetails(gym),
        ),
      );
    }
  }

  String _getDistanceText(GymBranch gym) {
    if (_currentPosition == null) return 'Konum alınamadı';
    final distance = _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      gym.latitude,
      gym.longitude,
    );
    return _locationService.formatDistance(distance);
  }

  void _findNearestGym() {
    if (_currentPosition == null || _gymBranches.isEmpty) return;

    // Salonları uzaklığa göre sırala
    _gymBranches.sort((a, b) {
      final distanceA = _locationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = _locationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    // En yakın salon ilk sırada
    _nearestGym = _gymBranches.isNotEmpty ? _gymBranches.first : null;
  }

  /// Gerçek zamanlı konum takibini başlatır
  /// Kullanıcının konumu değiştikçe harita güncellenir
  void _startLocationTracking() {
    try {
      _positionSubscription = _locationService.getPositionStream().listen(
        (Position position) {
          // Konum güncellendi - state'i güncelle
          setState(() {
            _currentPosition = position;
            _createMarkers();
            _findNearestGym();
          });

          // Haritayı yeni konuma göre kaydır
          try {
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude),
              ),
            );
          } catch (e) {
            debugPrint('❌ Harita kamera güncelleme hatası: $e');
          }

          // Salona yakınlık kontrolü yap
          _checkProximityToGyms(position);
        },
        onError: (error) {
          // Konum stream hatası - kullanıcıya bildir
          debugPrint('❌ Konum stream hatası: $error');
          if (mounted) {
            ErrorHandler.handleLocationError(context, error);
          }
        },
      );
    } catch (e) {
      // Stream başlatma hatası
      debugPrint('❌ Konum takibi başlatma hatası: $e');
      if (mounted) {
        ErrorHandler.handleLocationError(context, e);
      }
    }
  }

  /// Kullanıcının salonlara yakınlığını kontrol eder
  /// 100m içinde otomatik antrenman başlatma önerir
  void _checkProximityToGyms(Position position) {
    try {
      for (var gym in _gymBranches) {
        // Salona olan mesafeyi hesapla
        final distance = _locationService.calculateDistance(
          position.latitude,
          position.longitude,
          gym.latitude,
          gym.longitude,
        );

        // 100 metre içindeyse ve daha önce bildirim gösterilmemişse
        if (distance <= 100 && !_notifiedGyms.contains(gym.id)) {
          _notifiedGyms.add(gym.id!);
          _showWorkoutStartDialog(gym);
        }

        // 200 metreden uzaklaştıysa bildirimi sıfırla
        if (distance > 200 && _notifiedGyms.contains(gym.id)) {
          _notifiedGyms.remove(gym.id);
        }
      }
    } catch (e) {
      // Mesafe hesaplama hatası
      debugPrint('❌ Yakınlık kontrolü hatası: $e');
    }
  }

  void _showWorkoutStartDialog(GymBranch gym) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${gym.name} - ${gym.address}'),
        backgroundColor: const Color(0xFF00FFA3),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showGymDetails(GymBranch gym) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F3A), Color(0xFF0A0E27)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gym.name,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _getDistanceText(gym),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withAlpha((0.6 * 255).toInt()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildDetailRow(
              Icons.location_on,
              gym.address ?? 'Adres Bilinmiyor',
            ),
            SizedBox(height: 12.h),
            _buildDetailRow(Icons.phone, gym.phone ?? 'Telefon Bilinmiyor'),
            SizedBox(height: 12.h),
            _buildDetailRow(
              Icons.access_time,
              '${gym.openingTime} - ${gym.closingTime}',
            ),
            if (gym.facilities != null && gym.facilities!.isNotEmpty) ...[
              SizedBox(height: 20.h),
              Text(
                'Olanaklar',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                gym.facilities!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withAlpha((0.7 * 255).toInt()),
                ),
              ),
            ],
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF00FFA3).withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFF00FFA3).withAlpha((0.3 * 255).toInt()),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF00FFA3),
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Salona giriş yapmak için ana ekrandaki QR butonu ile giriş QR kodunu okutun',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withAlpha((0.8 * 255).toInt()),
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

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00FFA3), size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  void _centerOnUserLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _centerOnNearestGym() {
    if (_nearestGym != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_nearestGym!.latitude, _nearestGym!.longitude),
            zoom: 16,
          ),
        ),
      );
      _showGymDetails(_nearestGym!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Harita
          _isLoading
              ? Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FFA3)),
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : const LatLng(41.0082, 28.9784), // İstanbul
                    zoom: 13,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

          // Üst bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha((0.7 * 255).toInt()),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8.h,
                left: 16.w,
                right: 16.w,
                bottom: 16.h,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.map_rounded,
                    color: const Color(0xFF00FFA3),
                    size: 28.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Spor Salonları',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF00FFA3,
                      ).withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: const Color(0xFF00FFA3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${_gymBranches.length} Salon',
                      style: TextStyle(
                        color: const Color(0xFF00FFA3),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Kontrol butonları
          Positioned(
            right: 16.w,
            bottom: 100.h,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'nearest',
                  onPressed: _centerOnNearestGym,
                  backgroundColor: const Color(0xFF00FFA3),
                  child: const Icon(Icons.near_me, color: Colors.white),
                ),
                SizedBox(height: 12.h),
                FloatingActionButton(
                  heroTag: 'location',
                  onPressed: _centerOnUserLocation,
                  backgroundColor: const Color(0xFFFF6B9D),
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            ),
          ),

          // En yakın salon bilgisi
          if (_nearestGym != null)
            Positioned(
              bottom: 16.h,
              left: 16.w,
              right: 90.w,
              child: GestureDetector(
                onTap: () => _showGymDetails(_nearestGym!),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1F3A), Color(0xFF0A0E27)],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFF00FFA3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF00FFA3,
                        ).withAlpha((0.3 * 255).toInt()),
                        blurRadius: 20.r,
                        offset: Offset(0, 5.h),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'En Yakın Salon',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF00FFA3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _nearestGym!.name,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _getDistanceText(_nearestGym!),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white.withAlpha(
                                  (0.6 * 255).toInt(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF00FFA3)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
