import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// İzin yönetimi yardımcı sınıfı
/// Kamera ve konum izinlerini yönetir ve kullanıcıya açıklayıcı dialoglar gösterir
class PermissionHelper {
  /// Kamera izni ister
  /// Eğer izin verilmezse kullanıcıya neden gerekli olduğunu açıklayan dialog gösterir
  /// context BuildContext - Dialogun gösterileceği context
  /// Returns: Future<bool> - İzin verildi mi?
  static Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      // Mevcut izin durumunu kontrol et
      final status = await Permission.camera.status;

      debugPrint('📸 Kamera izin durumu: $status');

      // Eğer izin zaten verilmişse true döndür
      if (status.isGranted) {
        return true;
      }

      // Eğer kalıcı olarak reddedilmişse ayarlara yönlendir
      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          await _showPermissionDeniedDialog(
            context,
            title: 'Kamera İzni Gerekli',
            message:
                'İlerleme fotoğrafları çekmek için kamera iznine ihtiyacımız var. '
                'Lütfen uygulama ayarlarından kamera iznini aktif edin.',
            icon: Icons.camera_alt,
            onSettingsPressed: () async {
              // Kullanıcıyı uygulama ayarlarına yönlendir
              await openAppSettings();
            },
          );
        }
        return false;
      }

      // İzin daha önce reddedilmişse açıklama göster
      if (status.isDenied) {
        if (context.mounted) {
          final shouldRequest = await _showPermissionRationaleDialog(
            context,
            title: 'Kamera İzni Gerekli',
            message:
                'Gelişim fotoğraflarınızı çekip karşılaştırabilmeniz için '
                'kamera erişimine ihtiyacımız var. Bu, ilerlemenizi görsel olarak '
                'takip etmenizi sağlar.',
            icon: Icons.camera_alt,
            benefits: [
              'İlerleme fotoğrafları çekin',
              'Öncesi/sonrası karşılaştırmaları yapın',
              'Motivasyonunuzu yüksek tutun',
            ],
          );

          if (!shouldRequest) return false;
        }
      }

      // İzin iste
      final result = await Permission.camera.request();

      debugPrint('📸 Kamera izin sonucu: $result');

      // Sonucu döndür
      return result.isGranted;
    } catch (e) {
      // Hata durumunda log yaz ve false döndür
      debugPrint('❌ Kamera izin hatası: $e');
      return false;
    }
  }

  /// Konum izni ister
  /// Eğer izin verilmezse kullanıcıya neden gerekli olduğunu açıklayan dialog gösterir
  /// context BuildContext - Dialogun gösterileceği context
  /// Returns: Future<bool> - İzin verildi mi?
  static Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      // Mevcut izin durumunu kontrol et
      final status = await Permission.location.status;

      debugPrint('📍 Konum izin durumu: $status');

      // Eğer izin zaten verilmişse true döndür
      if (status.isGranted) {
        return true;
      }

      // Eğer kalıcı olarak reddedilmişse ayarlara yönlendir
      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          await _showPermissionDeniedDialog(
            context,
            title: 'Konum İzni Gerekli',
            message:
                'Yakınınızdaki spor salonlarını görmek ve mesafe takibi yapmak için '
                'konum iznine ihtiyacımız var. Lütfen uygulama ayarlarından konum '
                'iznini aktif edin.',
            icon: Icons.location_on,
            onSettingsPressed: () async {
              // Kullanıcıyı uygulama ayarlarına yönlendir
              await openAppSettings();
            },
          );
        }
        return false;
      }

      // İzin daha önce reddedilmişse açıklama göster
      if (status.isDenied) {
        if (context.mounted) {
          final shouldRequest = await _showPermissionRationaleDialog(
            context,
            title: 'Konum İzni Gerekli',
            message:
                'Yakınınızdaki spor salonlarını görmek ve otomatik antrenman kaydı '
                'başlatabilmek için konum erişimine ihtiyacımız var.',
            icon: Icons.location_on,
            benefits: [
              'Yakındaki salonları haritada görün',
              'Salona 100m yaklaştığınızda bildirim alın',
              'Otomatik antrenman kaydı başlatın',
            ],
          );

          if (!shouldRequest) return false;
        }
      }

      // İzin iste
      final result = await Permission.location.request();

      debugPrint('📍 Konum izin sonucu: $result');

      // Sonucu döndür
      return result.isGranted;
    } catch (e) {
      // Hata durumunda log yaz ve false döndür
      debugPrint('❌ Konum izin hatası: $e');
      return false;
    }
  }

  /// İzin reddedildiğinde gösterilen açıklayıcı dialog
  /// Kullanıcıya iznin neden gerekli olduğunu anlatır
  static Future<bool> _showPermissionRationaleDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required List<String> benefits,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1F3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                  width: 1,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: const Color(0xFF0A0E27), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bu özellik şunları sağlar:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...benefits.map(
                    (benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              benefit,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Text(
                        'İzin Ver',
                        style: TextStyle(
                          color: Color(0xFF0A0E27),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// İzin kalıcı olarak reddedildiğinde gösterilen dialog
  /// Kullanıcıyı ayarlara yönlendirir
  static Future<void> _showPermissionDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required VoidCallback onSettingsPressed,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withAlpha((0.2 * 255).toInt()), width: 1),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'İptal',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onSettingsPressed();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Ayarlara Git',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
