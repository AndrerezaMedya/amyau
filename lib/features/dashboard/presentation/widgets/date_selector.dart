import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/daily_logs_provider.dart';

/// Widget untuk memilih tanggal
class DateSelector extends ConsumerWidget {
  const DateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final today = DateTime.now();

    // Generate 7 days (3 before, today, 3 after)
    final dates = List.generate(7, (index) {
      return today.subtract(Duration(days: 3 - index));
    });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month/Year header with navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final newDate =
                        selectedDate.subtract(const Duration(days: 7));
                    ref.read(dailyLogsProvider.notifier).changeDate(newDate);
                  },
                ),
                GestureDetector(
                  onTap: () => _showDatePicker(context, ref, selectedDate),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('MMMM yyyy', 'id_ID').format(selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: selectedDate.isBefore(today)
                      ? () {
                          final newDate =
                              selectedDate.add(const Duration(days: 7));
                          if (newDate.isBefore(today) ||
                              newDate.day == today.day) {
                            ref
                                .read(dailyLogsProvider.notifier)
                                .changeDate(newDate);
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Day selector
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = _isSameDay(date, selectedDate);
                final isToday = _isSameDay(date, today);
                final isFuture = date.isAfter(today);

                return GestureDetector(
                  onTap: isFuture
                      ? null
                      : () {
                          ref.read(dailyLogsProvider.notifier).changeDate(date);
                        },
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : isFuture
                              ? Colors.grey.shade100
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(color: AppTheme.primaryColor, width: 2)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E', 'id_ID').format(date).substring(0, 3),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white70
                                : isFuture
                                    ? Colors.grey.shade400
                                    : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : isFuture
                                    ? Colors.grey.shade400
                                    : AppTheme.textPrimary,
                          ),
                        ),
                        if (isToday)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _showDatePicker(
    BuildContext context,
    WidgetRef ref,
    DateTime currentDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(dailyLogsProvider.notifier).changeDate(picked);
    }
  }
}
