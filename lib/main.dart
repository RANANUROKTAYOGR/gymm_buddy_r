import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'data/database/database_helper.dart';
import 'data/models.dart';
import 'data/seed_data.dart';
import 'features/dashboard/activity_dashboard_screen.dart';
import 'features/dashboard/hydration_detail_screen.dart';
import 'features/scanner/gym_qr_scanner_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/exercise/exercise_library_screen.dart';
import 'features/map/map_screen.dart';
import 'features/dashboard/widgets/hydration_widget.dart';
import 'services/step_counter_service.dart';
import 'services/gym_entry_service.dart';
import 'services/theme_service.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Turkish locale data for intl DateFormat
  await initializeDateFormatting('tr');
  Intl.defaultLocale = 'tr';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Yaygın tasarım boyutu
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ListenableBuilder(
          listenable: ThemeService(),
          builder: (context, child) {
            final themeService = ThemeService();
            final isDark = themeService.isDarkMode;
            
            return MaterialApp(
              title: 'GYM BUDDY',
              debugShowCheckedModeBanner: false,
              theme: isDark ? _buildDarkTheme() : _buildLightTheme(),
              home: const AppInitializer(),
            );
          },
        );
      },
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1FD9C1),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0E27),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0E27),
        foregroundColor: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1FD9C1),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1FD9C1),
        foregroundColor: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Show splash for at least 2 seconds for better UX
    final initFuture = _setupDatabase();
    final minSplashFuture = Future.delayed(const Duration(seconds: 2));

    await Future.wait([initFuture, minSplashFuture]);

    if (mounted) {
      final userId = await initFuture;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen(userId: userId)),
      );
    }
  }

  Future<int> _setupDatabase() async {
    // Initialize theme service
    await ThemeService().init();
    
    // Initialize database and ensure sample data exists
    final db = DatabaseHelper.instance;

    final users = await db.getAllUsers();

    // Create default user if none exists
    int userId;
    if (users.isEmpty) {
      final newUser = User(
        name: 'Kullanıcı',
        email: 'user@gymbud.com',
        createdAt: DateTime.now(),
      );
      final savedUser = await db.createUser(newUser);
      userId = savedUser.id!;
    } else {
      userId = users.first.id!;
    }

    // Seed gym branches data
    await SeedData.seedGymBranches();

    // Seed exercises data
    await SeedData.seedExercises();
    // Seed equipment data
    await SeedData.seedEquipment();

    // Update equipment video URLs
    await db.updateEquipmentVideoUrls();

    // Initialize step counter
    final stepService = StepCounterService();
    await stepService.initStepCounter();

    return userId;
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.userId});

  final int userId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final GymEntryService _gymEntryService;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _gymEntryService = GymEntryService();
    _screens = [
      ActivityDashboardScreen(userId: widget.userId),
      MapScreen(userId: widget.userId),
      const ExerciseLibraryScreen(),
      ProfileScreen(userId: widget.userId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Gym entry status
          AnimatedBuilder(
            animation: _gymEntryService,
            builder: (context, _) {
              return _gymEntryService.isCheckedIn
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1FD9C1).withOpacity(0.1),
                            const Color(0xFF5B9BCC).withOpacity(0.1),
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(0xFF1FD9C1).withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF1FD9C1),
                              size: 20,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _gymEntryService.currentGymName ?? 'Salon',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Text(
                                        '♀️ ${_gymEntryService.femaleCount}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Text(
                                        '♂️ ${_gymEntryService.maleCount}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox.shrink();
            },
          ),
          // Top water indicator
          SafeArea(
            bottom: false,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A1F3A).withAlpha((0.95 * 255).toInt()),
                    const Color(0xFF0A0E27).withAlpha((0.0 * 255).toInt()),
                  ],
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HydrationDetailScreen(
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: HydrationWidget(userId: widget.userId, isCompact: true),
              ),
            ),
          ),
          // Main content
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      // QR Check-in FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GymQRScannerScreen(userId: widget.userId),
            ),
          );
        },
        backgroundColor: const Color(0xFF1FD9C1),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          Icons.qr_code_2,
          color: Colors.white,
          size: 28.sp,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1F3A).withAlpha((0.95 * 255).toInt()),
              const Color(0xFF0A0E27),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.3 * 255).toInt()),
              blurRadius: 20.r,
              offset: Offset(0, -5.h),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.fitness_center_rounded, 'Antrenman'),
                _buildNavItem(1, Icons.map_rounded, 'Harita'),
                _buildNavItem(2, Icons.explore_rounded, 'Keşfet'),
                _buildNavItem(3, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: isSelected
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1FD9C1), Color(0xFF5B9BCC)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF1FD9C1,
                      ).withAlpha((0.2 * 255).toInt()),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withAlpha((0.5 * 255).toInt()),
                size: 26.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withAlpha((0.5 * 255).toInt()),
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
