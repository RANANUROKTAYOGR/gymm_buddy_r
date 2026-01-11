import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/database/database_helper.dart';
import '../../data/models.dart';
import '../../services/theme_service.dart';
import '../scanner/qr_equipment_scanner_screen.dart';
import '../scanner/equipment_list_screen.dart';
import '../progress/progress_tracking_screen.dart';
import '../dashboard/detailed_dashboard_screen.dart';
import '../appointments/appointments_screen.dart';
import '../group_classes/group_classes_screen.dart';
import '../diet/diet_plan_screen.dart';
import '../trainers/trainers_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  User? _user;
  int _totalWorkouts = 0;
  int _totalSets = 0;
  double _totalVolume = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = await _db.getUser(widget.userId);
    final workouts = await _db.getWorkoutSessionsByUser(widget.userId, 999);

    int totalSets = 0;
    double totalVolume = 0.0;

    for (var workout in workouts) {
      final logs = await _db.getExerciseLogsBySession(workout.id!);
      for (var log in logs) {
        final sets = await _db.getSetDetailsByLog(log.id!);
        totalSets += sets.length;
        for (var set in sets) {
          totalVolume += (set.weight ?? 0) * (set.reps ?? 0);
        }
      }
    }

    setState(() {
      _user = user;
      _totalWorkouts = workouts.length;
      _totalSets = totalSets;
      _totalVolume = totalVolume;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF0A0E27) : Colors.white;

    return Container(
      decoration: isDarkMode
          ? const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0E27),
                  Color(0xFF1A1F3A),
                  Color(0xFF0A0E27),
                ],
              ),
            )
          : BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1FD9C1)),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    _buildProfileHeader(),
                    SizedBox(height: 32.h),
                    _buildStatsGrid(),
                    SizedBox(height: 24.h),
                    _buildSubscriptionCard(),
                    SizedBox(height: 24.h),
                    _buildAchievements(),
                    SizedBox(height: 24.h),
                    _buildScannerTools(),
                    SizedBox(height: 24.h),
                    _buildSettings(),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B9D).withOpacity(0.4),
                blurRadius: 30.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: Icon(Icons.person_rounded, size: 60.sp, color: Colors.white),
        ),
        SizedBox(height: 20.h),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
          ).createShader(bounds),
          child: Text(
            _user?.name ?? 'Kullanıcı',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          _user?.email ?? '',
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
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
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16.sp,
                color: const Color(0xFFFF6B9D),
              ),
              SizedBox(width: 8.w),
              Text(
                'Üye: ${_getJoinDate()}',
                style: TextStyle(
                  color: const Color(0xFFFF6B9D),
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getJoinDate() {
    if (_user?.createdAt == null) return 'Bilinmiyor';
    final date = _user!.createdAt;
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatsGrid() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 16.h),
          child: Text(
            'İstatistikler',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.fitness_center_rounded,
                value: _totalWorkouts.toString(),
                label: 'Antrenman',
                colors: [const Color(0xFF00FFA3), const Color(0xFF00D4FF)],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                icon: Icons.repeat_rounded,
                value: _totalSets.toString(),
                label: 'Toplam Set',
                colors: [const Color(0xFFFF6B9D), const Color(0xFFC86DD7)],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _buildStatCard(
          icon: Icons.scale_rounded,
          value: '${(_totalVolume / 1000).toStringAsFixed(1)} ton',
          label: 'Toplam Hacim',
          colors: [const Color(0xFFFFB800), const Color(0xFFFF6B00)],
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required List<Color> colors,
    bool isWide = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[0].withOpacity(isDarkMode ? 0.2 : 0.1),
            colors[1].withOpacity(isDarkMode ? 0.2 : 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors[0].withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: Colors.white, size: 28.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.6)
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Subscription?>(
      future: _db.getActiveSubscription(widget.userId),
      builder: (context, snapshot) {
        final subscription = snapshot.data;
        final isActive =
            subscription != null &&
            subscription.endDate.isAfter(DateTime.now());

        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [
                      const Color(
                        0xFF00FFA3,
                      ).withOpacity(isDarkMode ? 0.2 : 0.1),
                      const Color(
                        0xFF00D4FF,
                      ).withOpacity(isDarkMode ? 0.2 : 0.1),
                    ]
                  : [
                      Colors.red.withOpacity(isDarkMode ? 0.2 : 0.1),
                      Colors.orange.withOpacity(isDarkMode ? 0.2 : 0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF00FFA3).withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    color: isActive ? const Color(0xFF00FFA3) : Colors.red,
                    size: 32.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive ? 'Üyelik Aktif' : 'Üyelik Pasif',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? const Color(0xFF00FFA3)
                                : Colors.red,
                          ),
                        ),
                        if (subscription != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            'Bitiş: ${subscription.endDate.day}/${subscription.endDate.month}/${subscription.endDate.year}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (subscription == null) ...[
                SizedBox(height: 8.h),
                Text(
                  'Henüz aktif bir üyeliğiniz bulunmamaktadır.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.6)
                        : Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievements() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 16.h),
          child: Text(
            'Başarılar',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      const Color(0xFF1A1F3A).withOpacity(0.7),
                      const Color(0xFF1A1F3A).withOpacity(0.5),
                    ]
                  : [Colors.grey.shade100, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAchievementBadge(
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFFFFD700),
                    isUnlocked: _totalWorkouts >= 10,
                    title: 'Bronz Kupa',
                    description: '10 antrenman tamamlayarak bu başarıyı açın.',
                  ),
                  SizedBox(width: 12.w),
                  _buildAchievementBadge(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF6B00),
                    isUnlocked: _totalWorkouts >= 25,
                    title: 'Ateşli Sporcu',
                    description: '25 antrenman tamamlayarak bu başarıyı açın.',
                  ),
                  SizedBox(width: 12.w),
                  _buildAchievementBadge(
                    icon: Icons.star_rounded,
                    color: const Color(0xFF00FFA3),
                    isUnlocked: _totalWorkouts >= 50,
                    title: 'Yıldız',
                    description: '50 antrenman tamamlayarak bu başarıyı açın.',
                  ),
                  SizedBox(width: 12.w),
                  _buildAchievementBadge(
                    icon: Icons.workspace_premium_rounded,
                    color: const Color(0xFFC86DD7),
                    isUnlocked: _totalWorkouts >= 100,
                    title: 'Elit Üye',
                    description: '100 antrenman tamamlayarak bu başarıyı açın.',
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                'Rozet Koleksiyonu',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              _buildBadgeCollection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge({
    required IconData icon,
    required Color color,
    required bool isUnlocked,
    required String title,
    required String description,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDarkMode
                  ? const Color(0xFF1A1F3A)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              title: Row(
                children: [
                  Icon(
                    icon,
                    color: isUnlocked
                        ? color
                        : (isDarkMode ? Colors.grey : Colors.grey.shade400),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 18.sp,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                description,
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 14.sp,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(color: Color(0xFF00FFA3)),
                  ),
                ),
              ],
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: isUnlocked
                ? color.withOpacity(0.2)
                : (isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isUnlocked
                  ? color.withOpacity(0.4)
                  : (isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.3)),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isUnlocked
                ? color
                : (isDarkMode ? Colors.white.withOpacity(0.3) : Colors.grey),
            size: 32.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeCollection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<List<UserBadge>>(
      future: DatabaseHelper.instance.getUserBadges(widget.userId),
      builder: (context, snapshot) {
        final badges = snapshot.data ?? [];
        final ownedCodes = badges.map((b) => b.badgeCode).toSet();

        // Known badge catalog
        final catalog = [
          _BadgeItem(
            code: 'SU_SAVASCISI',
            title: 'Su Savaşçısı',
            icon: Icons.water_drop,
          ),
          _BadgeItem(
            code: 'ILK_ADIM',
            title: 'İlk Adım',
            icon: Icons.directions_run,
          ),
        ];

        return GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.75,
          mainAxisSpacing: 8.h,
          crossAxisSpacing: 8.w,
          children: catalog.map((item) {
            final unlocked = ownedCodes.contains(item.code);
            final color = unlocked ? const Color(0xFF1FD9C1) : Colors.grey;
            final badgeTile = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: unlocked
                        ? color.withOpacity(0.2)
                        : (isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: unlocked
                          ? color.withOpacity(0.6)
                          : (isDark
                                ? Colors.white12
                                : Colors.grey.withOpacity(0.3)),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: unlocked ? color : Colors.grey,
                    size: 24.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  item.title,
                  style: TextStyle(
                    color: unlocked
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white54 : Colors.black54),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );

            if (unlocked) {
              return badgeTile;
            } else {
              // Grayscale effect for locked
              return ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: badgeTile,
              );
            }
          }).toList(),
        );
      },
    );
  }

  Widget _buildScannerTools() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 16.h),
          child: Text(
            'AR Araçları',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                icon: Icons.analytics_rounded,
                title: 'İlerleme Panosu',
                subtitle: 'Detaylı grafikler',
                gradient: const [Color(0xFF00D4FF), Color(0xFF0099FF)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DetailedDashboardScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                icon: Icons.qr_code_scanner,
                title: 'QR Tara',
                subtitle: 'Ekipman bilgileri',
                gradient: const [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          QREquipmentScannerScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildToolCard(
                icon: Icons.camera_alt,
                title: 'Gelişim Takibi',
                subtitle: 'Fotoğrafla kaydet',
                gradient: const [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProgressTrackingScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                icon: Icons.calendar_month,
                title: 'Randevular',
                subtitle: 'Antrenör randevuları',
                gradient: const [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AppointmentsScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildToolCard(
                icon: Icons.groups,
                title: 'Grup Dersleri',
                subtitle: 'Sınıf programları',
                gradient: const [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GroupClassesScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                icon: Icons.restaurant_menu,
                title: 'Beslenme',
                subtitle: 'Diyet planları',
                gradient: const [Color(0xFFFFD700), Color(0xFFFF6B00)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DietPlanScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildToolCard(
                icon: Icons.person_pin,
                title: 'Antrenörler',
                subtitle: 'İletişim',
                gradient: const [Color(0xFF00D4FF), Color(0xFF0099FF)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TrainersScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                icon: Icons.list_alt,
                title: 'Ekipman Listesi',
                subtitle: 'Tüm aletleri gör',
                gradient: const [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EquipmentListScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient[0].withOpacity(0.2),
              gradient[1].withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: gradient[0].withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 15.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 16.h),
          child: Text(
            'Ayarlar',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      const Color(0xFF1A1F3A).withOpacity(0.7),
                      const Color(0xFF1A1F3A).withOpacity(0.5),
                    ]
                  : [Colors.grey.shade100, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.brightness_4_rounded,
                title: isDarkMode ? 'Açık Tema' : 'Koyu Tema',
                onTap: () {
                  ThemeService().toggleTheme();
                },
              ),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              _buildSettingsItem(
                icon: Icons.person_outline_rounded,
                title: 'Profili Düzenle',
                onTap: () => _showEditProfileDialog(),
              ),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              _buildSettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Bildirimler',
                onTap: () => _showNotificationSettings(),
              ),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              _buildSettingsItem(
                icon: Icons.info_outline_rounded,
                title: 'Hakkında',
                onTap: () {
                  _showAboutDialog();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black54,
                size: 24.sp,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _user?.name);
    final emailController = TextEditingController(text: _user?.email);
    final heightController = TextEditingController(
      text: _user?.height?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: _user?.weight?.toString() ?? '',
    );
    DateTime selectedDate = _user?.dateOfBirth ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
            ).createShader(bounds),
            child: Text(
              'Profili Düzenle',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20.sp,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'İsim',
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      color: const Color(0xFFFF6B9D),
                      size: 24.sp,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFFF6B9D)),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.email,
                      color: const Color(0xFFFF6B9D),
                      size: 24.sp,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFFF6B9D)),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Boy (cm)',
                          labelStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.height,
                            color: const Color(0xFFFF6B9D),
                            size: 24.sp,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6B9D),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Kilo (kg)',
                          labelStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.monitor_weight,
                            color: const Color(0xFFFF6B9D),
                            size: 24.sp,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF6B9D),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFFF6B9D),
                              surface: Color(0xFF1A1F3A),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cake,
                          color: const Color(0xFFFF6B9D),
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Doğum Tarihi: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen isim giriniz')),
                  );
                  return;
                }

                final updatedUser = User(
                  id: _user?.id,
                  name: nameController.text,
                  email: emailController.text.isEmpty
                      ? null
                      : emailController.text,
                  dateOfBirth: selectedDate,
                  height: heightController.text.isEmpty
                      ? null
                      : double.tryParse(heightController.text),
                  weight: weightController.text.isEmpty
                      ? null
                      : double.tryParse(weightController.text),
                  createdAt: _user?.createdAt ?? DateTime.now(),
                );

                await _db.updateUser(updatedUser);
                await _loadProfileData();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil güncellendi!'),
                      backgroundColor: Color(0xFF00FFA3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Kaydet',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    bool workoutReminders = true;
    bool progressUpdates = true;
    bool achievementAlerts = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
            ).createShader(bounds),
            child: Text(
              'Bildirim Ayarları',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20.sp,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(
                  'Antrenman Hatırlatıcıları',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ),
                subtitle: Text(
                  'Günlük antrenman hatırlatmaları al',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12.sp,
                  ),
                ),
                value: workoutReminders,
                activeColor: const Color(0xFF00FFA3),
                onChanged: (value) {
                  setDialogState(() {
                    workoutReminders = value;
                  });
                },
              ),
              const Divider(color: Colors.white24),
              SwitchListTile(
                title: Text(
                  'İlerleme Güncellemeleri',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ),
                subtitle: Text(
                  'Haftalık ilerleme raporları al',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12.sp,
                  ),
                ),
                value: progressUpdates,
                activeColor: const Color(0xFF00FFA3),
                onChanged: (value) {
                  setDialogState(() {
                    progressUpdates = value;
                  });
                },
              ),
              const Divider(color: Colors.white24),
              SwitchListTile(
                title: Text(
                  'Başarı Bildirimleri',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ),
                subtitle: Text(
                  'Yeni başarılar kazandığında bildirim al',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12.sp,
                  ),
                ),
                value: achievementAlerts,
                activeColor: const Color(0xFF00FFA3),
                onChanged: (value) {
                  setDialogState(() {
                    achievementAlerts = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Save notification preferences to shared preferences or database
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bildirim ayarları kaydedildi!'),
                    backgroundColor: Color(0xFF00FFA3),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFA3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Kaydet',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
          ).createShader(bounds),
          child: Text(
            'GYM BUDDY',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20.sp,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versiyon 1.0.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Antrenmanlarınızı takip edin, hedeflerinize ulaşın! 💪',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tamam',
              style: TextStyle(color: Color(0xFF00FFA3), fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem {
  final String code;
  final String title;
  final IconData icon;
  _BadgeItem({required this.code, required this.title, required this.icon});
}
