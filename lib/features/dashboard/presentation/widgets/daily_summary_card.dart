import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/daily_logs_provider.dart';

/// Card ringkasan pencapaian harian
class DailySummaryCard extends ConsumerWidget {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(dailyLogsProvider);
    final totalActivities = 12; // Total 12 aktivitas (sesuai tabel)
    final achieved = logsState.totalAchieved;
    final percentage = logsState.achievementPercentage;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
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
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
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

              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pencapaian Hari Ini',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$achieved dari $totalActivities amalan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBadge(percentage),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar per kategori
          Row(
            children: [
              _buildMiniStat(
                icon: Icons.check_circle,
                label: 'Tercapai',
                value: '$achieved',
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              _buildMiniStat(
                icon: Icons.radio_button_unchecked,
                label: 'Belum',
                value: '${totalActivities - achieved}',
                color: Colors.white70,
              ),
              const Spacer(),
              _buildEmoji(percentage),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(double percentage) {
    String text;
    Color bgColor;

    if (percentage >= 80) {
      text = 'Luar Biasa! 🌟';
      bgColor = Colors.green.shade600;
    } else if (percentage >= 60) {
      text = 'Bagus! 💪';
      bgColor = Colors.blue.shade600;
    } else if (percentage >= 40) {
      text = 'Terus Semangat! 📈';
      bgColor = Colors.orange.shade600;
    } else {
      text = 'Ayo Tingkatkan! 🤲';
      bgColor = Colors.red.shade400;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmoji(double percentage) {
    String emoji;
    if (percentage >= 80) {
      emoji = '🏆';
    } else if (percentage >= 60) {
      emoji = '⭐';
    } else if (percentage >= 40) {
      emoji = '🌙';
    } else {
      emoji = '🌱';
    }

    return Text(
      emoji,
      style: const TextStyle(fontSize: 32),
    );
  }
}
