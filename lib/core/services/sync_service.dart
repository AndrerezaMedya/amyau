import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/daily_log_model.dart';
import '../constants/supabase_constants.dart';
import 'local_storage_service.dart';

/// Service untuk sinkronisasi data antara local storage dan Supabase
/// SUPABASE adalah SOURCE OF TRUTH
class SyncService {
  static final _supabase = Supabase.instance.client;

  /// Check koneksi internet
  static Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Pastikan user ada di tabel public.users
  /// Jika tidak ada, buat entry baru dari auth session
  static Future<bool> _ensureUserExists(String userId) async {
    try {
      // Cek apakah user sudah ada
      final existing = await _supabase
          .from(SupabaseConstants.usersTable)
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing != null) {
        return true; // User sudah ada
      }

      // User tidak ada, buat dari session data
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null || currentUser.id != userId) {
        debugPrint('SyncService: Cannot create user - no valid session');
        return false;
      }

      // Insert user baru
      await _supabase.from(SupabaseConstants.usersTable).insert({
        'id': userId,
        'username': currentUser.email ?? 'user_$userId',
        'full_name':
            currentUser.userMetadata?['full_name'] ?? currentUser.email,
        'gender': currentUser.userMetadata?['gender'],
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('SyncService: Created missing user profile for $userId');
      return true;
    } catch (e) {
      debugPrint('SyncService: Error ensuring user exists: $e');
      return false;
    }
  }

  /// Sync semua data pending ke Supabase
  static Future<SyncResult> syncToSupabase() async {
    if (!await hasInternetConnection()) {
      return SyncResult(
        success: false,
        message: 'Tidak ada koneksi internet',
        syncedCount: 0,
      );
    }

    // Pastikan user boxes sudah open
    if (!LocalStorageService.isUserBoxesOpen) {
      return SyncResult(
        success: false,
        message: 'Local storage belum siap',
        syncedCount: 0,
      );
    }

    final unsyncedLogs = LocalStorageService.getUnsyncedLogs();
    if (unsyncedLogs.isEmpty) {
      return SyncResult(
        success: true,
        message: 'Tidak ada data untuk sync',
        syncedCount: 0,
      );
    }

    // Pastikan user ada di tabel users sebelum sync
    final userId = unsyncedLogs.first.odIduserId;
    final userExists = await _ensureUserExists(userId);
    if (!userExists) {
      return SyncResult(
        success: false,
        message: 'User belum terdaftar di database',
        syncedCount: 0,
      );
    }

    int syncedCount = 0;
    List<String> errors = [];

    for (final log in unsyncedLogs) {
      try {
        // Cek apakah sudah ada di server (by user_id, activity_id, date)
        final existing = await _supabase
            .from(SupabaseConstants.dailyLogsTable)
            .select('id')
            .eq('user_id', log.odIduserId)
            .eq('activity_id', log.activityId)
            .eq('date', log.date.toIso8601String().split('T')[0])
            .maybeSingle();

        if (existing != null) {
          // Update existing record
          await _supabase.from(SupabaseConstants.dailyLogsTable).update({
            'value': log.value,
            'status': log.status,
            'updated_at': log.updatedAt?.toIso8601String(),
          }).eq('id', existing['id']);
        } else {
          // Insert new record
          await _supabase
              .from(SupabaseConstants.dailyLogsTable)
              .insert(log.toJson());
        }

        // Mark as synced locally
        await LocalStorageService.markAsSynced(log.id);
        syncedCount++;
      } catch (e) {
        errors.add('Gagal sync log ${log.id}: $e');
        debugPrint('Sync error: $e');
      }
    }

    return SyncResult(
      success: errors.isEmpty,
      message: errors.isEmpty
          ? 'Berhasil sync $syncedCount data'
          : 'Sync selesai dengan ${errors.length} error',
      syncedCount: syncedCount,
      errors: errors,
    );
  }

  /// Fetch data dari Supabase ke local - REPLACE local data (bukan append)
  /// Ini dipanggil saat login/refresh untuk memastikan data fresh dari server
  static Future<FetchResult> fetchFromSupabase(String userId) async {
    if (!await hasInternetConnection()) {
      return FetchResult(
        success: false,
        message: 'Tidak ada koneksi internet',
        fetchedCount: 0,
      );
    }

    // Pastikan user boxes sudah open
    if (!LocalStorageService.isUserBoxesOpen) {
      return FetchResult(
        success: false,
        message: 'Local storage belum siap',
        fetchedCount: 0,
      );
    }

    try {
      // PENTING: Clear local data dulu sebelum fetch
      // Ini memastikan tidak ada data lama yang tersisa
      await LocalStorageService.clearCurrentUserData();
      debugPrint(
          'SyncService: Cleared local data, fetching fresh from Supabase');

      // Fetch daily logs dari 90 hari terakhir (lebih lama untuk history)
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));

      final response = await _supabase
          .from(SupabaseConstants.dailyLogsTable)
          .select()
          .eq('user_id', userId)
          .gte('date', ninetyDaysAgo.toIso8601String().split('T')[0])
          .order('date', ascending: false);

      // Save to local storage
      int count = 0;
      for (final json in response as List) {
        final log = DailyLogModel.fromJson(json);
        await LocalStorageService.saveDailyLog(log.copyWith(isSynced: true));
        count++;
      }

      debugPrint('SyncService: Fetched $count logs from Supabase');

      return FetchResult(
        success: true,
        message: 'Berhasil fetch $count data dari server',
        fetchedCount: count,
      );
    } catch (e) {
      debugPrint('Error fetching from Supabase: $e');
      return FetchResult(
        success: false,
        message: 'Gagal fetch data: $e',
        fetchedCount: 0,
      );
    }
  }

  /// Listen to connectivity changes and auto-sync
  static void startAutoSync() {
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        // Connection restored, sync pending data
        await syncToSupabase();
      }
    });
  }
}

/// Result dari operasi sync
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    this.errors = const [],
  });
}

/// Result dari operasi fetch
class FetchResult {
  final bool success;
  final String message;
  final int fetchedCount;

  FetchResult({
    required this.success,
    required this.message,
    required this.fetchedCount,
  });
}
