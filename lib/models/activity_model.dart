import 'package:hive/hive.dart';

part 'activity_model.g.dart';

/// Jenis aktivitas
enum ActivityJenis {
  individu,
  grupBpc,
}

/// Periode evaluasi aktivitas
enum EvaluationPeriod {
  /// Evaluasi harian - dihitung per bulan (≥50% hari = V)
  daily,

  /// Evaluasi mingguan - minimal 1x per minggu
  weekly,

  /// Evaluasi bulanan - dengan threshold tertentu
  monthly,
}

/// Model untuk aktivitas yaumi
@HiveType(typeId: 0)
class ActivityModel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String target;

  @HiveField(3)
  final ActivityJenis jenis;

  @HiveField(4)
  final EvaluationPeriod evaluationPeriod;

  @HiveField(5)
  final String keterangan;

  @HiveField(6)
  final int threshold; // Minimal pencapaian untuk V (untuk monthly/weekly)

  ActivityModel({
    required this.id,
    required this.name,
    required this.target,
    required this.jenis,
    required this.evaluationPeriod,
    this.keterangan = '',
    this.threshold = 1, // Default 1x untuk binary
  });

  /// Apakah evaluasi berdasarkan persentase hari (≥50%)
  bool get isDailyPercentage => evaluationPeriod == EvaluationPeriod.daily;

  /// Apakah evaluasi mingguan
  bool get isWeekly => evaluationPeriod == EvaluationPeriod.weekly;

  /// Apakah evaluasi bulanan dengan count
  bool get isMonthlyCount => evaluationPeriod == EvaluationPeriod.monthly;

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'target': target,
      'jenis': jenis.name,
      'evaluation_period': evaluationPeriod.name,
      'threshold': threshold,
      'keterangan': keterangan,
    };
  }

  /// Create from JSON (Supabase response)
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as int,
      name: json['name'] as String,
      target: json['target'] as String,
      jenis: ActivityJenis.values.firstWhere(
        (e) => e.name == json['jenis'],
        orElse: () => ActivityJenis.individu,
      ),
      evaluationPeriod: EvaluationPeriod.values.firstWhere(
        (e) => e.name == json['evaluation_period'],
        orElse: () => EvaluationPeriod.daily,
      ),
      threshold: json['threshold'] as int? ?? 1,
      keterangan: json['keterangan'] as String? ?? '',
    );
  }

  @override
  String toString() => 'ActivityModel(id: $id, name: $name)';
}
