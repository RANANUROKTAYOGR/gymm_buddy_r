import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/database/database_helper.dart';
import '../../data/models.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key, required this.userId});

  final int userId;

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<DietPlan> _dietPlans = [];
  UserDiet? _currentUserDiet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final plans = await _db.getAllDietPlans();
    final userDiet = await _db.getCurrentUserDiet(widget.userId);
    setState(() {
      _dietPlans = plans;
      _currentUserDiet = userDiet;
      _isLoading = false;
    });
  }

  Future<void> _selectDietPlan(DietPlan plan) async {
    try {
      final userDiet = UserDiet(
        userId: widget.userId,
        dietPlanId: plan.id!,
        startDate: DateTime.now(),
        isActive: true,
      );

      await _db.createOrUpdateUserDiet(userDiet);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${plan.name} seçildi!'),
            backgroundColor: const Color(0xFF00FFA3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                    : _buildContent(isDark),
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
                'Beslenme Planım',
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

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentUserDiet != null) ...[
            _buildCurrentPlanCard(isDark),
            SizedBox(height: 24.h),
            _buildWeeklyMealPlan(isDark),
            SizedBox(height: 32.h),
          ],
          Text(
            'Mevcut Planlar',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          ..._dietPlans.map((plan) => _buildPlanCard(plan, isDark)),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(bool isDark) {
    final currentPlan = _dietPlans.firstWhere(
      (p) => p.id == _currentUserDiet!.dietPlanId,
      orElse: () => _dietPlans.first,
    );

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFA3).withOpacity(0.3),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 32.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktif Planınız',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      currentPlan.name,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            currentPlan.description,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildNutritionChip(
                'Protein',
                '${currentPlan.proteinPercentage}%',
                Colors.white,
              ),
              SizedBox(width: 8.w),
              _buildNutritionChip(
                'Karb',
                '${currentPlan.carbsPercentage}%',
                Colors.white,
              ),
              SizedBox(width: 8.w),
              _buildNutritionChip(
                'Yağ',
                '${currentPlan.fatPercentage}%',
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyMealPlan(bool isDark) {
    final currentPlan = _dietPlans.firstWhere(
      (p) => p.id == _currentUserDiet!.dietPlanId,
      orElse: () => _dietPlans.first,
    );

    final weeklyMeals = _getWeeklyMealsForPlan(currentPlan);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Haftalık Öğün Planı',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ...weeklyMeals.entries.map((entry) => _buildDayMealCard(
              entry.key,
              entry.value,
              isDark,
            )),
      ],
    );
  }

  Map<String, List<Map<String, String>>> _getWeeklyMealsForPlan(
      DietPlan plan) {
    if (plan.name.contains('Keto')) {
      return _getKetoMeals();
    } else if (plan.name.contains('Akdeniz')) {
      return _getMediterraneanMeals();
    } else if (plan.name.contains('Protein')) {
      return _getProteinMeals();
    } else {
      return _getBalancedMeals();
    }
  }

  Map<String, List<Map<String, String>>> _getKetoMeals() {
    return {
      'Pazartesi': [
        {
          'meal': 'Kahvaltı',
          'food': 'Omlet (3 yumurta) + Avokado + Peynir',
          'calories': '450 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Tavuk + Yeşil Salata (Zeytinyağlı)',
          'calories': '550 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Fırında Somon + Brokoli',
          'calories': '600 kcal'
        },
      ],
      'Salı': [
        {
          'meal': 'Kahvaltı',
          'food': 'Yumurta (3) + Hellim Peyniri + Yeşil Zeytin',
          'calories': '420 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Köfte + Roka Salatası',
          'calories': '580 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Biftek + Karnabahar Püresi',
          'calories': '620 kcal'
        },
      ],
      'Çarşamba': [
        {
          'meal': 'Kahvaltı',
          'food': 'Menemen (Tereyağlı) + Lor Peyniri',
          'calories': '440 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Balık + Roka ve Avokado Salatası',
          'calories': '560 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Tavuk Pirzola + Közlenmiş Patlıcan',
          'calories': '590 kcal'
        },
      ],
      'Perşembe': [
        {
          'meal': 'Kahvaltı',
          'food': 'Yumurta (Haşlanmış) + Avokado + Fındık',
          'calories': '460 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Hindi + Ispanak Salatası',
          'calories': '540 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Ton Balığı + Yeşil Salata',
          'calories': '580 kcal'
        },
      ],
      'Cuma': [
        {
          'meal': 'Kahvaltı',
          'food': 'Omlet (Mantarlı) + Beyaz Peynir + Ceviz',
          'calories': '470 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Kuzu Pirzola + Karışık Yeşillik',
          'calories': '620 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Izgara Levrek + Kabak Mücveri',
          'calories': '570 kcal'
        },
      ],
      'Cumartesi': [
        {
          'meal': 'Kahvaltı',
          'food': 'Yumurta (Sahanda) + Sosis + Domates',
          'calories': '480 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Karides (Tereyağlı) + Semizotu Salatası',
          'calories': '560 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Dana Bonfile + Mantar Sote',
          'calories': '640 kcal'
        },
      ],
      'Pazar': [
        {
          'meal': 'Kahvaltı',
          'food': 'Peynirli Omlet + Avokado + Badem',
          'calories': '450 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Tavuk But + Roka Salatası',
          'calories': '570 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Izgara Somon + Buharda Brokoli',
          'calories': '590 kcal'
        },
      ],
    };
  }

  Map<String, List<Map<String, String>>> _getMediterraneanMeals() {
    return {
      'Pazartesi': [
        {
          'meal': 'Kahvaltı',
          'food': 'Yulaf + Meyve + Badem + Bal',
          'calories': '400 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Balık + Pilav + Yeşil Salata',
          'calories': '650 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Tavuk Sote + Bulgur Pilavı + Cacık',
          'calories': '720 kcal'
        },
      ],
      'Salı': [
        {
          'meal': 'Kahvaltı',
          'food': 'Beyaz Peynir + Zeytin + Domates + Tam Buğday Ekmeği',
          'calories': '420 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Mercimek Çorbası + Izgara Köfte + Salata',
          'calories': '680 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Zeytinyağlı Fasulye + Pirinç Pilavı',
          'calories': '700 kcal'
        },
      ],
      'Çarşamba': [
        {
          'meal': 'Kahvaltı',
          'food': 'Menemen + Tam Buğday Ekmeği + Ceviz',
          'calories': '440 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Levrek + Patates (Fırın) + Salata',
          'calories': '670 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Kırmızı Mercimek Çorbası + Makarna + Salata',
          'calories': '690 kcal'
        },
      ],
      'Perşembe': [
        {
          'meal': 'Kahvaltı',
          'food': 'Yumurta (Haşlanmış) + Avokado + Tam Buğday Ekmeği',
          'calories': '430 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Tavuk Güveç + Bulgur Pilavı + Yoğurt',
          'calories': '700 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Izgara Çipura + Sebze Yemeği',
          'calories': '660 kcal'
        },
      ],
      'Cuma': [
        {
          'meal': 'Kahvaltı',
          'food': 'Yulaf Lapası + Muz + Fıstık Ezmesi',
          'calories': '450 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Nohut + Pirinç Pilavı + Karışık Salata',
          'calories': '720 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Fırında Tavuk + Sebzeli Bulgur',
          'calories': '680 kcal'
        },
      ],
      'Cumartesi': [
        {
          'meal': 'Kahvaltı',
          'food': 'Peynir + Domates + Salatalık + Zeytin + Ekmeği',
          'calories': '410 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Deniz Mahsülleri + Pilav + Salata',
          'calories': '690 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Zeytinyağlı Enginar + Yoğurt',
          'calories': '670 kcal'
        },
      ],
      'Pazar': [
        {
          'meal': 'Kahvaltı',
          'food': 'Omlet + Beyaz Peynir + Zeytin + Ekmeği',
          'calories': '440 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Balık + Makarna + Salata',
          'calories': '710 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Tavuk Sote + Sebze + Yoğurt',
          'calories': '690 kcal'
        },
      ],
    };
  }

  Map<String, List<Map<String, String>>> _getProteinMeals() {
    return {
      'Pazartesi': [
        {
          'meal': 'Kahvaltı',
          'food': 'Yumurta (4) + Peynir + Tam Buğday Ekmeği',
          'calories': '500 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Tavuk Göğsü (250g) + Kinoa + Brokoli',
          'calories': '750 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Biftek (200g) + Patates + Salata',
          'calories': '850 kcal'
        },
      ],
      'Salı': [
        {
          'meal': 'Kahvaltı',
          'food': 'Protein Shaker + Yulaf + Fıstık Ezmesi',
          'calories': '520 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Ton Balığı (200g) + Makarna + Salata',
          'calories': '780 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Izgara Somon (250g) + Pirinç Pilavı',
          'calories': '820 kcal'
        },
      ],
      'Çarşamba': [
        {
          'meal': 'Kahvaltı',
          'food': 'Omlet (4 yumurta) + Lor Peyniri + Ceviz',
          'calories': '510 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Hindi (250g) + Bulgur + Yeşillik',
          'calories': '760 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Kuzu Pirzola + Fasulye Pilaki',
          'calories': '840 kcal'
        },
      ],
      'Perşembe': [
        {
          'meal': 'Kahvaltı',
          'food': 'Yumurta (4) + Somon + Avokado',
          'calories': '530 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Köfte (250g) + Pirinç + Yoğurt',
          'calories': '790 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Tavuk But (250g) + Patates Püresi',
          'calories': '810 kcal'
        },
      ],
      'Cuma': [
        {
          'meal': 'Kahvaltı',
          'food': 'Protein Pancake + Muz + Badem Ezmesi',
          'calories': '540 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Balık (250g) + Kinoa + Ispanak',
          'calories': '770 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Dana Bonfile (200g) + Sebze + Yoğurt',
          'calories': '830 kcal'
        },
      ],
      'Cumartesi': [
        {
          'meal': 'Kahvaltı',
          'food': 'Yumurta (4) + Hellim + Domates',
          'calories': '510 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Tavuk Şiş (250g) + Bulgur + Salata',
          'calories': '800 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Karides (200g) + Makarna + Salata',
          'calories': '780 kcal'
        },
      ],
      'Pazar': [
        {
          'meal': 'Kahvaltı',
          'food': 'Menemen (4 yumurta) + Peynir + Ceviz',
          'calories': '520 kcal'
        },
        {
          'meal': 'Öğle',
          'food': 'Izgara Tavuk (300g) + Pirinç + Brokoli',
          'calories': '820 kcal'
        },
        {
          'meal': 'Akşam',
          'food': 'Izgara Somon (250g) + Patates + Salata',
          'calories': '840 kcal'
        },
      ],
    };
  }

  Map<String, List<Map<String, String>>> _getBalancedMeals() {
    return _getMediterraneanMeals();
  }

  Widget _buildDayMealCard(
      String day, List<Map<String, String>> meals, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F3A).withOpacity(0.7),
            const Color(0xFF1A1F3A).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.w,
        ),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        childrenPadding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 16.h),
        title: Text(
          day,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          '${meals.length} öğün',
          style: TextStyle(
            fontSize: 13.sp,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        iconColor: const Color(0xFF00FFA3),
        collapsedIconColor: isDark ? Colors.white54 : Colors.black54,
        children: meals
            .map((meal) => _buildMealItem(
                  meal['meal']!,
                  meal['food']!,
                  meal['calories']!,
                  isDark,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMealItem(
      String mealTime, String food, String calories, bool isDark) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _getMealIcon(mealTime),
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealTime,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00FFA3),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  food,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FFA3).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    calories,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00FFA3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String mealTime) {
    if (mealTime.contains('Kahvaltı')) {
      return Icons.wb_sunny_rounded;
    } else if (mealTime.contains('Öğle')) {
      return Icons.lunch_dining_rounded;
    } else {
      return Icons.dinner_dining_rounded;
    }
  }

  Widget _buildNutritionChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(DietPlan plan, bool isDark) {
    final isSelected = _currentUserDiet?.dietPlanId == plan.id;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [
                  const Color(0xFF00FFA3).withOpacity(0.2),
                  const Color(0xFF00D4FF).withOpacity(0.2),
                ]
              : [
                  const Color(0xFF1A1F3A).withOpacity(0.7),
                  const Color(0xFF1A1F3A).withOpacity(0.5),
                ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00FFA3).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 2.w,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: isSelected ? null : () => _selectDietPlan(plan),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSelected
                              ? [
                                  const Color(0xFF00FFA3),
                                  const Color(0xFF00D4FF)
                                ]
                              : [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        color: isSelected ? Colors.white : Colors.white54,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${plan.dailyCalories} kcal/gün',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: const Color(0xFF00FFA3),
                        size: 28.sp,
                      ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  plan.description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black87,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _buildNutritionChip(
                      'Protein',
                      '${plan.proteinPercentage}%',
                      isDark ? Colors.white70 : Colors.black87,
                    ),
                    _buildNutritionChip(
                      'Karbonhidrat',
                      '${plan.carbsPercentage}%',
                      isDark ? Colors.white70 : Colors.black87,
                    ),
                    _buildNutritionChip(
                      'Yağ',
                      '${plan.fatPercentage}%',
                      isDark ? Colors.white70 : Colors.black87,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
