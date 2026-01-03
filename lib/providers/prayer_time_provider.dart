import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prayer_time_model.dart';
import '../core/services/prayer_time_service.dart';
import '../core/services/location_service.dart';
import '../core/utils/timezone_helper.dart';

/// State untuk Prayer Time
class PrayerTimeState {
  final DailyPrayerSchedule? schedule;
  final bool isLoading;
  final String? errorMessage;
  final DateTime lastUpdated;
  final PrayerTime? nextPrayer;
  final Duration? timeUntilNextPrayer;
  final UserLocation? userLocation;
  final LocationPermissionStatus locationPermission;

  const PrayerTimeState({
    this.schedule,
    this.isLoading = false,
    this.errorMessage,
    required this.lastUpdated,
    this.nextPrayer,
    this.timeUntilNextPrayer,
    this.userLocation,
    this.locationPermission = LocationPermissionStatus.unknown,
  });

  PrayerTimeState copyWith({
    DailyPrayerSchedule? schedule,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
    PrayerTime? nextPrayer,
    Duration? timeUntilNextPrayer,
    UserLocation? userLocation,
    LocationPermissionStatus? locationPermission,
  }) {
    return PrayerTimeState(
      schedule: schedule ?? this.schedule,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      timeUntilNextPrayer: timeUntilNextPrayer ?? this.timeUntilNextPrayer,
      userLocation: userLocation ?? this.userLocation,
      locationPermission: locationPermission ?? this.locationPermission,
    );
  }

  /// Check if location is using default
  bool get isUsingDefaultLocation {
    return userLocation == null ||
        (userLocation!.latitude == -6.2088 &&
            userLocation!.longitude == 106.8456);
  }

  /// Get location display name
  String get locationDisplayName {
    return userLocation?.displayName ?? 'Jakarta (Default)';
  }

  /// Check if it's near prayer time
  bool get isNearPrayerTime {
    if (schedule == null) return false;
    return schedule!
        .isNearPrayerTime(TimezoneHelper.nowWIB(), minutesBefore: 15);
  }

  /// Get formatted time until next prayer
  String get formattedTimeUntilNextPrayer {
    if (timeUntilNextPrayer == null) return '-';

    final hours = timeUntilNextPrayer!.inHours;
    final minutes = timeUntilNextPrayer!.inMinutes % 60;

    if (hours > 0) {
      return '$hours jam $minutes menit';
    }
    return '$minutes menit';
  }

  /// Get AI context string
  String getAIContext() {
    if (schedule == null) return 'Data waktu sholat tidak tersedia.';

    final now = TimezoneHelper.nowWIB();
    return schedule!.toAISummary(now);
  }
}

/// Notifier untuk Prayer Time
class PrayerTimeNotifier extends StateNotifier<PrayerTimeState> {
  Timer? _updateTimer;
  Timer? _refreshTimer;

  PrayerTimeNotifier() : super(PrayerTimeState(lastUpdated: DateTime.now())) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Check permission and get location
    await _initializeLocation();
    _startUpdateTimer();
    _startDailyRefreshTimer();
  }

  /// Initialize location and fetch prayer times
  Future<void> _initializeLocation() async {
    state = state.copyWith(isLoading: true);

    // Check current permission status
    final permissionStatus = await LocationService.checkPermission();
    state = state.copyWith(locationPermission: permissionStatus);

    // Get location with fallback
    final location = await LocationService.getLocationWithFallback();
    state = state.copyWith(userLocation: location);

    // Fetch prayer times with location
    await _fetchPrayerTimesWithLocation(location);
  }

  /// Request location permission from user
  Future<bool> requestLocationPermission() async {
    state = state.copyWith(isLoading: true);

    final permissionStatus = await LocationService.requestPermission();
    state = state.copyWith(locationPermission: permissionStatus);

    if (permissionStatus == LocationPermissionStatus.granted) {
      // Get fresh location
      final location = await LocationService.getCurrentLocation();
      if (location != null) {
        state = state.copyWith(userLocation: location);
        await _fetchPrayerTimesWithLocation(location);
        return true;
      }
    }

    state = state.copyWith(isLoading: false);
    return false;
  }

  /// Refresh location and prayer times
  Future<void> refreshLocation() async {
    state = state.copyWith(isLoading: true);

    final location = await LocationService.getCurrentLocation();
    if (location != null) {
      state = state.copyWith(userLocation: location);
      await _fetchPrayerTimesWithLocation(location);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Fetch prayer times with specific location
  Future<void> _fetchPrayerTimesWithLocation(UserLocation location) async {
    try {
      var schedule = await PrayerTimeService.fetchTodayPrayerTimes(
        latitude: location.latitude,
        longitude: location.longitude,
        city: location.cityName,
      );

      // Use fallback if API fails
      schedule ??= PrayerTimeService.getFallbackPrayerTimes();

      final now = TimezoneHelper.nowWIB();
      final nextPrayer = schedule.getNextPrayer(now);
      final timeUntil = schedule.getTimeUntilNextPrayer(now);

      state = state.copyWith(
        schedule: schedule.withUpdatedPassedStatus(now),
        isLoading: false,
        lastUpdated: DateTime.now(),
        nextPrayer: nextPrayer,
        timeUntilNextPrayer: timeUntil,
      );
    } catch (e) {
      // Use fallback on error
      final fallback = PrayerTimeService.getFallbackPrayerTimes();
      final now = TimezoneHelper.nowWIB();

      state = state.copyWith(
        schedule: fallback,
        isLoading: false,
        errorMessage: 'Gagal memuat waktu sholat',
        lastUpdated: DateTime.now(),
        nextPrayer: fallback.getNextPrayer(now),
        timeUntilNextPrayer: fallback.getTimeUntilNextPrayer(now),
      );
    }
  }

  /// Fetch prayer times from API (legacy method for compatibility)
  Future<void> fetchPrayerTimes({
    double? latitude,
    double? longitude,
    String? city,
  }) async {
    final location = UserLocation(
      latitude: latitude ?? state.userLocation?.latitude ?? -6.2088,
      longitude: longitude ?? state.userLocation?.longitude ?? 106.8456,
      cityName: city ?? state.userLocation?.cityName,
      lastUpdated: DateTime.now(),
    );
    await _fetchPrayerTimesWithLocation(location);
  }

  /// Start timer to update next prayer countdown every minute
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateNextPrayer();
    });
  }

  /// Start timer to refresh prayer times at midnight
  void _startDailyRefreshTimer() {
    _refreshTimer?.cancel();

    // Calculate time until next midnight
    final now = TimezoneHelper.nowWIB();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);

    _refreshTimer = Timer(durationUntilMidnight, () {
      fetchPrayerTimes();
      _startDailyRefreshTimer(); // Reschedule for next day
    });
  }

  /// Update next prayer and countdown
  void _updateNextPrayer() {
    if (state.schedule == null) return;

    final now = TimezoneHelper.nowWIB();
    final schedule = state.schedule!.withUpdatedPassedStatus(now);
    final nextPrayer = schedule.getNextPrayer(now);
    final timeUntil = schedule.getTimeUntilNextPrayer(now);

    state = state.copyWith(
      schedule: schedule,
      nextPrayer: nextPrayer,
      timeUntilNextPrayer: timeUntil,
    );
  }

  /// Force refresh prayer times
  Future<void> refresh() async {
    await fetchPrayerTimes();
  }

  /// Update location
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    String? city,
  }) async {
    await fetchPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      city: city,
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Provider untuk Prayer Time
final prayerTimeProvider =
    StateNotifierProvider<PrayerTimeNotifier, PrayerTimeState>((ref) {
  return PrayerTimeNotifier();
});

/// Provider untuk next prayer info
final nextPrayerProvider = Provider<PrayerTime?>((ref) {
  return ref.watch(prayerTimeProvider).nextPrayer;
});

/// Provider untuk countdown text
final prayerCountdownProvider = Provider<String>((ref) {
  return ref.watch(prayerTimeProvider).formattedTimeUntilNextPrayer;
});

/// Provider untuk AI context
final prayerTimeAIContextProvider = Provider<String>((ref) {
  return ref.watch(prayerTimeProvider).getAIContext();
});

/// Provider untuk check if near prayer time
final isNearPrayerTimeProvider = Provider<bool>((ref) {
  return ref.watch(prayerTimeProvider).isNearPrayerTime;
});

/// Provider untuk location display name
final locationDisplayNameProvider = Provider<String>((ref) {
  return ref.watch(prayerTimeProvider).locationDisplayName;
});

/// Provider untuk check if using default location
final isUsingDefaultLocationProvider = Provider<bool>((ref) {
  return ref.watch(prayerTimeProvider).isUsingDefaultLocation;
});

/// Provider untuk location permission status
final locationPermissionProvider = Provider<LocationPermissionStatus>((ref) {
  return ref.watch(prayerTimeProvider).locationPermission;
});
