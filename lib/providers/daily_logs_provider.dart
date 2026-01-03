import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/activity_model.dart';
import '../models/daily_log_model.dart';
import '../core/constants/activity_constants.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/sync_service.dart';
import '../core/utils/timezone_helper.dart';
import '../shared/utils/status_calculator.dart';
import 'auth_provider.dart';

/// State untuk daily logs
class DailyLogsState {
  final DateTime selectedDate;
  final List<DailyLogModel> logs;
  final bool isLoading;
  final String? errorMessage;
  final bool isSyncing;

  const DailyLogsState({
    required this.selectedDate,
    this.logs = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isSyncing = false,
  });

  DailyLogsState copyWith({
    DateTime? selectedDate,
    List<DailyLogModel>? logs,
    bool? isLoading,
    String? errorMessage,
    bool? isSyncing,
  }) {
    return DailyLogsState(
      selectedDate: selectedDate ?? this.selectedDate,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  /// Get log by activity ID
  DailyLogModel? getLogByActivityId(int activityId) {
    try {
      return logs.firstWhere((log) => log.activityId == activityId);
    } catch (e) {
      return null;
    }
  }

  /// Hitung total V untuk hari ini
  int get totalAchieved => logs.where((log) => log.status == 'V').length;

  /// Persentase pencapaian
  double get achievementPercentage {
    if (logs.isEmpty) return 0;
    return (totalAchieved / ActivityConstants.activities.length) * 100;
  }
}

/// Notifier untuk daily logs
class DailyLogsNotifier extends StateNotifier<DailyLogsState> {
  final String? userId;
  final Uuid _uuid = const Uuid();

  DailyLogsNotifier(this.userId)
      : super(DailyLogsState(selectedDate: TimezoneHelper.todayWIB())) {
    _initializeAndLoad();
  }

  /// Initialize: fetch from server first, then load from local
  Future<void> _initializeAndLoad() async {
    if (userId == null) return;

    // Pastikan user boxes sudah dibuka
    if (!LocalStorageService.isUserBoxesOpen) {
      await LocalStorageService.openUserBoxes(userId!);
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Fetch latest data from Supabase first (akan clear & replace local)
      final fetchResult = await SyncService.fetchFromSupabase(userId!);

      // Jika fetch sukses, log hasilnya
      if (fetchResult.success) {
        // Data sudah fresh dari server
      }

      // Also sync any pending local changes (untuk data offline sebelumnya)
      await SyncService.syncToSupabase();
    } catch (e) {
      // Continue even if fetch fails - use local data
    }

    // Then load from local storage
    await loadLogs();
  }

  /// Load logs dari local storage
  Future<void> loadLogs() async {
    if (userId == null) return;

    // Pastikan user boxes sudah dibuka
    if (!LocalStorageService.isUserBoxesOpen) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final logs = LocalStorageService.getDailyLogsByDate(state.selectedDate);
      state = state.copyWith(logs: logs, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data',
      );
    }
  }

  /// Change selected date
  Future<void> changeDate(DateTime date) async {
    state = state.copyWith(selectedDate: date);
    await loadLogs();
  }

  /// Update or create log for an activity
  Future<void> updateLog(int activityId, int value) async {
    if (userId == null) return;

    // Status harian: 1 = sudah (V), 0 = belum (X)
    final status = StatusCalculator.calculateDailyStatus(value);
    final existingLog = state.getLogByActivityId(activityId);

    final log = DailyLogModel(
      id: existingLog?.id ?? _uuid.v4(),
      odIduserId: userId!,
      activityId: activityId,
      date: state.selectedDate,
      value: value,
      status: status,
      createdAt: existingLog?.createdAt ?? TimezoneHelper.nowWIB(),
      updatedAt: TimezoneHelper.nowWIB(),
      isSynced: false,
    );

    // Save to local storage
    await LocalStorageService.saveDailyLog(log);

    // Update state
    final updatedLogs = List<DailyLogModel>.from(state.logs);
    final index = updatedLogs.indexWhere((l) => l.activityId == activityId);
    if (index >= 0) {
      updatedLogs[index] = log;
    } else {
      updatedLogs.add(log);
    }

    state = state.copyWith(logs: updatedLogs);

    // Try to sync in background
    _syncInBackground();
  }

  /// Sync to Supabase in background
  Future<void> _syncInBackground() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true);
    await SyncService.syncToSupabase();
    state = state.copyWith(isSyncing: false);
  }

  /// Force sync
  Future<void> forceSync() async {
    state = state.copyWith(isSyncing: true);
    final result = await SyncService.syncToSupabase();
    state = state.copyWith(
      isSyncing: false,
      errorMessage: result.success ? null : result.message,
    );
  }

  /// Refresh dari Supabase
  Future<void> refreshFromServer() async {
    if (userId == null) return;

    state = state.copyWith(isLoading: true);
    await SyncService.fetchFromSupabase(userId!);
    await loadLogs();
  }
}

/// Provider untuk daily logs
final dailyLogsProvider =
    StateNotifierProvider<DailyLogsNotifier, DailyLogsState>((ref) {
  final user = ref.watch(currentUserProvider);
  return DailyLogsNotifier(user?.id);
});

/// Provider untuk list aktivitas (sorted by ID)
final activitiesProvider = Provider<List<ActivityModel>>((ref) {
  return ActivityConstants.sortedActivities;
});

/// Provider untuk selected date
final selectedDateProvider = Provider<DateTime>((ref) {
  return ref.watch(dailyLogsProvider).selectedDate;
});

/// Provider untuk achievement percentage
final dailyAchievementProvider = Provider<double>((ref) {
  return ref.watch(dailyLogsProvider).achievementPercentage;
});

/// Provider untuk pending sync count
final pendingSyncCountProvider = Provider<int>((ref) {
  return LocalStorageService.pendingSyncCount;
});
