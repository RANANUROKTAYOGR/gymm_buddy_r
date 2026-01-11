/// Maksimum güç (1RM - One Rep Max) hesaplayıcı sınıfı
/// Epley Formülü'nü kullanır: Ağırlık * (1 + Tekrar/30)
class OneRepMaxCalculator {
  /// Verilen ağırlık ve tekrar sayısına göre tahmini 1RM değerini hesaplar
  /// 
  /// [weight] - Kaldırılan ağırlık (kg cinsinden)
  /// [reps] - Yapılan tekrar sayısı
  /// 
  /// Returns: Tahmini 1RM değeri (kg cinsinden)
  /// 
  /// Örnek: 
  /// ```dart
  /// double oneRM = OneRepMaxCalculator.calculate(100, 8);
  /// // Sonuç: 126.67 kg
  /// ```
  static double calculate(double weight, int reps) {
    if (weight <= 0 || reps <= 0) {
      return 0;
    }
    
    // Epley Formülü: Ağırlık * (1 + Tekrar/30)
    return weight * (1 + reps / 30);
  }
  
  /// 1RM değerini formatlanmış string olarak döndürür
  /// 
  /// [weight] - Kaldırılan ağırlık (kg cinsinden)
  /// [reps] - Yapılan tekrar sayısı
  /// 
  /// Returns: "Tahmini 1RM: X.X kg" formatında string
  static String calculateFormatted(double weight, int reps) {
    final oneRM = calculate(weight, reps);
    if (oneRM <= 0) {
      return 'Tahmini 1RM: - kg';
    }
    return 'Tahmini 1RM: ${oneRM.toStringAsFixed(1)} kg';
  }
}
