import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/database/database_helper.dart';
import '../../data/models.dart';
import '../../services/calendar_service.dart';
import '../../services/notification_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required this.userId});

  final int userId;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final CalendarService _calendarService = CalendarService();
  final NotificationService _notificationService = NotificationService();
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadAppointments();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    final appointments = await _db.getAppointmentsByUser(widget.userId);
    setState(() {
      _appointments = appointments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : Colors.white,
      body: Container(
        decoration: isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0E27),
                    Color(0xFF1A1F3A),
                    Color(0xFF0A0E27)
                  ],
                ),
              )
            : null,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDark),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1FD9C1),
                        ),
                      )
                    : _appointments.isEmpty
                        ? _buildEmptyState(isDark)
                        : _buildAppointmentsList(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black87,
              size: 24.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
              ).createShader(bounds),
              child: Text(
                'Randevularım',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00FFA3).withOpacity(0.2),
                    const Color(0xFF00D4FF).withOpacity(0.2),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF00FFA3).withOpacity(0.3),
                  width: 2.w,
                ),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 80.sp,
                color: isDark
                    ? const Color(0xFF00FFA3)
                    : const Color(0xFF00D4FF),
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'Henüz Randevu Yok',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              'Henüz planlanmış bir randevunuz veya eğitmen atamanız gözükmemektedir.',
              style: TextStyle(
                fontSize: 16.sp,
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to booking screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Randevu alma özelliği yakında eklenecek!'),
                  ),
                );
              },
              icon: Icon(Icons.add_rounded, color: Colors.white, size: 24.sp),
              label: Text(
                'Randevu Al',
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFA3),
                padding: EdgeInsets.symmetric(
                  horizontal: 32.w,
                  vertical: 16.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return _buildAppointmentCard(appointment, isDark);
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, bool isDark) {
    return InkWell(
      onTap: () => _showTimePickerDialog(appointment, isDark),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F3A).withOpacity(0.7),
            const Color(0xFF1A1F3A).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.appointmentDate.day.toString() +
                          '/' +
                          appointment.appointmentDate.month.toString() +
                          '/' +
                          appointment.appointmentDate.year.toString(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (appointment.appointmentTime != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: const Color(0xFF00FFA3),
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${appointment.appointmentTime!.hour.toString().padLeft(2, '0')}:${appointment.appointmentTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF00FFA3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (appointment.notes != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        appointment.notes!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  void _showTimePickerDialog(Appointment appointment, bool isDark) async {
    final time = await showTimePicker(
      context: context,
      initialTime: appointment.appointmentTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00FFA3),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1F3A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      // Tam tarih ve saat oluştur
      final appointmentDateTime = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
        time.hour,
        time.minute,
      );

      // Randevuyu güncelle
      final updatedAppointment = appointment.copyWith(
        appointmentTime: time,
      );

      await _db.database.then((db) => db.update(
            'appointments',
            updatedAppointment.toMap(),
            where: 'id = ?',
            whereArgs: [appointment.id],
          ));

      // Eski bildirimi iptal et ve yenisini zamanla
      if (appointment.id != null) {
        await _notificationService.cancelNotification(appointment.id!);
        await _notificationService.scheduleAppointmentNotification(
          appointmentId: appointment.id!,
          appointmentTime: appointmentDateTime,
          notes: appointment.notes,
        );
      }

      // Listeyi yenile
      await _loadAppointments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu saati güncellendi ve bildirim ayarlandı!'),
            backgroundColor: Color(0xFF00FFA3),
          ),
        );
      }
    }
  }

  void _showAddAppointmentDialog(bool isDark) {
    final dateController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1F3A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Yeni Randevu',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Randevu Tarihi',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  suffixIcon: Icon(
                    Icons.calendar_month,
                    color: const Color(0xFF00FFA3),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF00FFA3),
                            onPrimary: Colors.white,
                            surface: Color(0xFF1A1F3A),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    selectedDate = date;
                    dateController.text =
                        '${date.day}/${date.month}/${date.year}';
                    setDialogState(() {});
                  }
                },
              ),
              const SizedBox(height: 16),
              // Saat seçici
              InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF00FFA3),
                            onPrimary: Colors.white,
                            surface: Color(0xFF1A1F3A),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    selectedTime = time;
                    setDialogState(() {});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: const Color(0xFF00FFA3),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        selectedTime == null
                            ? 'Randevu Saati Seçin'
                            : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notlar (İsteğe bağlı)',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: (selectedDate == null || selectedTime == null)
                  ? null
                  : () async {
                      // Tam tarih ve saat oluştur
                      final appointmentDateTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );

                      final appointmentId = DateTime.now().millisecondsSinceEpoch;

                      final appointment = Appointment(
                        id: appointmentId,
                        userId: widget.userId,
                        trainerId: 1,
                        appointmentDate: selectedDate!,
                        appointmentTime: selectedTime,
                        status: 'scheduled',
                        notes: notesController.text.isEmpty
                            ? null
                            : notesController.text,
                      );

                      await _db.database.then((db) => db.insert(
                            'appointments',
                            appointment.toMap(),
                          ));

                      // Bildirim zamanla (1 saat öncesi)
                      await _notificationService.scheduleAppointmentNotification(
                        appointmentId: appointmentId,
                        appointmentTime: appointmentDateTime,
                        notes: appointment.notes,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        _loadAppointments();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Randevu oluşturuldu ve bildirim ayarlandı!'),
                            backgroundColor: Color(0xFF00FFA3),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFA3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
