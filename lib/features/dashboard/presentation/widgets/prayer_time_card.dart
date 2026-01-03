import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../../../core/services/location_service.dart';
import '../../../../providers/prayer_time_provider.dart';

/// Widget untuk menampilkan jadwal sholat dan countdown
class PrayerTimeCard extends ConsumerWidget {
  const PrayerTimeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerState = ref.watch(prayerTimeProvider);
    final nextPrayer = ref.watch(nextPrayerProvider);
    final countdown = ref.watch(prayerCountdownProvider);
    final isNearPrayer = ref.watch(isNearPrayerTimeProvider);
    final locationName = ref.watch(locationDisplayNameProvider);
    final isDefaultLocation = ref.watch(isUsingDefaultLocationProvider);

    if (prayerState.isLoading) {
      return const _LoadingCard();
    }

    if (prayerState.schedule == null) {
      return const _ErrorCard();
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isNearPrayer
                ? [
                    AppTheme.warningColor,
                    AppTheme.warningColor.withValues(alpha: 0.8)
                  ]
                : [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.8)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan lokasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mosque_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Jadwal Sholat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Location indicator
                  GestureDetector(
                    onTap: () =>
                        _showLocationDialog(context, ref, isDefaultLocation),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDefaultLocation
                                ? Icons.location_off
                                : Icons.location_on,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            locationName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Next Prayer Countdown
              if (nextPrayer != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isNearPrayer
                                  ? '⏰ Waktu ${nextPrayer.name} hampir tiba!'
                                  : 'Sholat ${nextPrayer.name} berikutnya',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nextPrayer.formattedTime,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            countdown,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'tersisa',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // All Prayer Times Row
              _PrayerTimesRow(schedule: prayerState.schedule!),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerTimesRow extends StatelessWidget {
  final dynamic schedule;

  const _PrayerTimesRow({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final prayers = [
      {'name': 'Subuh', 'time': schedule.subuh, 'icon': Icons.nightlight_round},
      {
        'name': 'Dzuhur',
        'time': schedule.dzuhur,
        'icon': Icons.wb_sunny_rounded
      },
      {
        'name': 'Ashar',
        'time': schedule.ashar,
        'icon': Icons.wb_twilight_rounded
      },
      {
        'name': 'Maghrib',
        'time': schedule.maghrib,
        'icon': Icons.nights_stay_rounded
      },
      {'name': 'Isya', 'time': schedule.isya, 'icon': Icons.dark_mode_rounded},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: prayers.map((prayer) {
        final prayerTime = prayer['time'];
        final isPassed = prayerTime.isPassed;

        return Column(
          children: [
            Icon(
              prayer['icon'] as IconData,
              color:
                  isPassed ? Colors.white.withValues(alpha: 0.5) : Colors.white,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              prayer['name'] as String,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isPassed
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              prayerTime.formattedTime,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPassed
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white,
                decoration: isPassed ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Memuat jadwal sholat...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tidak dapat memuat jadwal sholat. Periksa koneksi internet.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show location permission dialog
void _showLocationDialog(
    BuildContext context, WidgetRef ref, bool isDefaultLocation) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            isDefaultLocation ? Icons.location_off : Icons.location_on,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          const Text('Lokasi'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDefaultLocation) ...[
            const Text(
              'Saat ini menggunakan lokasi default (Jakarta).',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aktifkan lokasi untuk waktu sholat yang lebih akurat sesuai lokasi Anda.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ] else ...[
            Text(
              'Lokasi: ${ref.read(locationDisplayNameProvider)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Terakhir diperbarui: ${TimezoneHelper.formatWIB(ref.read(prayerTimeProvider).lastUpdated, pattern: 'HH:mm')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        if (isDefaultLocation)
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Mengambil lokasi...'),
                    ],
                  ),
                  duration: Duration(seconds: 10),
                ),
              );

              final success = await ref
                  .read(prayerTimeProvider.notifier)
                  .requestLocationPermission();

              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Lokasi diperbarui: ${ref.read(locationDisplayNameProvider)}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Tidak dapat mengakses lokasi. Periksa izin aplikasi.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Aktifkan Lokasi'),
          )
        else
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Memperbarui lokasi...'),
                    ],
                  ),
                  duration: Duration(seconds: 10),
                ),
              );

              await ref.read(prayerTimeProvider.notifier).refreshLocation();

              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Lokasi diperbarui: ${ref.read(locationDisplayNameProvider)}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Perbarui'),
          ),
      ],
    ),
  );
}
