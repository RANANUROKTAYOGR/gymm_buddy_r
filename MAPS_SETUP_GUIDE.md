# 🗺️ Harita Modülü Kurulum Rehberi

## ✅ Tamamlanan Özellikler

### 1. **Paket Entegrasyonu**
- ✅ `google_maps_flutter: ^2.5.3` eklendi
- ✅ `geolocator: ^10.1.0` eklendi

### 2. **Konum İzinleri**

#### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### iOS (Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Konumunuz en yakın salonu göstermek için kullanılır.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Arka planda konum izni, salona yaklaştığınızda bildirim gösterilmesi için gereklidir.</string>
```

### 3. **Konum Servisi (LocationService)**
Lokasyon: `lib/services/location_service.dart`

**Özellikler:**
- ✅ Konum izinlerini kontrol etme ve isteme
- ✅ Anlık konum alma
- ✅ Konum değişikliklerini dinleme (her 10 metrede bir)
- ✅ İki nokta arası mesafe hesaplama
- ✅ Mesafe formatlama (m/km)
- ✅ Yarıçap içinde olup olmadığını kontrol etme

### 4. **Harita Ekranı (MapScreen)**
Lokasyon: `lib/features/map/map_screen.dart`

**Özellikler:**
- ✅ GYM_BRANCH tablosundaki tüm salonları marker olarak gösterme
- ✅ Kullanıcı konumunu mavi marker ile gösterme
- ✅ En yakın salonu yeşil marker ile öne çıkarma
- ✅ Diğer salonları kırmızı marker ile gösterme
- ✅ Her marker'da mesafe bilgisi
- ✅ Gerçek zamanlı konum takibi
- ✅ En yakın salon bilgi kartı (alt kısımda)

### 5. **100 Metre Yakınlık Kontrolü**
- ✅ Kullanıcı salona 100m yaklaştığında otomatik algılama
- ✅ SnackBar ile "Antrenman Oturumunu Başlatmak İster misin?" uyarısı
- ✅ Her salon için sadece bir kez bildirim gösterme
- ✅ 200m uzaklaşınca bildirimi sıfırlama
- ✅ Antrenman oturumu başlatma dialog'u

### 6. **Kullanıcı Arayüzü Özellikleri**
- ✅ Modern gradient tasarım
- ✅ Üst bar - toplam salon sayısı
- ✅ En yakın salon kartı (tıklanabilir)
- ✅ İki floating action button:
  - 🎯 En yakın salona odaklanma
  - 📍 Kullanıcı konumuna odaklanma
- ✅ Salon detay modal (tıklanınca açılır)
- ✅ Antrenman başlatma butonu

---

## 🔧 Kurulum Adımları

### 1. Google Maps API Key Almak

#### Android için:
1. [Google Cloud Console](https://console.cloud.google.com/) açın
2. Yeni proje oluşturun veya mevcut projeyi seçin
3. **APIs & Services > Library** bölümüne gidin
4. **Maps SDK for Android** arayın ve etkinleştirin
5. **APIs & Services > Credentials** bölümüne gidin
6. **CREATE CREDENTIALS > API Key** tıklayın
7. Oluşturulan API key'i kopyalayın
8. `android/app/src/main/res/values/strings.xml` dosyasında güncelleyin:

```xml
<string name="google_maps_api_key">BURAYA_API_KEY_YAPIŞTIRIN</string>
```

#### iOS için:
1. Yukarıdaki adımları tekrarlayın
2. **Maps SDK for iOS** da etkinleştirin
3. `ios/Runner/Info.plist` dosyasında güncelleyin:

```xml
<key>GMSApiKey</key>
<string>BURAYA_API_KEY_YAPIŞTIRIN</string>
```

### 2. Paketleri Yükleyin
```bash
flutter pub get
```

### 3. iOS için CocoaPods Güncelleyin
```bash
cd ios
pod install
cd ..
```

### 4. Uygulamayı Çalıştırın
```bash
flutter run
```

---

## 📱 Kullanım

### Harita Ekranına Gitme
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MapScreen(userId: currentUserId),
  ),
);
```

### Örnek GYM_BRANCH Verisi Ekleme
```dart
final gym = GymBranch(
  name: 'Gold\'s Gym Kadıköy',
  address: 'Caferağa Mahallesi, Moda Caddesi No:123',
  city: 'İstanbul',
  phone: '+90 216 555 1234',
  email: 'kadikoy@goldsgym.com.tr',
  latitude: 40.9876,
  longitude: 29.0234,
  openingTime: '06:00',
  closingTime: '23:00',
  facilities: 'Cardio, Kuvvet, Sauna, Duş',
  isActive: true,
  createdAt: DateTime.now(),
);

await DatabaseHelper.instance.createGymBranch(gym);
```

---

## 🎯 Özellik Açıklamaları

### En Yakın Salon Bulma
- Kullanıcının konumu her değiştiğinde otomatik hesaplanır
- Haversine formülü kullanılarak tam mesafe hesaplanır
- En yakın salon yeşil marker ile vurgulanır

### 100 Metre Yakınlık Uyarısı
```dart
// Otomatik çalışır, herhangi bir ek ayar gerekmez
// Kullanıcı salona 100m yaklaşınca:
// 1. SnackBar gösterilir
// 2. "Antrenmana Başla" butonu sunulur
// 3. Kullanıcı kabul ederse WorkoutSession oluşturulur
```

### Marker Renkleri
- 🔵 **Mavi**: Kullanıcı konumu
- 🟢 **Yeşil**: En yakın salon
- 🔴 **Kırmızı**: Diğer salonlar

---

## 🚨 Önemli Notlar

### 1. API Key Güvenliği
- **ÖNEMLİ**: API key'leri asla Git'e commit etmeyin
- `.gitignore` dosyasına ekleyin veya environment variables kullanın

### 2. Konum İzinleri
- Uygulama ilk açılışta kullanıcıdan konum izni isteyecek
- "Yalnızca uygulama kullanılırken" seçeneği yeterli
- iOS'ta "Her Zaman" seçeneği 100m kontrolünü daha güvenilir yapar

### 3. Gerçek Cihazda Test
- Konum özellikleri emülatörde düzgün çalışmayabilir
- Gerçek cihazda test yapmanız önerilir
- GPS açık olduğundan emin olun

### 4. Performans
- Konum güncellemeleri 10 metrede bir yapılır
- Daha sık güncellemeler pil tüketimini artırır
- Gerekirse `LocationSettings.distanceFilter` değerini ayarlayın

---

## 🔍 Sorun Giderme

### Harita Görünmüyor
1. API key'in doğru girildiğinden emin olun
2. Maps SDK'ların etkinleştirildiğini kontrol edin
3. Billing account'un aktif olduğunu doğrulayın

### Konum Alınamıyor
1. Cihazın GPS'inin açık olduğunu kontrol edin
2. Uygulama izinlerini kontrol edin
3. `flutter clean && flutter run` komutunu deneyin

### Marker'lar Görünmüyor
1. GYM_BRANCH tablosunda veri olduğunu kontrol edin
2. `latitude` ve `longitude` değerlerinin geçerli olduğunu doğrulayın
3. Console loglarını kontrol edin

---

## 📚 Ek Kaynaklar

- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Geolocator Plugin](https://pub.dev/packages/geolocator)
- [Google Maps Platform](https://developers.google.com/maps/documentation)

---

## ✨ Gelecek İyileştirmeler (Opsiyonel)

- [ ] Salon filtreleme (açık/kapalı, mesafe)
- [ ] Yol tarifi entegrasyonu
- [ ] Salon detaylarında resimler
- [ ] Salon yoğunluk bilgisi
- [ ] Favori salonlar
- [ ] Geçmiş ziyaretler
- [ ] Push notification ile arka plan bildirimleri
