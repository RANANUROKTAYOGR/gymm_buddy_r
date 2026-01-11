import 'package:flutter/foundation.dart';

/// Spor salonuna giriş/çıkış ve ziyaretçi sayısını yönetir
class GymEntryService extends ChangeNotifier {
  // Singleton pattern
  static final GymEntryService _instance = GymEntryService._internal();
  factory GymEntryService() => _instance;
  GymEntryService._internal();

  bool _isCheckedIn = false;
  String? _currentGymName;
  DateTime? _checkInTime;

  // Her salon için default kullanıcı sayıları
  final Map<String, Map<String, int>> _gymUserCounts = {
    'FitZone Merkez': {'female': 12, 'male': 18},
    'PowerGym Şube 1': {'female': 8, 'male': 15},
    'IronFit Spor Salonu': {'female': 10, 'male': 20},
    'FlexFit Gym': {'female': 15, 'male': 12},
    'MuscleLab': {'female': 6, 'male': 22},
  };

  bool get isCheckedIn => _isCheckedIn;
  String? get currentGymName => _currentGymName;
  DateTime? get checkInTime => _checkInTime;

  int getFemaleCount(String gymName) {
    return _gymUserCounts[gymName]?['female'] ?? 10;
  }

  int getMaleCount(String gymName) {
    return _gymUserCounts[gymName]?['male'] ?? 15;
  }

  int getTotalCount(String gymName) {
    return getFemaleCount(gymName) + getMaleCount(gymName);
  }

  int get femaleCount => _currentGymName != null ? getFemaleCount(_currentGymName!) : 0;
  int get maleCount => _currentGymName != null ? getMaleCount(_currentGymName!) : 0;
  int get totalCount => femaleCount + maleCount;

  /// Salondan giriş yap
  Future<void> checkIn(String gymName) async {
    // Salon yoksa default değerler ekle
    if (!_gymUserCounts.containsKey(gymName)) {
      _gymUserCounts[gymName] = {'female': 10, 'male': 15};
    }
    
    _isCheckedIn = true;
    _currentGymName = gymName;
    _checkInTime = DateTime.now();
    
    // Giriş yaptığında erkek sayısını arttır
    _gymUserCounts[gymName]!['male'] = (_gymUserCounts[gymName]!['male'] ?? 0) + 1;
    notifyListeners();
  }

  /// Salondan çıkış yap
  Future<void> checkOut() async {
    if (_isCheckedIn && _currentGymName != null) {
      // Erkek sayısını azalt (minimum 0)
      final currentMale = _gymUserCounts[_currentGymName]!['male'] ?? 0;
      if (currentMale > 0) {
        _gymUserCounts[_currentGymName!]!['male'] = currentMale - 1;
      }
    }
    _isCheckedIn = false;
    _currentGymName = null;
    _checkInTime = null;
    notifyListeners();
  }

  /// Sayıları reset et
  void reset() {
    _isCheckedIn = false;
    _currentGymName = null;
    _checkInTime = null;
    // Salon sayılarını resetleme, sadece giriş durumunu sıfırla
    notifyListeners();
  }

  /// Kadın sayısı ekle (belirli bir salon için)
  void addFemale(String gymName) {
    if (!_gymUserCounts.containsKey(gymName)) {
      _gymUserCounts[gymName] = {'female': 10, 'male': 15};
    }
    _gymUserCounts[gymName]!['female'] = (_gymUserCounts[gymName]!['female'] ?? 0) + 1;
    notifyListeners();
  }

  /// Erkek sayısı ekle (belirli bir salon için)
  void addMale(String gymName) {
    if (!_gymUserCounts.containsKey(gymName)) {
      _gymUserCounts[gymName] = {'female': 10, 'male': 15};
    }
    _gymUserCounts[gymName]!['male'] = (_gymUserCounts[gymName]!['male'] ?? 0) + 1;
    notifyListeners();
  }
}
