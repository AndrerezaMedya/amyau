import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/activity_model.dart';

/// Card untuk satu aktivitas dengan checkbox sederhana
/// Evaluasi V/X dilakukan berdasarkan akumulasi mingguan/bulanan
class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final int currentValue; // 0 = belum, 1 = sudah
  final String? status;
  final Function(int) onValueChanged;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.currentValue,
    required this.status,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = currentValue > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _toggleActivity(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => _toggleActivity(),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone ? AppTheme.successColor : Colors.transparent,
                    border: Border.all(
                      color:
                          isDone ? AppTheme.successColor : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isDone
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Activity info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity name
                    Text(
                      '${activity.id}. ${activity.name}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDone
                            ? Colors.grey.shade500
                            : AppTheme.textPrimary,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Target
                    Text(
                      activity.target,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    // Keterangan jika ada
                    if (activity.keterangan.isNotEmpty) ...[
                      Text(
                        activity.keterangan,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Evaluation type badge
              _buildEvaluationBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationBadge() {
    String badgeText;
    Color bgColor;
    Color textColor;

    switch (activity.evaluationPeriod) {
      case EvaluationPeriod.daily:
        badgeText = '≥50%/bulan';
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade600;
        break;
      case EvaluationPeriod.weekly:
        badgeText = '≥${activity.threshold}x/minggu';
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade600;
        break;
      case EvaluationPeriod.monthly:
        badgeText = '≥${activity.threshold}x/bulan';
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade600;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  void _toggleActivity() {
    // Toggle between 0 (belum) and 1 (sudah)
    onValueChanged(currentValue > 0 ? 0 : 1);
  }
}
