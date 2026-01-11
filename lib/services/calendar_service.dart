import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  String? _selectedCalendarId;

  /// Takvim izinlerini kontrol et ve iste
  Future<bool> requestCalendarPermissions() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && (permissionsGranted.data ?? false)) {
        return true;
      }

      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      return permissionsGranted.isSuccess && (permissionsGranted.data ?? false);
    } catch (e) {
      debugPrint('Calendar permission error: $e');
      return false;
    }
  }

  /// Cihazdan takvim listesini al ve ilk yazılabilir takvimi seç
  Future<void> retrieveCalendars() async {
    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        final writableCalendar = calendarsResult.data!.firstWhere(
          (cal) => cal.isReadOnly == false,
          orElse: () => calendarsResult.data!.first,
        );
        _selectedCalendarId = writableCalendar.id;
      }
    } catch (e) {
      debugPrint('Error retrieving calendars: $e');
    }
  }

  /// Workout session için takvime etkinlik ekle
  Future<bool> addWorkoutToCalendar({
    required String title,
    required DateTime startTime,
    int durationMinutes = 60,
    String? description,
    String? location,
  }) async {
    try {
      final hasPermission = await requestCalendarPermissions();
      if (!hasPermission) return false;

      if (_selectedCalendarId == null) {
        await retrieveCalendars();
      }

      if (_selectedCalendarId == null) return false;

      final event = Event(
        _selectedCalendarId,
        title: title,
        description: description ?? 'Gym Buddy antrenman seansı',
        start: TZDateTime.from(startTime, UTC),
        end: TZDateTime.from(
          startTime.add(Duration(minutes: durationMinutes)),
          UTC,
        ),
        location: location,
      );

      final createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      return createEventResult?.isSuccess ?? false;
    } catch (e) {
      debugPrint('Error adding workout to calendar: $e');
      return false;
    }
  }

  /// Randevu için takvime etkinlik ekle
  Future<bool> addAppointmentToCalendar({
    required String title,
    required DateTime appointmentTime,
    int durationMinutes = 30,
    String? trainerName,
    String? notes,
    String? location,
  }) async {
    try {
      final hasPermission = await requestCalendarPermissions();
      if (!hasPermission) return false;

      if (_selectedCalendarId == null) {
        await retrieveCalendars();
      }

      if (_selectedCalendarId == null) return false;

      final description = StringBuffer();
      if (trainerName != null) {
        description.writeln('Antrenör: $trainerName');
      }
      if (notes != null) {
        description.writeln(notes);
      }

      final event = Event(
        _selectedCalendarId,
        title: title,
        description: description.toString(),
        start: TZDateTime.from(appointmentTime, UTC),
        end: TZDateTime.from(
          appointmentTime.add(Duration(minutes: durationMinutes)),
          UTC,
        ),
        location: location,
      );

      final createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      return createEventResult?.isSuccess ?? false;
    } catch (e) {
      debugPrint('Error adding appointment to calendar: $e');
      return false;
    }
  }

  /// Grup dersi için takvime etkinlik ekle
  Future<bool> addGroupClassToCalendar({
    required String className,
    required DateTime classTime,
    int durationMinutes = 45,
    String? instructorName,
    String? location,
  }) async {
    try {
      final hasPermission = await requestCalendarPermissions();
      if (!hasPermission) return false;

      if (_selectedCalendarId == null) {
        await retrieveCalendars();
      }

      if (_selectedCalendarId == null) return false;

      final description = instructorName != null
          ? 'Eğitmen: $instructorName'
          : 'Gym Buddy grup dersi';

      final event = Event(
        _selectedCalendarId,
        title: className,
        description: description,
        start: TZDateTime.from(classTime, UTC),
        end: TZDateTime.from(
          classTime.add(Duration(minutes: durationMinutes)),
          UTC,
        ),
        location: location,
      );

      final createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      return createEventResult?.isSuccess ?? false;
    } catch (e) {
      debugPrint('Error adding group class to calendar: $e');
      return false;
    }
  }
}
