# GYM BUDDY R - PROJE RAPORU

**Proje Adı:** GYM BUDDY R - Akıllı Spor Salonu Yönetim Uygulaması  
**Geliştirici:** RANA NUR OKTAYOĞLU  
**Tarih:** Ocak 2026  
**Platform:** Flutter (Dart)  
**Versiyon:** 1.0.0  
**GitHub Repository:** https://github.com/RANANUROKTAYOGR/gymm_buddy_r.git

---

## 1. GİRİŞ

Bu rapor, Flutter framework'ü kullanarak geliştirdiğim GYM BUDDY R mobil uygulamasının teknik detaylarını, özelliklerini ve geliştirme sürecini kapsamaktadır. Proje, spor salonu kullanıcılarının fitness hedeflerini takip etmelerini, antrenman programlarını yönetmelerini ve spor salonu deneyimlerini dijitalleştirmelerini sağlayan kapsamlı bir mobil çözüm sunmaktadır.

## 2. PROJE AMACI VE KAPSAMI

### 2.1. Projenin Amacı

GYM BUDDY R projesini geliştirmemdeki temel amaç, spor salonu kullanıcılarının fitness yolculuklarını daha verimli ve keyifli hale getirmek için dijital bir asistan oluşturmaktı. Günümüzde fitness sektöründe dijitalleşme ihtiyacını göz önünde bulundurarak, kullanıcıların antrenman takibinden beslenme planlamasına, vücut ölçümlerinden spor salonu check-in'ine kadar birçok işlemi tek bir uygulama üzerinden yapabilmesini hedefledim.

### 2.2. Hedef Kitle

- Düzenli spor salonu kullanan bireyler
- Fitness hedefleri olan kullanıcılar
- Kişisel antrenörler ve spor uzmanları
- Spor salonu işletmeleri
- Sağlıklı yaşam tarzı benimseyen kişiler

### 2.3. Problemin Tanımı

Geleneksel spor salonu deneyiminde kullanıcılar şu sorunlarla karşılaşmaktadır:
- Antrenman kayıtlarının kağıt üzerinde tutulması
- İlerlemenin düzenli takip edilememesi
- Egzersiz tekniklerinin unutulması
- Beslenme ve antrenman planlarının karmaşık yönetimi
- Spor salonu ekipmanları hakkında yeterli bilgiye erişilememesi

Bu problemlere çözüm olarak GYM BUDDY R'ı geliştirdim.

## 3. TEKNİK ALTYAPI VE MİMARİ

### 3.1. Kullandığım Teknolojiler

#### Framework ve Programlama Dili
- **Flutter SDK 3.9.2**: Cross-platform uygulama geliştirmek için tercih ettim
- **Dart**: Flutter'ın resmi programlama dili
- **Material Design**: Modern ve kullanıcı dostu arayüz tasarımı için

#### Veritabanı Yönetimi
- **SQLite (Sqflite 2.4.2)**: Yerel veri depolama için tercih ettim
- 10 tablolu ilişkisel veritabanı mimarisi tasarladım
- Foreign key ilişkileri ile veri bütünlüğünü sağladım

#### Haritalama ve Konum Servisleri
- **Google Maps Flutter 2.5.3**: Spor salonu lokasyonlarını göstermek için
- **Geolocator 10.1.0**: GPS tabanlı konum takibi için
- **Permission Handler**: Konum izinlerini yönetmek için

#### Kamera ve Tarayıcı Özellikleri
- **Mobile Scanner**: QR kod okuma işlemleri için
- **Camera**: Vücut ölçüm fotoğrafları çekmek için

#### Veri Görselleştirme
- **FL Chart 0.65.0**: İnteraktif grafikler ve ilerleme çizelgeleri için
- **Printing**: PDF rapor oluşturma için

#### Bildirim ve Zamanlama
- **Flutter Local Notifications**: Kullanıcı hatırlatıcıları için
- **Device Calendar**: Takvim entegrasyonu için

#### Sensör ve Aktivite Takibi
- **Pedometer**: Adım sayma özelliği için
- **Sensors Plus**: Cihaz sensörlerinden veri almak için

#### Yardımcı Paketler
- **Intl 0.18.1**: Tarih ve sayı formatlaması için
- **Path Provider**: Dosya sistemi erişimi için
- **URL Launcher**: Harici bağlantıları açmak için
- **Shared Preferences**: Kullanıcı ayarlarını saklamak için

### 3.2. Mimari Tasarım

Projemi Clean Architecture prensiplerine uygun olarak geliştirdim:

```
lib/
├── main.dart               # Uygulama başlangıç noktası
├── splash_screen.dart      # Açılış ekranı
├── data/                   # Veri katmanı
│   ├── models/            # 15+ veri modeli
│   ├── database/          # SQLite yönetimi
│   └── seed_data.dart     # Örnek veriler
├── features/              # Özellik bazlı modüller
│   ├── dashboard/         # Ana ekran ve istatistikler
│   ├── exercise/          # Egzersiz kütüphanesi
│   ├── workout/           # Antrenman yönetimi
│   ├── scanner/           # QR tarama özellikleri
│   ├── map/               # Harita entegrasyonu
│   ├── diet/              # Beslenme planları
│   ├── progress/          # İlerleme takibi
│   ├── profile/           # Kullanıcı profili
│   ├── appointments/      # Randevu sistemi
│   ├── trainers/          # Antrenör listesi
│   └── group_classes/     # Grup dersleri
├── services/              # İş mantığı katmanı
│   ├── notification_service.dart
│   ├── location_service.dart
│   ├── step_counter_service.dart
│   ├── hydration_service.dart
│   ├── theme_service.dart
│   └── report_service.dart
└── utils/                 # Yardımcı araçlar
    ├── error_handler.dart
    ├── permission_helper.dart
    └── one_rep_max_calculator.dart
```

### 3.3. Veritabanı Şeması

Uygulamada 10 ana tablo tasarladım:

1. **USER**: Kullanıcı hesap bilgileri
2. **GYM_BRANCH**: Spor salonu şube bilgileri
3. **EQUIPMENT**: Ekipman kataloğu
4. **EXERCISE**: 300+ egzersiz veritabanı
5. **WORKOUT_SESSION**: Antrenman seansı kayıtları
6. **EXERCISE_LOG**: Egzersiz detay kayıtları
7. **SET_DETAILS**: Set, tekrar ve ağırlık bilgileri
8. **BODY_MEASUREMENTS**: Vücut ölçümleri geçmişi
9. **DIET_PLAN**: Beslenme programları
10. **USER_GOALS**: Kullanıcı hedefleri

Her tablo arasında uygun foreign key ilişkileri kurdum ve veri bütünlüğünü sağladım.

## 4. UYGULAMA ÖZELLİKLERİ

### 4.1. Egzersiz Kütüphanesi ve Antrenman Yönetimi

Uygulamanın en kapsamlı modüllerinden birini geliştirdim:

- **300+ Egzersiz Veritabanı**: Her egzersiz için detaylı açıklama, görseller ve adım adım talimatlar ekledim
- **Kas Grubu Filtreleme**: Göğüs, sırt, bacak, omuz, kol, karın gibi gruplar için filtreleme sistemi
- **Egzersiz Detay Sayfası**: Her egzersiz için başlangıç ve bitiş pozisyonlarını gösteren görsel rehber
- **Set ve Tekrar Takibi**: Kullanıcıların her sette yaptıkları tekrar sayısını ve kaldırdıkları ağırlığı kaydetmesini sağladım
- **Antrenman Geçmişi**: Geçmiş antrenmanları tarih bazlı görüntüleme
- **1RM Hesaplayıcı**: One Rep Max hesaplama algoritması geliştirdim

**Teknik Detaylar:**
- Exercise modelinde exerciseImages ilişkisi ile çoklu görsel desteği
- SQLite JOIN işlemleri ile performanslı veri çekme
- Future ve async/await kullanarak responsive UI

### 4.2. QR Kod Sistemi ve Tarayıcı Modülü

Uygulamaya üç farklı QR tarama özelliği ekledim:

**Spor Salonu Check-in:**
- Giriş ve çıkış için QR kod okuma
- Otomatik zaman damgası
- Günlük spor salonu kullanım istatistikleri

**Ekipman Bilgi Sistemi:**
- Her ekipman için benzersiz QR kod
- Makine kullanım talimatları
- Egzersiz videoları ve açıklamaları
- Güvenlik uyarıları

**Vücut Ölçümü:**
- Fotoğraf çekme ve kaydetme
- Geçmiş ölçümlerle karşılaştırma
- İlerleme fotoğrafları galerisi

**Teknik Detaylar:**
- Mobile Scanner paketi ile hızlı QR okuma
- Camera plugin ile fotoğraf çekme
- Path Provider ile local storage yönetimi

### 4.3. Akıllı Dashboard ve Aktivite Takibi

Ana ekrana kullanıcı için değerli bilgiler sunan bir dashboard geliştirdim:

**Günlük Aktivite:**
- Adım sayacı (Pedometer entegrasyonu)
- Kalori hesaplama
- Aktif dakika takibi
- Hareket hedefleri

**Su Tüketimi Takibi:**
- Günlük su içme hedefi
- Su içme hatırlatıcıları
- Görsel progress bar
- Haftalık istatistikler

**Hızlı İstatistikler:**
- Bu hafta yapılan antrenman sayısı
- Toplam kaldırılan ağırlık
- Hedeflere ulaşım oranı
- Başarım rozetleri

**Detaylı Raporlar:**
- Aylık ilerleme grafikleri
- PDF export özelliği
- Paylaşılabilir raporlar
- Karşılaştırmalı analizler

**Teknik Detaylar:**
- FL Chart ile interaktif grafikler
- Stream controller ile real-time updates
- Background service ile adım sayımı
- Local notifications ile hatırlatıcılar

### 4.4. Harita ve Lokasyon Özellikleri

Google Maps API'yi entegre ederek lokasyon tabanlı özellikler ekledim:

**Yakındaki Spor Salonları:**
- Kullanıcının konumuna göre en yakın salonlar
- Harita üzerinde marker'lar
- Mesafe ve yol tarifi
- Şube detayları ve iletişim bilgileri

**Check-in Sistemi:**
- Lokasyon bazlı otomatik check-in
- Geofencing teknolojisi
- Check-in geçmişi

**Şube Bilgileri:**
- Çalışma saatleri
- Telefon ve email
- Yol tarifi butonu
- Şube fotoğrafları

**Teknik Detaylar:**
- Google Maps Flutter plugin
- Geolocator ile GPS koordinatları
- Permission Handler ile runtime izinler
- Custom map markers

### 4.5. Beslenme Planı Yönetimi

Kullanıcıların beslenme hedeflerini takip etmesi için bir modül geliştirdim:

- Günlük kalori hedefi belirleme
- Öğün planlaması (sabah, öğle, akşam, atıştırmalık)
- Makro besin ögesi dağılımı (protein, karbonhidrat, yağ)
- Besin listesi ve kalori değerleri
- Günlük besin kaydı
- Haftalık beslenme raporu

**Teknik Detaylar:**
- DietPlan ve UserDiet modelleri
- İlişkisel veritabanı yapısı
- Circular progress indicators
- Tarih bazlı filtreleme

### 4.6. Gamifikasyon ve Motivasyon Sistemi

Kullanıcı motivasyonunu artırmak için gamifikasyon öğeleri ekledim:

**Rozet Sistemi:**
- İlk antrenman rozeti
- Süreklilik rozetleri (7, 30, 100 gün)
- Kilo kaybı rozetleri
- Özel başarımlar

**Hedef Takibi:**
- Kısa vadeli hedefler
- Uzun vadeli hedefler
- Hedef tamamlanma oranları
- Bildirimler ve kutlamalar

**İstatistikler:**
- Toplam antrenman sayısı
- Toplam kaldırılan ağırlık
- En uzun seri
- Kişisel rekorlar

### 4.7. Vücut Ölçümleri ve İlerleme Takibi

Fiziksel gelişimi takip etmek için detaylı bir ölçüm sistemi oluşturdum:

**Ölçüm Tipleri:**
- Kilo
- Boy
- Vücut yağ oranı
- Kas kütlesi
- Göğüs, bel, kalça, kol, bacak çevresi

**Görselleştirme:**
- Zaman bazlı grafik gösterimleri
- Öncesi/sonrası karşılaştırmaları
- İlerleme fotoğrafları
- Trend analizleri

**Teknik Detaylar:**
- BodyMeasurements modeli
- FL Chart ile line chart'lar
- Image picker ile fotoğraf seçimi
- Local storage ile fotoğraf saklama

### 4.8. Randevu ve Takvim Sistemi

Spor salonu ile etkileşimi kolaylaştırmak için randevu sistemi ekledim:

**Antrenör Randevuları:**
- Müsait antrenör listesi
- Randevu oluşturma
- Randevu iptali ve düzenleme
- Hatırlatıcı bildirimleri

**Grup Dersleri:**
- Ders programı
- Kayıt sistemi
- Kapasite takibi
- Takvim entegrasyonu

**Teknik Detaylar:**
- Device Calendar plugin
- Local Notifications
- DateTime yönetimi
- Trainer ve Appointment modelleri

### 4.9. Profil ve Ayarlar

Kullanıcı deneyimini kişiselleştirmek için kapsamlı bir profil sistemi:

**Kullanıcı Bilgileri:**
- Kişisel bilgiler
- Fitness hedefleri
- Deneyim seviyesi
- Sağlık bilgileri

**Tema ve Görünüm:**
- Açık/Koyu tema geçişi
- Renk şeması seçenekleri
- Font boyutu ayarları

**Bildirim Ayarları:**
- Hatırlatıcılar
- Başarım bildirimleri
- Sessiz saatler

## 5. GELİŞTİRME SÜRECİ VE YAŞADIĞIM ZORLUKLAR

### 5.1. Geliştirme Aşamaları

1. **Planlama ve Analiz** (1 hafta)
   - Kullanıcı ihtiyaçlarını belirleme
   - Özellik listesi oluşturma
   - Veritabanı şemasını tasarlama

2. **Temel Altyapı** (1 hafta)
   - Flutter projesini kurma
   - Veritabanı implementasyonu
   - Model sınıflarını oluşturma

3. **UI/UX Tasarımı** (2 hafta)
   - Ekran tasarımları
   - Navigasyon yapısı
   - Widget componentleri

4. **Özellik Geliştirme** (4 hafta)
   - Her modülü ayrı ayrı geliştirme
   - Test etme ve hata düzeltme
   - Optimizasyon

5. **Entegrasyonlar** (1 hafta)
   - Google Maps
   - QR Scanner
   - Bildirimler

6. **Test ve Düzeltme** (1 hafta)
   - Kapsamlı testler
   - Bug fixing
   - Performance optimization

### 5.2. Karşılaştığım Teknik Zorluklar ve Çözümler

**1. SQLite İlişkisel Sorgular:**
- **Sorun**: Karmaşık JOIN işlemlerinde performans sorunları
- **Çözüm**: Raw SQL sorguları ve indexleme kullanarak optimize ettim

**2. Google Maps API Anahtarı:**
- **Sorun**: Android ve iOS için farklı konfigürasyonlar
- **Çözüm**: Platform bazlı ayarları detaylı dokümante ettim (MAPS_SETUP_GUIDE.md)

**3. Background Services:**
- **Sorun**: Adım sayacının arka planda çalışması
- **Çözüm**: Platform-specific implementasyon ve battery optimization

**4. Permission Handling:**
- **Sorun**: Runtime permission'ları yönetmek
- **Çözüm**: PermissionHelper utility sınıfı oluşturdum

**5. State Management:**
- **Sorun**: Karmaşık state yönetimi
- **Çözüm**: StatefulWidget ve setState kullanarak basit tutma

**6. Image Storage:**
- **Sorun**: Vücut ölçüm fotoğraflarının yönetimi
- **Çözüm**: Path Provider ile local storage ve veritabanında path saklama

### 5.3. Öğrendiğim Yeni Teknolojiler

Bu proje boyunca:
- Flutter framework'ünü derinlemesine öğrendim
- SQLite ve ilişkisel veritabanı yönetimi
- Google Maps API entegrasyonu
- QR kod teknolojisi
- Chart ve grafik kütüphaneleri
- Background service implementation
- Permission handling best practices
- Clean Architecture prensipleri

## 6. KOD KALİTESİ VE EN İYİ UYGULAMALAR

### 6.1. Uyguladığım Prensipler

**Clean Code:**
- Anlamlı değişken ve fonksiyon isimleri
- Yorum satırları ile dokümantasyon
- DRY (Don't Repeat Yourself) prensibi
- Single Responsibility Principle

**Error Handling:**
- Try-catch blokları
- User-friendly hata mesajları
- Merkezi error handler
- Logging sistemi

**Code Organization:**
- Feature-based klasör yapısı
- Separation of Concerns
- Reusable widget'lar
- Utility fonksiyonları

### 6.2. Dokümantasyon

Proje için kapsamlı dokümantasyon hazırladım:
- DATABASE_ARCHITECTURE.md
- DATABASE_SCHEMA.md
- MAPS_SETUP_GUIDE.md
- MAP_QUICK_START.md
- ERROR_HANDLING.md
- SCANNER_FEATURES.md
- README.md

## 7. TEST VE KALİTE GÜVENCESİ

### 7.1. Test Stratejim

**Manuel Testler:**
- Her özelliği farklı cihazlarda test ettim
- Android ve iOS platformlarında çalıştırdım
- Edge case'leri kontrol ettim
- User flow'ları doğruladım

**Widget Testleri:**
- Temel widget testleri oluşturdum (test/widget_test.dart)
- UI component'lerini test ettim

**Performans Testi:**
- Büyük veri setleri ile test
- Memory leak kontrolü
- Battery consumption analizi
- App size optimization

### 7.2. Karşılaşılan Buglar ve Çözümler

1. **Veritabanı migrasyon sorunları** → Version kontrolü ile çözüldü
2. **Map marker'ların gösterilmemesi** → Asset path düzeltmeleri
3. **QR scanner permission redirection** → Permission helper iyileştirmesi
4. **Chart rendering gecikmeleri** → Data pagination
5. **Image loading slowness** → Caching mekanizması

## 8. PROJE ÇIKTILARI VE BAŞARILAR

### 8.1. Ulaştığım Hedefler

✅ Cross-platform (Android, iOS, Web) uygulama geliştirdim  
✅ 11 ana modül ve 15+ alt özellik implementasyonu  
✅ 300+ egzersiz içeren kapsamlı veritabanı  
✅ Kullanıcı dostu ve modern arayüz tasarımı  
✅ Offline çalışabilen robust bir uygulama  
✅ Detaylı dokümantasyon ve kod organizasyonu  
✅ Gerçek zamanlı aktivite takibi  
✅ Gamifikasyon ve motivasyon sistemi  

### 8.2. Teknik Başarılar

- **10 tabloluk** ilişkisel veritabanı mimarisi
- **238 dosya** ve **32,000+ satır** kod
- **20+ third-party paket** entegrasyonu
- **Modüler ve ölçeklenebilir** mimari
- **Clean Architecture** prensipleri
- **Responsive** tasarım

## 9. GELECEK GELİŞTİRMELER VE İYİLEŞTİRMELER

### 9.1. Kısa Vadeli Planlarım

- 🔐 Kullanıcı kimlik doğrulama sistemi
- ☁️ Firebase entegrasyonu ve cloud sync
- 📱 Push notification sistemi
- 🎨 Daha fazla tema seçeneği
- 🌍 Çoklu dil desteği

### 9.2. Uzun Vadeli Vizyonum

- 🤖 AI destekli antrenman önerileri
- 🎥 Video tabanlı egzersiz kılavuzları
- 👥 Sosyal özellikler ve arkadaş sistemi
- 📊 Advanced analytics ve machine learning
- ⌚ Akıllı saat entegrasyonu
- 🏆 Leaderboard ve challenge sistemi
- 💳 In-app purchase ve premium özellikler

## 10. SONUÇ VE DEĞERLENDİRME

### 10.1. Proje Değerlendirmesi

GYM BUDDY R projesini geliştirmek benim için çok değerli bir öğrenme deneyimi oldu. Flutter framework'ünü öğrenirken, aynı zamanda gerçek dünya problemlerine çözüm üreten bir uygulama geliştirdim. Proje boyunca:

- **Teknik Yetkinlik:** Flutter, Dart, SQLite ve birçok API ile çalışmayı öğrendim
- **Problem Çözme:** Karşılaştığım teknik zorlukları araştırarak ve deneyerek çözdüm
- **Proje Yönetimi:** Büyük bir projeyi modüler parçalara bölerek yönettim
- **Clean Code:** Okunabilir, sürdürülebilir kod yazmayı deneyimledim
- **Kullanıcı Deneyimi:** UX/UI prensiplerini uygulamalı olarak öğrendim

### 10.2. Öğrendiklerim ve Kazanımlarım

**Teknik Kazanımlar:**
- Cross-platform mobil uygulama geliştirme
- Veritabanı tasarımı ve yönetimi
- API entegrasyonları
- State management
- Asynchronous programming
- Third-party package kullanımı

**Soft Skills:**
- Zaman yönetimi
- Problem analizi
- Dokümantasyon yazımı
- Araştırma yetenekleri
- Detaya özen

### 10.3. Uygulamanın Potansiyeli

GYM BUDDY R, sadece bir okul projesi olmanın ötesinde, gerçek kullanıcılara değer sağlayabilecek bir ürün potansiyeline sahiptir. Spor salonları için bir B2B çözüm ya da bireysel kullanıcılar için bir B2C uygulama olarak piyasaya sürülebilir. 

**Kullanım Alanları:**
- 🏋️ Spor salonları için üye yönetim sistemi
- 👤 Bireysel fitness takip uygulaması
- 💪 Kişisel antrenörler için müşteri takip aracı
- 📊 Kurumsal wellness programları
- 🏢 Şirket içi sağlık ve fitness uygulaması

### 10.4. Son Sözler

Bu projeyi geliştirirken en çok keyif aldığım şey, her gün yeni bir şey öğrenmek ve uygulama üzerinde somut gelişmeler görmek oldu. Her özelliği tamamladığımda kullanıcıların hayatlarını nasıl kolaylaştıracağını düşündüm. 

GYM BUDDY R sadece bir mobil uygulama değil, sağlıklı yaşam tarzını destekleyen dijital bir arkadaş olma amacını taşıyor. Gelecekte bu projeyi daha da geliştirerek gerçek kullanıcılara ulaştırmayı hedefliyorum.

---

## EKLER

### A. Proje İstatistikleri

- **Toplam Dosya Sayısı:** 238
- **Toplam Satır Sayısı:** ~32,000+
- **Dart Dosyaları:** 50+
- **Asset Dosyaları:** 30+
- **Veritabanı Tabloları:** 10
- **Veri Modeli:** 15+
- **Servis Sınıfı:** 8+
- **Özellik Modülü:** 11
- **Third-party Paket:** 20+

### B. Kullanılan Paketlerin Tam Listesi

```yaml
dependencies:
  - sqflite: ^2.4.2          # Veritabanı
  - google_maps_flutter: ^2.5.3  # Harita
  - geolocator: ^10.1.0      # Konum
  - fl_chart: ^0.65.0        # Grafikler
  - mobile_scanner: ^3.5.2   # QR Scanner
  - camera: ^0.10.5          # Kamera
  - pedometer: ^4.0.1        # Adım Sayacı
  - flutter_local_notifications: ^16.2.0  # Bildirimler
  - device_calendar: ^4.3.2  # Takvim
  - printing: ^5.11.0        # PDF
  - permission_handler: ^11.0.1  # İzinler
  - path_provider: ^2.1.1    # Dosya Sistemi
  - shared_preferences: ^2.2.2  # Local Storage
  - intl: ^0.18.1            # Tarih/Format
  - url_launcher: ^6.2.1     # URL
  - sensors_plus: ^3.1.0     # Sensörler
```

### C. Ekran Görüntüleri ve Diyagramlar

*(Proje sunumunda ekran görüntüleri ve akış diyagramları eklenecektir)*

### D. Veritabanı ER Diyagramı

*(Detaylı ER diyagramı DATABASE_ARCHITECTURE.md dosyasında mevcuttur)*

### E. Git Commit Geçmişi

- **Initial commit:** 238 dosya, 32,102 satır ekleme
- **Repository:** https://github.com/RANANUROKTAYOGR/gymm_buddy_r.git

---

**Rapor Hazırlayan:** RANA NUR OKTAYOĞLU  
**Tarih:** 11 Ocak 2026  
**İletişim:** [GitHub - RANANUROKTAYOGR](https://github.com/RANANUROKTAYOGR)

---

> *"Code is like humor. When you have to explain it, it's bad."* – Cory House

Bu proje, teknik becerilerimi geliştirirken, aynı zamanda gerçek dünya problemlerine çözüm üretmenin ne kadar tatmin edici olduğunu gösterdi. GYM BUDDY R ile insanların fitness hedeflerine ulaşmalarına yardımcı olmayı umuyorum.
