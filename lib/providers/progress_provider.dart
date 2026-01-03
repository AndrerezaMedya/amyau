import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/activity_constants.dart';
import '../core/services/local_storage_service.dart';
import '../core/utils/timezone_helper.dart';
import '../shared/utils/status_calculator.dart';
import 'auth_provider.dart';

/// Model untuk progress item
class ProgressItem {
  final int activityId;
  final String activityName;
  final int achievedDays;
  final int totalDays;
  final double percentage;

  ProgressItem({
    required this.activityId,
    required this.activityName,
    required this.achievedDays,
    required this.totalDays,
  }) : percentage = totalDays > 0 ? (achievedDays / totalDays) * 100 : 0;
}

/// State untuk progress tracking
class ProgressState {
  final bool isWeekly; // true = weekly, false = monthly
  final DateTime startDate;
  final DateTime endDate;
  final List<ProgressItem> items;
  final double overallPercentage;
  final bool isLoading;

  const ProgressState({
    this.isWeekly = true,
    required this.startDate,
    required this.endDate,
    this.items = const [],
    this.overallPercentage = 0,
    this.isLoading = false,
  });

  ProgressState copyWith({
    bool? isWeekly,
    DateTime? startDate,
    DateTime? endDate,
    List<ProgressItem>? items,
    double? overallPercentage,
    bool? isLoading,
  }) {
    return ProgressState(
      isWeekly: isWeekly ?? this.isWeekly,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      items: items ?? this.items,
      overallPercentage: overallPercentage ?? this.overallPercentage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier untuk progress tracking
class ProgressNotifier extends StateNotifier<ProgressState> {
  final String? userId;

  ProgressNotifier(this.userId)
      : super(ProgressState(
          startDate: _getWeekStart(TimezoneHelper.todayWIB()),
          endDate: TimezoneHelper.todayWIB(),
        )) {
    loadProgress();
  }

  static DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static DateTime _getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Toggle antara weekly dan monthly
  Future<void> togglePeriod() async {
    final isWeekly = !state.isWeekly;
    final now = TimezoneHelper.todayWIB();

    DateTime startDate;
    DateTime endDate = now;

    if (isWeekly) {
      startDate = _getWeekStart(now);
    } else {
      startDate = _getMonthStart(now);
    }

    state = state.copyWith(
      isWeekly: isWeekly,
      startDate: startDate,
      endDate: endDate,
    );

    await loadProgress();
  }

  /// Load progress data
  Future<void> loadProgress() async {
    if (userId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final logs = LocalStorageService.getDailyLogsByDateRange(
        state.startDate,
        state.endDate,
      );

      final totalDays = state.endDate.difference(state.startDate).inDays + 1;
      final achievementMap = StatusCalculator.calculateAchievementCount(logs);

      final items = ActivityConstants.activities.map((activity) {
        return ProgressItem(
          activityId: activity.id,
          activityName: activity.name,
          achievedDays: achievementMap[activity.id] ?? 0,
          totalDays: totalDays,
        );
      }).toList();

      // Calculate overall
      int totalAchieved = 0;
      int totalPossible = 0;

      for (final item in items) {
        totalAchieved += item.achievedDays;
        totalPossible += item.totalDays;
      }

      final overallPercentage =
          totalPossible > 0 ? (totalAchieved / totalPossible) * 100 : 0.0;

      state = state.copyWith(
        items: items,
        overallPercentage: overallPercentage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Navigate to previous period
  Future<void> previousPeriod() async {
    DateTime newStart;
    DateTime newEnd;

    if (state.isWeekly) {
      newEnd = state.startDate.subtract(const Duration(days: 1));
      newStart = _getWeekStart(newEnd);
    } else {
      newStart = DateTime(state.startDate.year, state.startDate.month - 1, 1);
      newEnd = DateTime(newStart.year, newStart.month + 1, 0);
    }

    state = state.copyWith(startDate: newStart, endDate: newEnd);
    await loadProgress();
  }

  /// Navigate to next period
  Future<void> nextPeriod() async {
    final now = TimezoneHelper.todayWIB();
    DateTime newStart;
    DateTime newEnd;

    if (state.isWeekly) {
      newStart = state.endDate.add(const Duration(days: 1));
      newEnd = newStart.add(const Duration(days: 6));
    } else {
      newStart = DateTime(state.startDate.year, state.startDate.month + 1, 1);
      newEnd = DateTime(newStart.year, newStart.month + 1, 0);
    }

    // Don't go beyond current date
    if (newEnd.isAfter(now)) {
      newEnd = now;
    }

    if (newStart.isBefore(now)) {
      state = state.copyWith(startDate: newStart, endDate: newEnd);
      await loadProgress();
    }
  }
}

/// Provider untuk progress
final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  final user = ref.watch(currentUserProvider);
  return ProgressNotifier(user?.id);
});

/// Provider untuk weekly achievement per aktivitas
final weeklyAchievementProvider = Provider.family<int, int>((ref, activityId) {
  final progress = ref.watch(progressProvider);
  final item = progress.items.firstWhere(
    (i) => i.activityId == activityId,
    orElse: () => ProgressItem(
      activityId: activityId,
      activityName: '',
      achievedDays: 0,
      totalDays: 7,
    ),
  );
  return item.achievedDays;
});

/// Provider untuk streak per aktivitas
final streakProvider = Provider.family<int, int>((ref, activityId) {
  final logs = LocalStorageService.getAllDailyLogs();
  return StatusCalculator.calculateStreak(logs, activityId);
});
