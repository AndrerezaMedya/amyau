import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/prayer_time_model.dart';
import '../utils/timezone_helper.dart';

/// Service untuk mengambil waktu sholat dari API
/// Menggunakan Aladhan API (https://aladhan.com/prayer-times-api)
class PrayerTimeService {
  PrayerTimeService._();

  /// Base URL untuk Aladhan API
  static const String _baseUrl = 'https://api.aladhan.com/v1';

  /// Default location (Jakarta)
  static const double defaultLatitude = -6.2088;
  static const double defaultLongitude = 106.8456;
  static const String defaultCity = 'Jakarta';

  /// Calculation method
  /// 20 = Kemenag Indonesia (Kementerian Agama Republik Indonesia)
  static const int calculationMethod = 20;

  /// Fetch prayer times for today
  static Future<DailyPrayerSchedule?> fetchTodayPrayerTimes({
    double? latitude,
    double? longitude,
    String? city,
  }) async {
    final lat = latitude ?? defaultLatitude;
    final lng = longitude ?? defaultLongitude;
    final cityName = city ?? defaultCity;

    try {
      final now = TimezoneHelper.nowWIB();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

      final url = Uri.parse(
        '$_baseUrl/timings/$dateStr?latitude=$lat&longitude=$lng&method=$calculationMethod&timezonestring=Asia/Jakarta',
      );

      debugPrint('Fetching prayer times from: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200 && data['data'] != null) {
          return _parsePrayerTimes(data['data'], cityName);
        }
      }

      debugPrint('Failed to fetch prayer times: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching prayer times: $e');
      return null;
    }
  }

  /// Fetch prayer times for a specific date
  static Future<DailyPrayerSchedule?> fetchPrayerTimesForDate({
    required DateTime date,
    double? latitude,
    double? longitude,
    String? city,
  }) async {
    final lat = latitude ?? defaultLatitude;
    final lng = longitude ?? defaultLongitude;
    final cityName = city ?? defaultCity;

    try {
      final dateStr =
          '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

      final url = Uri.parse(
        '$_baseUrl/timings/$dateStr?latitude=$lat&longitude=$lng&method=$calculationMethod&timezonestring=Asia/Jakarta',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200 && data['data'] != null) {
          return _parsePrayerTimes(data['data'], cityName);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching prayer times for date: $e');
      return null;
    }
  }

  /// Parse API response to DailyPrayerSchedule
  static DailyPrayerSchedule _parsePrayerTimes(
    Map<String, dynamic> data,
    String city,
  ) {
    final timings = data['timings'] as Map<String, dynamic>;
    final dateInfo = data['date'] as Map<String, dynamic>;
    final gregorian = dateInfo['gregorian'] as Map<String, dynamic>;

    // Parse date
    final day = int.parse(gregorian['day']);
    final month = int.parse(gregorian['month']['number'].toString());
    final year = int.parse(gregorian['year']);
    final date = DateTime(year, month, day);

    // Helper to parse time string "HH:mm (TZ)" to DateTime
    DateTime parseTime(String timeStr) {
      final timePart = timeStr.split(' ').first; // Remove timezone suffix
      final parts = timePart.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(year, month, day, hour, minute);
    }

    final now = TimezoneHelper.nowWIB();

    return DailyPrayerSchedule(
      date: date,
      location: city,
      method: 'Kemenag Indonesia',
      subuh: PrayerTime(
        name: 'Subuh',
        arabicName: 'الفجر',
        time: parseTime(timings['Fajr']),
        isPassed: parseTime(timings['Fajr']).isBefore(now),
      ),
      terbit: PrayerTime(
        name: 'Terbit',
        arabicName: 'الشروق',
        time: parseTime(timings['Sunrise']),
        isPassed: parseTime(timings['Sunrise']).isBefore(now),
      ),
      dzuhur: PrayerTime(
        name: 'Dzuhur',
        arabicName: 'الظهر',
        time: parseTime(timings['Dhuhr']),
        isPassed: parseTime(timings['Dhuhr']).isBefore(now),
      ),
      ashar: PrayerTime(
        name: 'Ashar',
        arabicName: 'العصر',
        time: parseTime(timings['Asr']),
        isPassed: parseTime(timings['Asr']).isBefore(now),
      ),
      maghrib: PrayerTime(
        name: 'Maghrib',
        arabicName: 'المغرب',
        time: parseTime(timings['Maghrib']),
        isPassed: parseTime(timings['Maghrib']).isBefore(now),
      ),
      isya: PrayerTime(
        name: 'Isya',
        arabicName: 'العشاء',
        time: parseTime(timings['Isha']),
        isPassed: parseTime(timings['Isha']).isBefore(now),
      ),
    );
  }

  /// Get fallback prayer times if API fails (approximate for Jakarta)
  static DailyPrayerSchedule getFallbackPrayerTimes() {
    final now = TimezoneHelper.nowWIB();
    final date = DateTime(now.year, now.month, now.day);

    return DailyPrayerSchedule(
      date: date,
      location: 'Jakarta (Perkiraan)',
      method: 'Fallback',
      subuh: PrayerTime(
        name: 'Subuh',
        arabicName: 'الفجر',
        time: DateTime(date.year, date.month, date.day, 4, 30),
        isPassed:
            DateTime(date.year, date.month, date.day, 4, 30).isBefore(now),
      ),
      terbit: PrayerTime(
        name: 'Terbit',
        arabicName: 'الشروق',
        time: DateTime(date.year, date.month, date.day, 5, 50),
        isPassed:
            DateTime(date.year, date.month, date.day, 5, 50).isBefore(now),
      ),
      dzuhur: PrayerTime(
        name: 'Dzuhur',
        arabicName: 'الظهر',
        time: DateTime(date.year, date.month, date.day, 12, 0),
        isPassed:
            DateTime(date.year, date.month, date.day, 12, 0).isBefore(now),
      ),
      ashar: PrayerTime(
        name: 'Ashar',
        arabicName: 'العصر',
        time: DateTime(date.year, date.month, date.day, 15, 15),
        isPassed:
            DateTime(date.year, date.month, date.day, 15, 15).isBefore(now),
      ),
      maghrib: PrayerTime(
        name: 'Maghrib',
        arabicName: 'المغرب',
        time: DateTime(date.year, date.month, date.day, 18, 0),
        isPassed:
            DateTime(date.year, date.month, date.day, 18, 0).isBefore(now),
      ),
      isya: PrayerTime(
        name: 'Isya',
        arabicName: 'العشاء',
        time: DateTime(date.year, date.month, date.day, 19, 15),
        isPassed:
            DateTime(date.year, date.month, date.day, 19, 15).isBefore(now),
      ),
    );
  }
}
