class Subscription {
  final int? id;
  final int userId;
  final int gymBranchId;
  final String subscriptionType;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final bool isActive;
  final DateTime? createdAt;

  Subscription({
    this.id,
    required this.userId,
    required this.gymBranchId,
    required this.subscriptionType,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.isActive,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'gym_branch_id': gymBranchId,
      'subscription_type': subscriptionType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'amount': amount,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      gymBranchId: map['gym_branch_id'] as int,
      subscriptionType: map['subscription_type'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      amount: (map['amount'] as num).toDouble(),
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Subscription copyWith({
    int? id,
    int? userId,
    int? gymBranchId,
    String? subscriptionType,
    DateTime? startDate,
    DateTime? endDate,
    double? amount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gymBranchId: gymBranchId ?? this.gymBranchId,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      amount: amount ?? this.amount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
