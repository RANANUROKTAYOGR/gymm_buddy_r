import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/database/database_helper.dart';
import '../../data/models.dart';
import '../../services/gamification_manager.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    required this.userId,
  });

  final int userId;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? _sessionStart;
  String? _selectedSessionType;
  int? _selectedExerciseId;
  List<Exercise> _exercises = [];
  final List<_SetInput> _sets = [];
  bool _isLoading = false;

  static const sessionTypes = ['Strength', 'Cardio', 'Mixed', 'Flexibility'];

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final exercises = await _db.getAllExercises();
    setState(() => _exercises = exercises);
  }

  void _addSet() {
    if (_selectedExerciseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen egzersizi seçin')),
      );
      return;
    }
    setState(() => _sets.add(_SetInput()));
  }

  void _removeSet(int index) {
    setState(() => _sets.removeAt(index));
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir set ekleyin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (true) {

      setState(() => _isLoading = true);
      try {
        final endTime = DateTime.now();
        final duration = endTime.difference(_sessionStart!).inMinutes;

        final session = WorkoutSession(
          userId: widget.userId,
          startTime: _sessionStart!,
          endTime: endTime,
          sessionType: _selectedSessionType,
          totalDuration: duration,
          createdAt: DateTime.now(),
        );

        final savedSession = await _db.createWorkoutSession(session);
        // Check badges after first workout session
        await GamificationManager().checkBadges(widget.userId, context);

        final exerciseLog = ExerciseLog(
          workoutSessionId: savedSession.id!,
          exerciseId: _selectedExerciseId!,
          orderInSession: 1,
          createdAt: DateTime.now(),
        );

        final savedLog = await _db.createExerciseLog(exerciseLog);

        for (int i = 0; i < _sets.length; i++) {
          final set = _sets[i];
          final setDetails = SetDetails(
            exerciseLogId: savedLog.id!,
            setNumber: i + 1,
            weight: set.weight,
            reps: set.reps,
            createdAt: DateTime.now(),
          );
          await _db.createSetDetails(setDetails);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Antrenman başarıyla kaydedildi! ✓'),
              backgroundColor: Color(0xFF00FFA3),
            ),
          );
          Navigator.pop(context, true);
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
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF0A0E27) : Colors.white;
    
    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.white.withAlpha((0.1 * 255).toInt())
                  : Colors.black.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.arrow_back_rounded, 
                size: 24.sp,
                color: isDarkMode ? Colors.white : Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Antrenman Kaydı',
          style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold, 
              color: isDarkMode ? Colors.white : Colors.black),
        ),
      ),
      body: Container(
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
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(20.w),
              children: [
                _buildSessionTypeCard(),
                SizedBox(height: 20.h),
                _buildExerciseCard(),
                SizedBox(height: 20.h),
                _buildAddSetButton(),
                SizedBox(height: 20.h),
                if (_sets.isEmpty)
                  _buildEmptyState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sets.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      return _SetCard(
                        setIndex: index + 1,
                        setInput: _sets[index],
                        onRemove: () => _removeSet(index),
                      );
                    },
                  ),
                SizedBox(height: 24.h),
                _buildSaveButton(),
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionTypeCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F3A).withAlpha((0.7 * 255).toInt()),
            const Color(0xFF1A1F3A).withAlpha((0.5 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withAlpha((0.1 * 255).toInt()), width: 1),
      ),
      child: Column(
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
                child: Icon(Icons.category_rounded, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                'Oturum Türü',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          DropdownButtonFormField<String>(
            value: _selectedSessionType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withAlpha((0.05 * 255).toInt()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: Colors.white.withAlpha((0.1 * 255).toInt())),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: Colors.white.withAlpha((0.1 * 255).toInt())),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: Color(0xFF00FFA3), width: 2),
              ),
            ),
            dropdownColor: const Color(0xFF1A1F3A),
            style: const TextStyle(color: Colors.white),
            items: sessionTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(fontSize: 14.sp)))).toList(),
            onChanged: (v) => setState(() => _selectedSessionType = v),
            validator: (v) => v == null ? 'Gerekli' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F3A).withAlpha((0.7 * 255).toInt()),
            const Color(0xFF1A1F3A).withAlpha((0.5 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withAlpha((0.1 * 255).toInt()), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.fitness_center_rounded, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                'Egzersiz Seçimi',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          DropdownButtonFormField<int>(
            value: _selectedExerciseId,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withAlpha((0.05 * 255).toInt()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: Colors.white.withAlpha((0.1 * 255).toInt())),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: Colors.white.withAlpha((0.1 * 255).toInt())),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
              ),
            ),
            dropdownColor: const Color(0xFF1A1F3A),
            style: const TextStyle(color: Colors.white),
            items: _exercises.isEmpty
                ? [DropdownMenuItem(value: null, child: Text('Egzersiz bulunamadı', style: TextStyle(fontSize: 14.sp)))]
                : _exercises.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name, style: TextStyle(fontSize: 14.sp)))).toList(),
            onChanged: _exercises.isEmpty ? null : (id) => setState(() => _selectedExerciseId = id),
            validator: (v) => v == null ? 'Lütfen bir egzersiz seçin' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAddSetButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFA3).withAlpha((0.3 * 255).toInt()),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: _addSet,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  'Set Ekle',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F3A).withAlpha((0.5 * 255).toInt()),
            const Color(0xFF1A1F3A).withAlpha((0.3 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withAlpha((0.1 * 255).toInt()), width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.fitness_center_outlined, size: 48.sp, color: Colors.white.withAlpha((0.3 * 255).toInt())),
            SizedBox(height: 12.h),
            Text(
              'Hiçbir set eklenmedi',
              style: TextStyle(color: Colors.white.withAlpha((0.5 * 255).toInt()), fontSize: 15.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFC86DD7)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withAlpha((0.4 * 255).toInt()),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: _isLoading ? null : _saveWorkout,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 18.h),
            child: _isLoading
                ? Center(
                    child: SizedBox(
                      height: 24.w,
                      width: 24.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 24.sp),
                      SizedBox(width: 12.w),
                      Text(
                        'Antrenmanı Kaydet',
                        style: TextStyle(color: Colors.white, fontSize: 17.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SetInput {
  double? weight;
  int? reps;
}

class _SetCard extends StatefulWidget {
  const _SetCard({
    required this.setIndex,
    required this.setInput,
    required this.onRemove,
  });

  final int setIndex;
  final _SetInput setInput;
  final VoidCallback onRemove;

  @override
  State<_SetCard> createState() => _SetCardState();
}

class _SetCardState extends State<_SetCard> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.setInput.weight?.toString() ?? '');
    _repsController = TextEditingController(text: widget.setInput.reps?.toString() ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1F3A).withAlpha((0.7 * 255).toInt()),
            const Color(0xFF1A1F3A).withAlpha((0.5 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withAlpha((0.1 * 255).toInt()), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)]),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${widget.setIndex}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text('Set', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.sp, color: Colors.white)),
                ],
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((0.2 * 255).toInt()),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20.sp),
                ),
                tooltip: 'Seti sil',
              )
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    labelText: 'Ağırlık (kg)',
                    labelStyle: TextStyle(color: Colors.white.withAlpha((0.6 * 255).toInt()), fontSize: 14.sp),
                    filled: true,
                    fillColor: Colors.white.withAlpha((0.05 * 255).toInt()),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.white.withAlpha((0.1 * 255).toInt())),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.white.withAlpha((0.1 * 255).toInt())),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFF00FFA3), width: 2),
                    ),
                    prefixIcon: Icon(Icons.fitness_center_rounded, color: Colors.white.withAlpha((0.5 * 255).toInt()), size: 24.sp),
                    contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Gerekli';
                    if (double.tryParse(v!) == null) return 'Geçerli sayı';
                    return null;
                  },
                  onChanged: (v) => widget.setInput.weight = double.tryParse(v),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: TextFormField(
                  controller: _repsController,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    labelText: 'Tekrar',
                    labelStyle: TextStyle(color: Colors.white.withAlpha((0.6 * 255).toInt()), fontSize: 14.sp),
                    filled: true,
                    fillColor: Colors.white.withAlpha((0.05 * 255).toInt()),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.white.withAlpha((0.1 * 255).toInt())),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.white.withAlpha((0.1 * 255).toInt())),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFF00FFA3), width: 2),
                    ),
                    prefixIcon: Icon(Icons.repeat_rounded, color: Colors.white.withAlpha((0.5 * 255).toInt()), size: 24.sp),
                    contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Gerekli';
                    if (int.tryParse(v!) == null) return 'Geçerli sayı';
                    return null;
                  },
                  onChanged: (v) => widget.setInput.reps = int.tryParse(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
