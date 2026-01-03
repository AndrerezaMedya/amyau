import '../services/env_service.dart';

/// Konfigurasi Supabase
/// Values dimuat dari .env file untuk security
class SupabaseConstants {
  SupabaseConstants._();

  /// URL Supabase project Anda
  /// Dari: .env SUPABASE_URL
  static String get supabaseUrl => EnvService.getRequired('SUPABASE_URL');

  /// Anon key Supabase project Anda
  /// Dari: .env SUPABASE_ANON_KEY
  static String get supabaseAnonKey =>
      EnvService.getRequired('SUPABASE_ANON_KEY');

  /// Nama tabel di Supabase
  static const String usersTable = 'users';
  static const String activitiesTable = 'activities';
  static const String dailyLogsTable = 'daily_logs';
  static const String weeklySummaryTable = 'weekly_summary';
}
