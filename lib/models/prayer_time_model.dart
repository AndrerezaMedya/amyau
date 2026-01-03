/// Model untuk waktu sholat harian
class PrayerTime {
  final String name;
  final String arabicName;
  final DateTime time;
  final bool isPassed;

  const PrayerTime({
    required this.name,
    required this.arabicName,
    required this.time,
    this.isPassed = false,
  });

  PrayerTime copyWith({
    String? name,
    String? arabicName,
    DateTime? time,
    bool? isPassed,
  }) {
    return PrayerTime(
      name: name ?? this.name,
      arabicName: arabicName ?? this.arabicName,
      time: time ?? this.time,
      isPassed: isPassed ?? this.isPassed,
    );
  }

  /// Format waktu ke HH:mm
  String get formattedTime {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => '$name: $formattedTime';
}

/// Model untuk jadwal sholat satu hari penuh
class DailyPrayerSchedule {
  final DateTime date;
  final String location;
  final String method;
  final PrayerTime subuh;
  final PrayerTime terbit;
  final PrayerTime dzuhur;
  final PrayerTime ashar;
  final PrayerTime maghrib;
  final PrayerTime isya;

  const DailyPrayerSchedule({
    required this.date,
    required this.location,
    required this.method,
    required this.subuh,
    required this.terbit,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  /// Get all prayer times as list (excluding terbit for main prayers)
  List<PrayerTime> get mainPrayers => [subuh, dzuhur, ashar, maghrib, isya];

  /// Get all times including terbit
  List<PrayerTime> get allTimes =>
      [subuh, terbit, dzuhur, ashar, maghrib, isya];

  /// Get next prayer based on current time
  PrayerTime? getNextPrayer(DateTime currentTime) {
    for (final prayer in allTimes) {
      if (prayer.time.isAfter(currentTime)) {
        return prayer;
      }
    }
    return null; // All prayers passed, next is Subuh tomorrow
  }

  /// Get current prayer (the one that just passed)
  PrayerTime? getCurrentPrayer(DateTime currentTime) {
    PrayerTime? current;
    for (final prayer in allTimes) {
      if (prayer.time.isBefore(currentTime) ||
          prayer.time.isAtSameMomentAs(currentTime)) {
        current = prayer;
      }
    }
    return current;
  }

  /// Get time until next prayer
  Duration? getTimeUntilNextPrayer(DateTime currentTime) {
    final next = getNextPrayer(currentTime);
    if (next == null) return null;
    return next.time.difference(currentTime);
  }

  /// Check if it's near a prayer time (within minutes)
  bool isNearPrayerTime(DateTime currentTime, {int minutesBefore = 15}) {
    final next = getNextPrayer(currentTime);
    if (next == null) return false;
    final diff = next.time.difference(currentTime);
    return diff.inMinutes <= minutesBefore && diff.inMinutes >= 0;
  }

  /// Update isPassed status for all prayers
  DailyPrayerSchedule withUpdatedPassedStatus(DateTime currentTime) {
    return DailyPrayerSchedule(
      date: date,
      location: location,
      method: method,
      subuh: subuh.copyWith(isPassed: subuh.time.isBefore(currentTime)),
      terbit: terbit.copyWith(isPassed: terbit.time.isBefore(currentTime)),
      dzuhur: dzuhur.copyWith(isPassed: dzuhur.time.isBefore(currentTime)),
      ashar: ashar.copyWith(isPassed: ashar.time.isBefore(currentTime)),
      maghrib: maghrib.copyWith(isPassed: maghrib.time.isBefore(currentTime)),
      isya: isya.copyWith(isPassed: isya.time.isBefore(currentTime)),
    );
  }

  /// Convert to summary string for AI context
  String toAISummary(DateTime currentTime) {
    final next = getNextPrayer(currentTime);
    final current = getCurrentPrayer(currentTime);
    final timeUntil = getTimeUntilNextPrayer(currentTime);

    final buffer = StringBuffer();
    buffer.writeln('Jadwal Sholat Hari Ini ($location):');
    for (final prayer in allTimes) {
      final status = prayer.isPassed ? '✓' : '○';
      buffer.writeln('$status ${prayer.name}: ${prayer.formattedTime}');
    }

    if (current != null) {
      buffer.writeln(
          '\nWaktu sholat terakhir: ${current.name} (${current.formattedTime})');
    }

    if (next != null && timeUntil != null) {
      final hours = timeUntil.inHours;
      final minutes = timeUntil.inMinutes % 60;
      buffer.writeln('Sholat berikutnya: ${next.name} (${next.formattedTime})');
      if (hours > 0) {
        buffer.writeln('Waktu tersisa: $hours jam $minutes menit');
      } else {
        buffer.writeln('Waktu tersisa: $minutes menit');
      }
    }

    return buffer.toString();
  }

  factory DailyPrayerSchedule.empty() {
    final now = DateTime.now();
    return DailyPrayerSchedule(
      date: now,
      location: 'Unknown',
      method: 'Unknown',
      subuh: PrayerTime(name: 'Subuh', arabicName: 'الفجر', time: now),
      terbit: PrayerTime(name: 'Terbit', arabicName: 'الشروق', time: now),
      dzuhur: PrayerTime(name: 'Dzuhur', arabicName: 'الظهر', time: now),
      ashar: PrayerTime(name: 'Ashar', arabicName: 'العصر', time: now),
      maghrib: PrayerTime(name: 'Maghrib', arabicName: 'المغرب', time: now),
      isya: PrayerTime(name: 'Isya', arabicName: 'العشاء', time: now),
    );
  }
}
