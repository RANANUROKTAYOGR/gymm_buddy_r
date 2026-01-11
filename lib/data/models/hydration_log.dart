class HydrationLog {
  final int? id;
  final int userId;
  final int amountMl;
  final DateTime date;

  HydrationLog({
    this.id,
    required this.userId,
    required this.amountMl,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount_ml': amountMl,
      'date': date.toIso8601String().split('T')[0], // Only date part
    };
  }

  factory HydrationLog.fromMap(Map<String, dynamic> map) {
    return HydrationLog(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      amountMl: map['amount_ml'] as int,
      date: DateTime.parse(map['date'] as String),
    );
  }

  HydrationLog copyWith({int? id, int? userId, int? amountMl, DateTime? date}) {
    return HydrationLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amountMl: amountMl ?? this.amountMl,
      date: date ?? this.date,
    );
  }
}
