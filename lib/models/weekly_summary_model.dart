import 'package:hive/hive.dart';

part 'weekly_summary_model.g.dart';

/// Model untuk ringkasan mingguan dari AI
@HiveType(typeId: 3)
class WeeklySummaryModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String odIduserId;

  @HiveField(2)
  final DateTime weekStart;

  @HiveField(3)
  final DateTime weekEnd;

  /// Ringkasan dari AI dalam Bahasa Indonesia
  @HiveField(4)
  final String aiReview;

  /// Statistik pencapaian (jumlah V)
  @HiveField(5)
  final int totalAchieved;

  /// Total aktivitas yang di-track
  @HiveField(6)
  final int totalActivities;

  @HiveField(7)
  final DateTime createdAt;

  WeeklySummaryModel({
    required this.id,
    required this.odIduserId,
    required this.weekStart,
    required this.weekEnd,
    required this.aiReview,
    required this.totalAchieved,
    required this.totalActivities,
    required this.createdAt,
  });

  /// Persentase pencapaian
  double get achievementPercentage {
    if (totalActivities == 0) return 0;
    return (totalAchieved / totalActivities) * 100;
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': odIduserId,
      'week_start': weekStart.toIso8601String().split('T')[0],
      'week_end': weekEnd.toIso8601String().split('T')[0],
      'ai_review': aiReview,
      'total_achieved': totalAchieved,
      'total_activities': totalActivities,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON (Supabase response)
  factory WeeklySummaryModel.fromJson(Map<String, dynamic> json) {
    return WeeklySummaryModel(
      id: json['id'] as String,
      odIduserId: json['user_id'] as String,
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      aiReview: json['ai_review'] as String,
      totalAchieved: json['total_achieved'] as int,
      totalActivities: json['total_activities'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  String toString() =>
      'WeeklySummaryModel(weekStart: $weekStart, achieved: $totalAchieved/$totalActivities)';
}
