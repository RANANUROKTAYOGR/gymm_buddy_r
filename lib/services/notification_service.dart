import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Bildirim servisini başlat
  Future<void> initialize() async {
    if (_initialized) return;

    // Timezone verilerini yükle
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Bildirime tıklandığında çağrılır
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Gerekirse navigate işlemleri yapılabilir
  }

  /// İzinleri kontrol et ve iste
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosImplementation = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Hemen bildirim göster
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'gym_buddy_channel',
      'Gym Buddy Bildirimleri',
      channelDescription: 'Randevu ve grup dersi bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Belirli bir zamanda bildirim zamanla (1 saat öncesi için)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    // 1 saat öncesine ayarla
    final notificationTime = scheduledTime.subtract(const Duration(hours: 1));

    // Geçmiş bir zaman ise bildirim gönderme
    if (notificationTime.isBefore(DateTime.now())) {
      debugPrint('Bildirim zamanı geçmiş, gönderilmedi: $notificationTime');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'gym_buddy_channel',
      'Gym Buddy Bildirimleri',
      channelDescription: 'Randevu ve grup dersi bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(notificationTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint('Bildirim zamanlandı: $notificationTime için (ID: $id)');
  }

  /// Grup dersi bildirimi zamanla
  Future<void> scheduleGroupClassNotification({
    required int classId,
    required String className,
    required DateTime classTime,
    String? instructorName,
  }) async {
    final title = 'Grup Dersi Hatırlatması';
    final body = instructorName != null
        ? '$className dersi 1 saat sonra başlıyor!\nEğitmen: $instructorName'
        : '$className dersi 1 saat sonra başlıyor!';

    await scheduleNotification(
      id: classId,
      title: title,
      body: body,
      scheduledTime: classTime,
      payload: 'group_class_$classId',
    );
  }

  /// Randevu bildirimi zamanla
  Future<void> scheduleAppointmentNotification({
    required int appointmentId,
    required DateTime appointmentTime,
    String? notes,
  }) async {
    final title = 'Randevu Hatırlatması';
    final body = notes != null
        ? 'Randevunuz 1 saat sonra!\n$notes'
        : 'Randevunuz 1 saat sonra başlıyor!';

    await scheduleNotification(
      id: appointmentId,
      title: title,
      body: body,
      scheduledTime: appointmentTime,
      payload: 'appointment_$appointmentId',
    );
  }

  /// Bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('Bildirim iptal edildi: $id');
  }

  /// Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('Tüm bildirimler iptal edildi');
  }

  /// Bekleyen bildirimleri listele (debug için)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
