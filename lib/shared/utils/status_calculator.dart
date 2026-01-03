import '../../models/activity_model.dart';
import '../../models/daily_log_model.dart';
import '../../core/constants/activity_constants.dart';

/// Helper class untuk menghitung status V/X aktivitas
///
/// Sistem Evaluasi:
/// - Daily: ≥50% hari tercapai dalam bulan = V
/// - Weekly: ≥threshold kali per minggu = V
/// - Monthly: ≥threshold kali per bulan = V
class StatusCalculator {
  StatusCalculator._();

  /// Hitung status HARIAN (checklist per hari)
  /// Ini untuk daily log, value 1 = sudah, 0 = belum
  static String calculateDailyStatus(int value) {
    return value >= 1 ? 'V' : 'X';
  }

  /// Hitung status EVALUASI BULANAN untuk satu aktivitas
  ///
  /// [achievedDays] - jumlah hari yang diceklis dalam periode
  /// [totalDaysInMonth] - total hari dalam bulan (untuk evaluasi daily)
  /// [weeksInMonth] - jumlah minggu dalam bulan (untuk evaluasi weekly)
  static String calculateMonthlyEvaluation(
    ActivityModel activity,
    int achievedDays,
    int totalDaysInMonth,
    int weeksInMonth,
  ) {
    switch (activity.evaluationPeriod) {
      case EvaluationPeriod.daily:
        // ≥50% hari dalam bulan = V
        final percentage =
            totalDaysInMonth > 0 ? (achievedDays / totalDaysInMonth) * 100 : 0;
        return percentage >= 50 ? 'V' : 'X';

      case EvaluationPeriod.monthly:
        // ≥threshold kali dalam bulan = V
        return achievedDays >= activity.threshold ? 'V' : 'X';

      case EvaluationPeriod.weekly:
        // Untuk weekly, perlu cek per minggu
        // Ini akan dihandle oleh calculateWeeklyEvaluation
        return achievedDays >= activity.threshold ? 'V' : 'X';
    }
  }

  /// Hitung status EVALUASI MINGGUAN untuk aktivitas weekly
  ///
  /// [achievedDaysInWeek] - jumlah hari yang diceklis dalam minggu ini
  static String calculateWeeklyEvaluation(
    ActivityModel activity,
    int achievedDaysInWeek,
  ) {
    if (activity.evaluationPeriod != EvaluationPeriod.weekly) {
      return 'X';
    }
    return achievedDaysInWeek >= activity.threshold ? 'V' : 'X';
  }

  /// Hitung evaluasi bulanan untuk semua aktivitas
  ///
  /// Mengembalikan map: activityId -> { 'status': V/X, 'achieved': count, 'target': threshold }
  static Map<int, Map<String, dynamic>> calculateFullMonthlyEvaluation(
    List<DailyLogModel> logsInMonth,
    int totalDaysInMonth,
    int weeksInMonth,
  ) {
    final Map<int, Map<String, dynamic>> result = {};

    for (final activity in ActivityConstants.activities) {
      final activityLogs = logsInMonth
          .where((log) => log.activityId == activity.id && log.status == 'V')
          .toList();
      final achievedCount = activityLogs.length;

      String targetText;
      String status;

      switch (activity.evaluationPeriod) {
        case EvaluationPeriod.daily:
          final percentage = totalDaysInMonth > 0
              ? (achievedCount / totalDaysInMonth) * 100
              : 0;
          status = percentage >= 50 ? 'V' : 'X';
          targetText = '≥50% (${(totalDaysInMonth / 2).ceil()} hari)';
          break;

        case EvaluationPeriod.monthly:
          status = achievedCount >= activity.threshold ? 'V' : 'X';
          targetText = '≥${activity.threshold}x/bulan';
          break;

        case EvaluationPeriod.weekly:
          // Untuk weekly, perlu evaluasi per minggu
          status = achievedCount >= activity.threshold ? 'V' : 'X';
          targetText = '≥${activity.threshold}x/minggu';
          break;
      }

      result[activity.id] = {
        'status': status,
        'achieved': achievedCount,
        'target': activity.threshold,
        'targetText': targetText,
        'period': activity.evaluationPeriod.name,
      };
    }

    return result;
  }

  /// Hitung persentase pencapaian harian (untuk summary card)
  static double calculateDailyAchievement(List<DailyLogModel> logs) {
    if (logs.isEmpty) return 0;
    final achievedCount = logs.where((log) => log.status == 'V').length;
    return (achievedCount / ActivityConstants.activities.length) * 100;
  }

  /// Hitung pencapaian per aktivitas dalam periode
  static Map<int, int> calculateAchievementCount(List<DailyLogModel> logs) {
    final Map<int, int> result = {};

    for (final activity in ActivityConstants.activities) {
      final activityLogs = logs.where((log) => log.activityId == activity.id);
      result[activity.id] =
          activityLogs.where((log) => log.status == 'V').length;
    }

    return result;
  }

  /// Get warna indikator berdasarkan persentase
  static String getAchievementColor(double percentage) {
    if (percentage >= 80) return 'green';
    if (percentage >= 50) return 'yellow';
    return 'red';
  }

  /// Get emoji berdasarkan persentase
  static String getAchievementEmoji(double percentage) {
    if (percentage >= 80) return '🌟';
    if (percentage >= 60) return '💪';
    if (percentage >= 40) return '📈';
    return '🤲';
  }

  /// Generate summary text untuk AI
  static String generateSummaryForAI(List<DailyLogModel> logs) {
    final buffer = StringBuffer();
    buffer.writeln('Ringkasan Pencapaian Ibadah:');
    buffer.writeln('');

    for (final activity in ActivityConstants.activities) {
      final log = logs.where((l) => l.activityId == activity.id).firstOrNull;
      final status = log?.status ?? '-';
      final value = log?.value ?? 0;

      buffer.writeln('${activity.id}. ${activity.name}');
      buffer.writeln('   Target: ${activity.target}');
      buffer.writeln('   Pencapaian: $value% | Status: $status');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Hitung streak (hari berturut-turut tercapai)
  static int calculateStreak(List<DailyLogModel> logs, int activityId) {
    final activityLogs = logs
        .where((log) => log.activityId == activityId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime? previousDate;

    for (final log in activityLogs) {
      if (log.status != 'V') break;

      if (previousDate == null) {
        streak = 1;
        previousDate = log.date;
      } else {
        final diff = previousDate.difference(log.date).inDays;
        if (diff == 1) {
          streak++;
          previousDate = log.date;
        } else {
          break;
        }
      }
    }

    return streak;
  }
}
