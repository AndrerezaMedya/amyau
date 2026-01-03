import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/progress_provider.dart';

/// Halaman untuk melihat progres mingguan/bulanan
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progres Amalan'),
        actions: [
          // Toggle Weekly/Monthly
          TextButton.icon(
            onPressed: () => ref.read(progressProvider.notifier).togglePeriod(),
            icon: Icon(
              progressState.isWeekly
                  ? Icons.calendar_view_week
                  : Icons.calendar_month,
              color: Colors.white,
            ),
            label: Text(
              progressState.isWeekly ? 'Mingguan' : 'Bulanan',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Period header
          _buildPeriodHeader(context, ref, progressState),

          // Overall progress card
          _buildOverallCard(progressState),

          // Activity list
          Expanded(
            child: progressState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(progressProvider.notifier).loadProgress(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: progressState.items.length,
                      itemBuilder: (context, index) {
                        final item = progressState.items[index];
                        return _buildProgressItem(item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader(
    BuildContext context,
    WidgetRef ref,
    ProgressState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                ref.read(progressProvider.notifier).previousPeriod(),
          ),
          Column(
            children: [
              Text(
                state.isWeekly ? 'Minggu Ini' : 'Bulan Ini',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${DateFormat('d MMM', 'id_ID').format(state.startDate)} - ${DateFormat('d MMM yyyy', 'id_ID').format(state.endDate)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.endDate.isBefore(DateTime.now())
                ? () => ref.read(progressProvider.notifier).nextPeriod()
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallCard(ProgressState state) {
    final percentage = state.overallPercentage;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text(
                  '${percentage.toInt()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isWeekly
                      ? 'Pencapaian Minggu Ini'
                      : 'Pencapaian Bulan Ini',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getMotivationalText(percentage),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Text(
            _getEmoji(percentage),
            style: const TextStyle(fontSize: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(ProgressItem item) {
    final percentage = item.percentage;
    final color = _getProgressColor(percentage);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity name
            Text(
              item.activityName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.achievedDays} dari ${item.totalDays} hari',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return AppTheme.successColor;
    if (percentage >= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getMotivationalText(double percentage) {
    if (percentage >= 80) return 'Luar Biasa! Pertahankan! 🌟';
    if (percentage >= 60) return 'Bagus! Tingkatkan terus! 💪';
    if (percentage >= 40) return 'Semangat! Masih bisa lebih! 📈';
    return 'Ayo mulai istiqomah! 🤲';
  }

  String _getEmoji(double percentage) {
    if (percentage >= 80) return '🏆';
    if (percentage >= 60) return '⭐';
    if (percentage >= 40) return '🌙';
    return '🌱';
  }
}
