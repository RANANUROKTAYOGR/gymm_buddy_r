import 'package:flutter/material.dart';

/// Global hata yönetimi sınıfı
/// Tüm uygulama genelinde tutarlı hata mesajları gösterir
class ErrorHandler {
  /// Genel bir hata mesajı gösterir
  /// [context] BuildContext - Mesajın gösterileceği context
  /// [error] dynamic - Yakalanan hata
  /// [customMessage] String - Özel hata mesajı (opsiyonel)
  static void showError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
  }) {
    // Mounted kontrolü - Widget hala aktif mi?
    if (!context.mounted) return;

    // Hata detaylarını console'a yazdır (debugging için)
    debugPrint('❌ HATA YAKALANDI: ${error.toString()}');
    debugPrint('📍 Stack Trace: ${StackTrace.current}');

    // Kullanıcıya gösterilecek mesaj
    final String displayMessage =
        customMessage ?? 'Bir şeyler ters gitti, lütfen tekrar deneyin';

    // SnackBar ile kullanıcıya bildirme
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935), // Kırmızı
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'KAPAT',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Başarı mesajı gösterir
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00FFA3), // Aqua yeşil
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Veritabanı işlem hatalarını yakalar
  static void handleDatabaseError(BuildContext context, dynamic error) {
    showError(
      context,
      error,
      customMessage:
          'Veritabanı hatası oluştu. Lütfen daha sonra tekrar deneyin.',
    );
  }

  /// Kamera hatalarını yakalar
  static void handleCameraError(BuildContext context, dynamic error) {
    showError(
      context,
      error,
      customMessage: 'Kamera başlatılamadı. Lütfen kamera iznini kontrol edin.',
    );
  }

  /// Konum servisi hatalarını yakalar
  static void handleLocationError(BuildContext context, dynamic error) {
    showError(
      context,
      error,
      customMessage: 'Konum alınamadı. GPS\'in açık olduğundan emin olun.',
    );
  }

  /// Ağ bağlantı hatalarını yakalar
  static void handleNetworkError(BuildContext context, dynamic error) {
    showError(
      context,
      error,
      customMessage:
          'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.',
    );
  }
}
