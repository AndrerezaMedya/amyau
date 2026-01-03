import 'package:intl/intl.dart';

/// Helper class untuk menangani timezone WIB (GMT+7)
/// Semua operasi tanggal di app ini menggunakan Waktu Indonesia Barat
class TimezoneHelper {
  TimezoneHelper._();

  /// Offset WIB dari UTC (7 jam)
  static const int wibOffsetHours = 7;
  static const Duration wibOffset = Duration(hours: wibOffsetHours);

  /// Get current DateTime in WIB timezone
  /// Returns a non-UTC DateTime representing WIB time
  static DateTime nowWIB() {
    final utc = DateTime.now().toUtc();
    final wib = utc.add(wibOffset);
    // Return as non-UTC DateTime to prevent double conversion
    return DateTime(
      wib.year,
      wib.month,
      wib.day,
      wib.hour,
      wib.minute,
      wib.second,
      wib.millisecond,
    );
  }

  /// Get today's date in WIB (tanpa waktu, hanya tanggal)
  static DateTime todayWIB() {
    final now = nowWIB();
    return DateTime(now.year, now.month, now.day);
  }

  /// Convert UTC DateTime to WIB
  /// Returns a non-UTC DateTime representing WIB time
  static DateTime toWIB(DateTime dateTime) {
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    final wib = utc.add(wibOffset);
    // Return as non-UTC DateTime
    return DateTime(
      wib.year,
      wib.month,
      wib.day,
      wib.hour,
      wib.minute,
      wib.second,
      wib.millisecond,
    );
  }

  /// Convert WIB DateTime to UTC
  static DateTime toUTC(DateTime wib) {
    return wib.subtract(wibOffset).toUtc();
  }

  /// Check if a date is today in WIB
  static bool isToday(DateTime date) {
    final today = todayWIB();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// Check if a date is in the current week (starting Monday) in WIB
  static bool isThisWeek(DateTime date) {
    final now = nowWIB();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOnly = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);

    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  /// Check if a date is in the current month in WIB
  static bool isThisMonth(DateTime date) {
    final now = nowWIB();
    return date.year == now.year && date.month == now.month;
  }

  /// Get start of day in WIB
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day in WIB (23:59:59.999)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of current week (Monday) in WIB
  static DateTime startOfWeek() {
    final now = nowWIB();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  /// Get start of current month in WIB
  static DateTime startOfMonth() {
    final now = nowWIB();
    return DateTime(now.year, now.month, 1);
  }

  /// Get end of current month in WIB
  static DateTime endOfMonth() {
    final now = nowWIB();
    return DateTime(now.year, now.month + 1, 0);
  }

  /// Get number of days in current month
  static int daysInCurrentMonth() {
    final now = nowWIB();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  /// Get number of weeks in current month
  static int weeksInCurrentMonth() {
    final daysInMonth = daysInCurrentMonth();
    return ((daysInMonth + startOfMonth().weekday - 1) / 7).ceil();
  }

  /// Format DateTime to WIB string with label
  static String formatWIB(DateTime date,
      {String pattern = 'dd MMM yyyy HH:mm'}) {
    final wib = date.isUtc ? toWIB(date) : date;
    return '${DateFormat(pattern, 'id_ID').format(wib)} WIB';
  }

  /// Format time only (HH:mm)
  static String formatTime(DateTime date) {
    final wib = date.isUtc ? toWIB(date) : date;
    return DateFormat('HH:mm', 'id_ID').format(wib);
  }

  /// Format date only (dd MMMM yyyy)
  static String formatDate(DateTime date) {
    final wib = date.isUtc ? toWIB(date) : date;
    return DateFormat('dd MMMM yyyy', 'id_ID').format(wib);
  }

  /// Format date for storage (yyyy-MM-dd)
  static String formatForStorage(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Parse date from storage format
  static DateTime parseFromStorage(String dateStr) {
    return DateFormat('yyyy-MM-dd').parse(dateStr);
  }

  /// Get greeting based on current WIB time
  static String getGreeting() {
    final hour = nowWIB().hour;
    if (hour < 4) return 'Selamat malam';
    if (hour < 10) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  /// Get Islamic greeting based on current WIB time
  static String getIslamicGreeting() {
    final hour = nowWIB().hour;
    if (hour < 4) return 'Assalamu\'alaikum, semoga malam ini penuh berkah';
    if (hour < 10) return 'Assalamu\'alaikum, semoga pagi ini penuh semangat';
    if (hour < 15) return 'Assalamu\'alaikum, semoga siang ini produktif';
    if (hour < 18) return 'Assalamu\'alaikum, semoga sore ini menyenangkan';
    return 'Assalamu\'alaikum, semoga malam ini tenang';
  }
}
