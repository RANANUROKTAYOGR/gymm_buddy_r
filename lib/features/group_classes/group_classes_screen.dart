import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/database/database_helper.dart';
import '../../data/models.dart';
import '../../services/notification_service.dart';

class GroupClassesScreen extends StatefulWidget {
  const GroupClassesScreen({super.key, required this.userId, this.branchId});

  final int userId;
  final int? branchId;

  @override
  State<GroupClassesScreen> createState() => _GroupClassesScreenState();
}

class _GroupClassesScreenState extends State<GroupClassesScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();
  List<GroupClass> _classes = [];
  bool _isLoading = true;

  // Grup dersleri saatleri
  final List<String> _classHours = [
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadGroupClasses();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  Future<void> _loadGroupClasses() async {
    setState(() => _isLoading = true);
    final classes = await _db.getGroupClassesByBranch(widget.branchId ?? 1);
    setState(() {
      _classes = classes;
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
                    : _classes.isEmpty
                        ? _buildEmptyState(isDark)
                        : _buildClassesList(isDark),
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
                colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
              ).createShader(bounds),
              child: Text(
                'Grup Dersleri',
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
                    const Color(0xFFFF6B9D).withOpacity(0.2),
                    const Color(0xFFC86DD7).withOpacity(0.2),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFF6B9D).withOpacity(0.3),
                  width: 2.w,
                ),
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 80.sp,
                color: isDark
                    ? const Color(0xFFFF6B9D)
                    : const Color(0xFFC86DD7),
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'Henüz Grup Dersi Yok',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              'Bu şubede henüz tarih ve saat belirlenmiş grup dersi bulunmamaktadır.',
              style: TextStyle(
                fontSize: 16.sp,
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Grup dersleri programı için resepsiyonla iletişime geçebilirsiniz.',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black45,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B9D).withOpacity(0.2),
                    const Color(0xFFC86DD7).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: const Color(0xFFFF6B9D).withOpacity(0.3),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: const Color(0xFFFF6B9D),
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Yakında yeni dersler eklenecek!',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
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

  Widget _buildClassesList(bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final groupClass = _classes[index];
        return _buildClassCard(groupClass, isDark);
      },
    );
  }

  Widget _buildClassCard(GroupClass groupClass, bool isDark) {
    return Container(
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
                    colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
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
                      groupClass.className,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${groupClass.maxCapacity} kişilik',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (groupClass.classDateTime != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B9D).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: const Color(0xFFFF6B9D),
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '${groupClass.classDateTime!.day}/${groupClass.classDateTime!.month}/${groupClass.classDateTime!.year} - ${groupClass.classDateTime!.hour.toString().padLeft(2, '0')}:${groupClass.classDateTime!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddClassDialog(bool isDark) {
    final nameController = TextEditingController();
    final capacityController = TextEditingController();
    final instructorController = TextEditingController();
    DateTime? selectedDate;
    String? selectedHour;

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
                    colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Yeni Grup Dersi',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Ders Adı',
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
                const SizedBox(height: 16),
                TextField(
                  controller: instructorController,
                  decoration: InputDecoration(
                    labelText: 'Eğitmen Adı (İsteğe bağlı)',
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
                const SizedBox(height: 16),
                TextField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Maksimum Kapasite',
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
                const SizedBox(height: 16),
                // Tarih seçici
                InkWell(
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
                              primary: Color(0xFFFF6B9D),
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
                          Icons.calendar_today,
                          color: const Color(0xFFFF6B9D),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedDate == null
                              ? 'Ders Tarihi Seçin'
                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
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
                // Saat seçici
                DropdownButtonFormField<String>(
                  value: selectedHour,
                  decoration: InputDecoration(
                    labelText: 'Ders Saati',
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
                  dropdownColor: isDark ? const Color(0xFF1A1F3A) : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  items: _classHours.map((hour) {
                    return DropdownMenuItem(
                      value: hour,
                      child: Text(hour),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedHour = value;
                    setDialogState(() {});
                  },
                ),
              ],
            ),
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
              onPressed: (nameController.text.isEmpty ||
                      capacityController.text.isEmpty ||
                      selectedDate == null ||
                      selectedHour == null)
                  ? null
                  : () async {
                      // Saat ve dakika bilgilerini al
                      final timeParts = selectedHour!.split(':');
                      final hour = int.parse(timeParts[0]);
                      final minute = int.parse(timeParts[1]);

                      // Tam tarih ve saat oluştur
                      final classDateTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        hour,
                        minute,
                      );

                      final classId = DateTime.now().millisecondsSinceEpoch;

                      final groupClass = GroupClass(
                        id: classId,
                        gymBranchId: widget.branchId ?? 1,
                        className: nameController.text,
                        instructorName: instructorController.text.isEmpty
                            ? null
                            : instructorController.text,
                        maxCapacity: int.parse(capacityController.text),
                        schedule: 'Belirli saat',
                        classDateTime: classDateTime,
                      );

                      await _db.database.then((db) => db.insert(
                            'group_classes',
                            groupClass.toMap(),
                          ));

                      // Bildirim zamanla (1 saat öncesi)
                      await _notificationService.scheduleGroupClassNotification(
                        classId: classId,
                        className: groupClass.className,
                        classTime: classDateTime,
                        instructorName: groupClass.instructorName,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        _loadGroupClasses();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Grup dersi eklendi ve bildirim ayarlandı!',
                            ),
                            backgroundColor: const Color(0xFFFF6B9D),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
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
