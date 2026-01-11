# Error Handling Implementasyonu

Bu dokümantasyon, GYM_BUDDY_R uygulamasında uygulanan kapsamlı hata yönetimi sistemini açıklamaktadır.

## 📁 Yapı

```
lib/
├── utils/
│   ├── error_handler.dart       # Global hata yönetimi
│   └── permission_helper.dart   # İzin yönetimi ve dialogları
```

## 🎯 Ana Özellikler

### 1. Global Error Handler (`error_handler.dart`)

#### ErrorHandler Sınıfı

Tüm uygulama genelinde tutarlı hata mesajları gösterir.

**Metodlar:**

- `showError(context, error, {customMessage})`
  - Genel hata mesajları gösterir
  - Floating SnackBar ile şık görünüm
  - Console'a detaylı log yazdırır
  - Mounted kontrolü ile güvenli

- `showSuccess(context, message)`
  - Başarı mesajları gösterir
  - Aqua yeşil renkli SnackBar

- `handleDatabaseError(context, error)`
  - Veritabanı işlem hatalarını yakalar
  - "Veritabanı hatası oluştu" mesajı

- `handleCameraError(context, error)`
  - Kamera başlatma hatalarını yakalar
  - "Kamera başlatılamadı" mesajı

- `handleLocationError(context, error)`
  - Konum servisi hatalarını yakalar
  - "GPS'in açık olduğundan emin olun" mesajı

- `handleNetworkError(context, error)`
  - Ağ bağlantı hatalarını yakalar
  - "İnternet bağlantısı yok" mesajı

**Kullanım Örneği:**

```dart
try {
  await someAsyncOperation();
} catch (e) {
  ErrorHandler.showError(
    context,
    e,
    customMessage: 'İşlem başarısız oldu',
  );
}
```

### 2. Permission Helper (`permission_helper.dart`)

#### PermissionHelper Sınıfı

Kamera ve konum izinlerini yönetir, kullanıcıya açıklayıcı dialoglar gösterir.

**Metodlar:**

- `requestCameraPermission(context)` → `Future<bool>`
  - Kamera iznini kontrol eder ve ister
  - İzin reddedilirse açıklayıcı dialog gösterir
  - Kalıcı reddedilmişse ayarlara yönlendirir
  - Fayda listesi ile kullanıcıyı bilgilendirir

- `requestLocationPermission(context)` → `Future<bool>`
  - Konum iznini kontrol eder ve ister
  - İzin reddedilirse açıklayıcı dialog gösterir
  - Kalıcı reddedilmişse ayarlara yönlendirir
  - Fayda listesi ile kullanıcıyı bilgilendirir

**İzin Durumları:**

1. **isGranted**: İzin verilmiş → `true` döner
2. **isDenied**: İlk kez reddedilmiş → Açıklama dialogu gösterir
3. **isPermanentlyDenied**: Kalıcı reddedilmiş → Ayarlara yönlendirir

**Dialog Tipleri:**

#### İzin Açıklama Dialogu (_showPermissionRationaleDialog)

- Modern dark theme tasarım
- İznin neden gerekli olduğunu açıklar
- Faydaları madde madde listeler
- İptal ve İzin Ver butonları

#### İzin Reddedildi Dialogu (_showPermissionDeniedDialog)

- Kalıcı red durumunda gösterilir
- Ayarlara yönlendirme butonu
- Adım adım rehberlik

**Kullanım Örneği:**

```dart
// Kamera izni iste
final hasCameraPermission = 
    await PermissionHelper.requestCameraPermission(context);

if (hasCameraPermission) {
  // Kamerayı başlat
} else {
  // İzin verilmedi
}
```

## 🔧 Entegrasyon Detayları

### ProgressTrackingScreen Entegrasyonu

**_loadMeasurements() Metodu:**
```dart
/// Kullanıcının vücut ölçümlerini veritabanından yükler
/// Try-catch ile veritabanı hatalarını yakalar
Future<void> _loadMeasurements() async {
  try {
    setState(() => _isLoading = true);
    
    // Veritabanından ölçümleri getir
    final measurements = await _dbHelper.getBodyMeasurementsByUser(
      widget.userId,
    );
    
    // Başarılı - state'i güncelle
    if (mounted) {
      setState(() {
        _measurements = measurements;
        _isLoading = false;
      });
    }
  } catch (e) {
    // Hata durumunda loading'i kapat ve kullanıcıya bildir
    if (mounted) {
      setState(() => _isLoading = false);
      ErrorHandler.handleDatabaseError(context, e);
    }
  }
}
```

**_navigateToCamera() Metodu:**
```dart
/// Kamera ekranına yönlendirir
/// Önce izin kontrolü yapar, sonra kamera listesini alır
void _navigateToCamera() async {
  try {
    // Adım 1: Kamera iznini kontrol et ve gerekirse iste
    final hasPermission = 
        await PermissionHelper.requestCameraPermission(context);
    
    if (!hasPermission) {
      // İzin verilmedi - kullanıcıya bilgi ver
      if (mounted) {
        ErrorHandler.showError(
          context,
          'İzin reddedildi',
          customMessage: 'Kamera izni olmadan fotoğraf çekilemez.',
        );
      }
      return;
    }

    // Adım 2: Kullanılabilir kameraları listele
    final cameras = await availableCameras();
    
    // Kamera bulunamadı kontrolü
    if (cameras.isEmpty) {
      if (mounted) {
        ErrorHandler.showError(
          context,
          'Kamera yok',
          customMessage: 'Cihazınızda kullanılabilir kamera bulunamadı.',
        );
      }
      return;
    }

    // Adım 3: Kamera ekranına git
    // ...
  } catch (e) {
    // Beklenmeyen kamera hatalarını yakala
    if (mounted) {
      ErrorHandler.handleCameraError(context, e);
    }
  }
}
```

**CameraCapturePage - _initializeCamera() Metodu:**
```dart
/// Kamerayı başlatır
/// Try-catch ile başlatma hatalarını yakalar
void _initializeCamera() {
  try {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  } catch (e) {
    debugPrint('❌ Kamera başlatma hatası: $e');
    // Hata durumunda kullanıcıya bildir
    if (mounted) {
      ErrorHandler.handleCameraError(context, e);
    }
  }
}
```

**PhotoPreviewPage - _saveProgress() Metodu:**
```dart
/// Fotoğrafı ve ölçüm verilerini kaydeder
/// Try-catch ile dosya işlemleri ve veritabanı hatalarını yakalar
Future<void> _saveProgress() async {
  try {
    // Adım 1: Uygulama dizinini al
    final appDir = await getApplicationDocumentsDirectory();
    
    // Adım 2: Fotoğrafı kalıcı konuma kopyala
    try {
      await File(widget.imagePath).copy(savedPath);
    } catch (e) {
      debugPrint('❌ Dosya kopyalama hatası: $e');
      throw Exception('Fotoğraf kaydedilemedi');
    }
    
    // Adım 3-5: BMI hesaplama ve veritabanı kayıt
    // ...
    
    // Başarılı - kullanıcıya bildir
    ErrorHandler.showSuccess(
      context,
      'Gelişim kaydı başarıyla kaydedildi!',
    );
  } catch (e) {
    // Hata durumunda kullanıcıya bildir
    debugPrint('❌ Progress kaydetme hatası: $e');
    if (mounted) {
      ErrorHandler.handleDatabaseError(context, e);
    }
  }
}
```

### MapScreen Entegrasyonu

**_initializeMap() Metodu:**
```dart
/// Haritayı başlatır
/// Konum izni kontrol eder, salonları yükler ve marker'ları oluşturur
Future<void> _initializeMap() async {
  try {
    // Adım 1: Konum iznini kontrol et ve gerekirse iste
    final hasPermission = 
        await PermissionHelper.requestLocationPermission(context);
    
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

    // Adım 4-6: Marker oluşturma, mesafe hesaplama, tracking
    // ...
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
  }
}
```

**_startLocationTracking() Metodu:**
```dart
/// Gerçek zamanlı konum takibini başlatır
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

        // Salona yakınlık kontrolü
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
```

## 📝 Önemli Notlar

### 1. Mounted Kontrolü
Her kullanıcı etkileşiminden önce `if (mounted)` kontrolü yapılır:
```dart
if (mounted) {
  ErrorHandler.showError(context, e);
}
```

### 2. Debug Logging
Her hata durumunda console'a log yazdırılır:
```dart
debugPrint('❌ Kamera başlatma hatası: $e');
```

### 3. Try-Catch Katmanları
İç içe try-catch blokları ile granüler hata yönetimi:
```dart
try {
  // Dış işlem
  try {
    // İç işlem
  } catch (innerError) {
    // İç hata yakalama
  }
} catch (outerError) {
  // Dış hata yakalama
}
```

### 4. Kullanıcı Dostu Mesajlar
Teknik hatalar yerine anlaşılır mesajlar:
- ❌ `"Camera initialization failed: PlatformException"`
- ✅ `"Kamera başlatılamadı. Lütfen kamera iznini kontrol edin."`

### 5. İzin Dialog Tasarımı
- Modern dark theme
- Gradient butonlar
- İkon ve renklerle görsel zenginlik
- Açıklayıcı ve ikna edici metinler

## 🎨 UI/UX Özellikleri

### SnackBar Tasarımı
- Floating behavior
- Rounded corners (12px)
- Gradient background
- Icon + Text kombinasyonu
- Action button ("KAPAT")

### Dialog Tasarımı
- Dark background (#1A1F3A)
- Gradient borders
- Icon container with gradient
- Benefit listesi (bullet points)
- İki aksiyonlu butonlar (İptal / İzin Ver)

## 🚀 Performans

- Asenkron işlemler non-blocking
- Stream'lerde error handler
- Dispose metodlarında güvenli cleanup
- Memory leak önleme

## ✅ Test Senaryoları

1. **Kamera izni reddedildiğinde:**
   - Dialog gösterilir
   - Kullanıcı bilgilendirilir
   - Ayarlara yönlendirme seçeneği

2. **GPS kapalıyken:**
   - Hata mesajı gösterilir
   - GPS açma önerisi

3. **Veritabanı hatası:**
   - Kullanıcı dostu mesaj
   - Console'da detaylı log

4. **Kamera bulunamadığında:**
   - Cihaz uyumsuzluğu mesajı

5. **Network hatası:**
   - Bağlantı kontrolü önerisi

## 📦 Bağımlılıklar

```yaml
dependencies:
  permission_handler: ^11.1.0
  camera: ^0.10.5+5
  geolocator: ^10.1.0
```

## 🎯 Sonuç

Bu implementasyon sayesinde:
- ✅ Uygulama asla çökmez
- ✅ Kullanıcı her zaman bilgilendirilir
- ✅ Hatalar tutarlı şekilde yönetilir
- ✅ Debug işlemleri kolaydır
- ✅ Kod okunabilirliği yüksektir
- ✅ Bakım maliyeti düşüktür
