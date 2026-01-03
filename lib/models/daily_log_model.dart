import 'package:hive/hive.dart';

part 'daily_log_model.g.dart';

/// Model untuk log harian aktivitas
@HiveType(typeId: 1)
class DailyLogModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String odIduserId;

  @HiveField(2)
  final int activityId;

  @HiveField(3)
  final DateTime date;

  /// Nilai input:
  /// - Untuk percentage type: 0-100 (persentase)
  /// - Untuk binary type: 0 (tidak) atau 1 (ya)
  @HiveField(4)
  final int value;

  /// Status evaluasi: 'V' atau 'X'
  @HiveField(5)
  final String status;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  /// Flag untuk sync ke Supabase
  @HiveField(8)
  final bool isSynced;

  DailyLogModel({
    required this.id,
    required this.odIduserId,
    required this.activityId,
    required this.date,
    required this.value,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  /// Copy with untuk update
  DailyLogModel copyWith({
    String? id,
    String? odIduserId,
    int? activityId,
    DateTime? date,
    int? value,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return DailyLogModel(
      id: id ?? this.id,
      odIduserId: odIduserId ?? this.odIduserId,
      activityId: activityId ?? this.activityId,
      date: date ?? this.date,
      value: value ?? this.value,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': odIduserId,
      'activity_id': activityId,
      'date': date.toIso8601String().split('T')[0],
      'value': value,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from JSON (Supabase response)
  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      id: json['id'] as String,
      odIduserId: json['user_id'] as String,
      activityId: json['activity_id'] as int,
      date: DateTime.parse(json['date'] as String),
      value: json['value'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isSynced: true,
    );
  }

  @override
  String toString() =>
      'DailyLogModel(activityId: $activityId, date: $date, value: $value, status: $status)';
}
