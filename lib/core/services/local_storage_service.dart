import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/daily_log_model.dart';
import '../../models/user_model.dart';
import '../../models/weekly_summary_model.dart';

/// Service untuk local storage menggunakan Hive
/// DATA TER-ISOLASI PER USER untuk mencegah kebocoran data
class LocalStorageService {
  // Global boxes (tidak per-user)
  static const String _userBox = 'user_settings';
  static const String _pendingSyncBox = 'pending_sync';

  // User-specific box names generator
  static String _getDailyLogsBoxName(String userId) => 'daily_logs_$userId';
  static String _getWeeklySummaryBoxName(String userId) =>
      'weekly_summary_$userId';

  // Global box instances
  static Box<UserModel>? _userBoxInstance;
  static Box<String>? _pendingSyncBoxInstance;

  // User-specific box instances
  static Box<DailyLogModel>? _dailyLogsBoxInstance;
  static Box<WeeklySummaryModel>? _weeklySummaryBoxInstance;
  static String? _currentUserId;

  /// Initialize Hive - only register adapters and open global boxes
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DailyLogModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(WeeklySummaryModelAdapter());
    }

    // Open global boxes only (user box for storing current user info)
    _userBoxInstance = await Hive.openBox<UserModel>(_userBox);
    _pendingSyncBoxInstance = await Hive.openBox<String>(_pendingSyncBox);

    debugPrint('LocalStorage: Global boxes initialized');
  }

  /// Open user-specific boxes saat login
  /// WAJIB dipanggil setelah login berhasil
  static Future<void> openUserBoxes(String userId) async {
    // Close previous user boxes jika ada
    await closeUserBoxes();

    _currentUserId = userId;

    // Open boxes khusus untuk user ini
    _dailyLogsBoxInstance = await Hive.openBox<DailyLogModel>(
      _getDailyLogsBoxName(userId),
    );
    _weeklySummaryBoxInstance = await Hive.openBox<WeeklySummaryModel>(
      _getWeeklySummaryBoxName(userId),
    );

    debugPrint('LocalStorage: Opened boxes for user $userId');
  }

  /// Close user-specific boxes saat logout
  static Future<void> closeUserBoxes() async {
    try {
      if (_dailyLogsBoxInstance?.isOpen == true) {
        await _dailyLogsBoxInstance?.close();
      }
      if (_weeklySummaryBoxInstance?.isOpen == true) {
        await _weeklySummaryBoxInstance?.close();
      }
    } catch (e) {
      debugPrint('Error closing user boxes: $e');
    }

    _dailyLogsBoxInstance = null;
    _weeklySummaryBoxInstance = null;
    _currentUserId = null;

    debugPrint('LocalStorage: User boxes closed');
  }

  /// Clear all data for current user (untuk fresh fetch dari server)
  static Future<void> clearCurrentUserData() async {
    await _dailyLogsBoxInstance?.clear();
    await _weeklySummaryBoxInstance?.clear();
    debugPrint('LocalStorage: Cleared data for user $_currentUserId');
  }

  /// Check if user boxes are open
  static bool get isUserBoxesOpen =>
      _dailyLogsBoxInstance != null && _dailyLogsBoxInstance!.isOpen;

  /// Get current user ID
  static String? get currentUserId => _currentUserId;

  // ==================== Daily Logs ====================

  /// Get all daily logs for current user
  static List<DailyLogModel> getAllDailyLogs() {
    if (!isUserBoxesOpen) {
      debugPrint(
          'LocalStorage WARNING: User boxes not open, returning empty list');
      return [];
    }
    return _dailyLogsBoxInstance?.values.toList() ?? [];
  }

  /// Get daily logs by date for current user
  static List<DailyLogModel> getDailyLogsByDate(DateTime date) {
    if (!isUserBoxesOpen) return [];
    final dateString = date.toIso8601String().split('T')[0];
    return _dailyLogsBoxInstance?.values
            .where(
                (log) => log.date.toIso8601String().split('T')[0] == dateString)
            .toList() ??
        [];
  }

  /// Get daily logs by user ID and date (double-check userId)
  static List<DailyLogModel> getDailyLogsByUserAndDate(
      String userId, DateTime date) {
    if (!isUserBoxesOpen || _currentUserId != userId) return [];
    return getDailyLogsByDate(date);
  }

  /// Get daily logs by date range (for weekly/monthly)
  static List<DailyLogModel> getDailyLogsByDateRange(
      DateTime startDate, DateTime endDate) {
    if (!isUserBoxesOpen) return [];
    return _dailyLogsBoxInstance?.values.where((log) {
          return log.date
                  .isAfter(startDate.subtract(const Duration(days: 1))) &&
              log.date.isBefore(endDate.add(const Duration(days: 1)));
        }).toList() ??
        [];
  }

  /// Get daily log by activity and date
  static DailyLogModel? getDailyLog(int activityId, DateTime date) {
    if (!isUserBoxesOpen) return null;
    final dateString = date.toIso8601String().split('T')[0];
    try {
      return _dailyLogsBoxInstance?.values.firstWhere(
        (log) =>
            log.activityId == activityId &&
            log.date.toIso8601String().split('T')[0] == dateString,
      );
    } catch (e) {
      return null;
    }
  }

  /// Save daily log
  static Future<void> saveDailyLog(DailyLogModel log) async {
    if (!isUserBoxesOpen) {
      debugPrint('LocalStorage ERROR: Cannot save log - user boxes not open');
      return;
    }
    await _dailyLogsBoxInstance?.put(log.id, log);

    // Mark for sync if not synced
    if (!log.isSynced) {
      await _pendingSyncBoxInstance?.put(log.id, 'daily_log');
    }
  }

  /// Bulk save daily logs (untuk fetch dari server)
  static Future<void> saveDailyLogs(List<DailyLogModel> logs) async {
    if (!isUserBoxesOpen) return;
    for (final log in logs) {
      await _dailyLogsBoxInstance?.put(log.id, log);
    }
  }

  /// Get unsynced logs
  static List<DailyLogModel> getUnsyncedLogs() {
    if (!isUserBoxesOpen) return [];
    return _dailyLogsBoxInstance?.values
            .where((log) => !log.isSynced)
            .toList() ??
        [];
  }

  /// Mark log as synced
  static Future<void> markAsSynced(String logId) async {
    final log = _dailyLogsBoxInstance?.get(logId);
    if (log != null) {
      await _dailyLogsBoxInstance?.put(logId, log.copyWith(isSynced: true));
      await _pendingSyncBoxInstance?.delete(logId);
    }
  }

  // ==================== User ====================

  /// Get current user
  static UserModel? getCurrentUser() {
    return _userBoxInstance?.get('current_user');
  }

  /// Save current user
  static Future<void> saveCurrentUser(UserModel user) async {
    await _userBoxInstance?.put('current_user', user);
  }

  /// Clear current user (logout)
  static Future<void> clearCurrentUser() async {
    await _userBoxInstance?.delete('current_user');
  }

  // ==================== Weekly Summary ====================

  /// Get weekly summaries for current user
  static List<WeeklySummaryModel> getWeeklySummaries() {
    if (!isUserBoxesOpen) return [];
    return _weeklySummaryBoxInstance?.values.toList() ?? [];
  }

  /// Save weekly summary
  static Future<void> saveWeeklySummary(WeeklySummaryModel summary) async {
    if (!isUserBoxesOpen) return;
    await _weeklySummaryBoxInstance?.put(summary.id, summary);
  }

  // ==================== Utilities ====================

  /// Clear all data (for logout) - closes user boxes and clears user info
  static Future<void> clearAll() async {
    // Clear current user data from user-specific boxes
    await clearCurrentUserData();

    // Close user-specific boxes
    await closeUserBoxes();

    // Clear global user info
    await _userBoxInstance?.clear();
    await _pendingSyncBoxInstance?.clear();

    debugPrint('LocalStorage: All data cleared for logout');
  }

  /// Get pending sync count
  static int get pendingSyncCount => _pendingSyncBoxInstance?.length ?? 0;
}
