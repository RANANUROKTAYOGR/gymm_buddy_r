import 'package:flutter/material.dart';

class Appointment {
  final int? id;
  final int userId;
  final int? trainerId;
  final int? gymBranchId;
  final DateTime appointmentDate;
  final String? notes;
  final String status;
  final DateTime? createdAt;
  final TimeOfDay? appointmentTime; // Randevu saati

  Appointment({
    this.id,
    required this.userId,
    this.trainerId,
    this.gymBranchId,
    required this.appointmentDate,
    this.notes,
    this.status = 'scheduled',
    this.createdAt,
    this.appointmentTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'trainer_id': trainerId,
      'gym_branch_id': gymBranchId,
      'appointment_date': appointmentDate.toIso8601String(),
      'notes': notes,
      'status': status,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'appointment_time': appointmentTime != null
          ? '${appointmentTime!.hour}:${appointmentTime!.minute}'
          : null,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    TimeOfDay? time;
    if (map['appointment_time'] != null) {
      final parts = (map['appointment_time'] as String).split(':');
      if (parts.length == 2) {
        time = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    return Appointment(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      trainerId: map['trainer_id'] as int?,
      gymBranchId: map['gym_branch_id'] as int?,
      appointmentDate: DateTime.parse(map['appointment_date'] as String),
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'scheduled',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      appointmentTime: time,
    );
  }

  Appointment copyWith({
    int? id,
    int? userId,
    int? trainerId,
    int? gymBranchId,
    DateTime? appointmentDate,
    String? notes,
    String? status,
    DateTime? createdAt,
    TimeOfDay? appointmentTime,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      trainerId: trainerId ?? this.trainerId,
      gymBranchId: gymBranchId ?? this.gymBranchId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      appointmentTime: appointmentTime ?? this.appointmentTime,
    );
  }
}
