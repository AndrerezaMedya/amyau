import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/gemini_constants.dart';
import '../../core/utils/timezone_helper.dart';
import '../../models/daily_log_model.dart';
import '../../models/prayer_time_model.dart';
import '../../core/constants/activity_constants.dart';
import '../../shared/utils/status_calculator.dart';

/// Service untuk AI Agent menggunakan Gemini
class GeminiService {
  static GenerativeModel? _model;
  static ChatSession? _chatSession;
  static DailyPrayerSchedule? _currentPrayerSchedule;

  /// Set current prayer schedule for context
  static void setPrayerSchedule(DailyPrayerSchedule? schedule) {
    _currentPrayerSchedule = schedule;
  }

  /// Initialize Gemini model
  static void initialize() {
    _model = GenerativeModel(
      model: GeminiConstants.modelId,
      apiKey: GeminiConstants.apiKey,
      systemInstruction: Content.text(GeminiConstants.systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
    );
  }

  /// Get or create chat session
  static ChatSession get _chat {
    _chatSession ??= _model!.startChat();
    return _chatSession!;
  }

  /// Reset chat session
  static void resetChat() {
    _chatSession = null;
  }

  /// Send message to AI and get response
  static Future<String> sendMessage(String message,
      {String? prayerContext}) async {
    try {
      if (_model == null) initialize();

      // Build context-enhanced message
      final contextBuffer = StringBuffer();

      // Add current time context (WIB)
      final now = TimezoneHelper.nowWIB();
      contextBuffer.writeln(
          '[Konteks Waktu: ${TimezoneHelper.formatWIB(now, pattern: 'EEEE, d MMMM yyyy HH:mm')}]');

      // Add prayer time context
      if (prayerContext != null && prayerContext.isNotEmpty) {
        contextBuffer.writeln('[Konteks Waktu Sholat: $prayerContext]');
      } else if (_currentPrayerSchedule != null) {
        contextBuffer.writeln(
            '[Konteks Waktu Sholat: ${_currentPrayerSchedule!.toAISummary(now)}]');
      }

      contextBuffer.writeln('');
      contextBuffer.writeln('Pertanyaan user: $message');

      final response =
          await _chat.sendMessage(Content.text(contextBuffer.toString()));
      return response.text ?? 'Maaf, tidak ada respons dari AI.';
    } catch (e) {
      return 'Maaf, terjadi kesalahan: $e';
    }
  }

  /// Generate daily review berdasarkan log harian
  static Future<String> generateDailyReview(
    List<DailyLogModel> logs,
    String sapaan, {
    String? prayerContext,
  }) async {
    try {
      if (_model == null) initialize();

      final summary = StatusCalculator.generateSummaryForAI(logs);
      final achieved = logs.where((l) => l.status == 'V').length;
      final total = ActivityConstants.activities.length;
      final percentage = total > 0 ? (achieved / total * 100).toInt() : 0;

      // Add time context
      final now = TimezoneHelper.nowWIB();
      final timeContext =
          TimezoneHelper.formatWIB(now, pattern: 'EEEE, d MMMM yyyy HH:mm');

      // Build prayer context string
      String prayerInfo = '';
      if (prayerContext != null && prayerContext.isNotEmpty) {
        prayerInfo = '\n\nKonteks waktu sholat hari ini:\n$prayerContext';
      } else if (_currentPrayerSchedule != null) {
        prayerInfo =
            '\n\nKonteks waktu sholat hari ini:\n${_currentPrayerSchedule!.toAISummary(now)}';
      }

      final prompt = '''
$sapaan, berikut ringkasan pencapaian ibadah hari ini ($timeContext WIB):

$summary

Total pencapaian: $achieved dari $total amalan ($percentage%)
$prayerInfo

Tolong berikan ringkasan evaluasi harian dengan:
1. Apresiasi untuk amalan yang tercapai
2. Motivasi untuk amalan yang belum tercapai
3. Tips singkat untuk besok
4. Doa penutup

Gunakan bahasa yang ramah dan penuh kasih sayang seperti mentor.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Tidak dapat membuat ringkasan.';
    } catch (e) {
      return _generateOfflineReview(logs, sapaan);
    }
  }

  /// Generate reminder untuk aktivitas tertentu
  static Future<String> generateReminder(String activityName) async {
    try {
      if (_model == null) initialize();

      final prompt = '''
${GeminiConstants.reminderPrompt}

Aktivitas: $activityName

Buat reminder yang singkat, ramah, dan memotivasi.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Jangan lupa $activityName ya! 🌙';
    } catch (e) {
      return 'Jangan lupa $activityName ya! Semangat! 💪';
    }
  }

  /// Analyze habit patterns dari data mingguan
  static Future<String> analyzeHabitPatterns(
    List<DailyLogModel> weeklyLogs,
    String sapaan,
  ) async {
    try {
      if (_model == null) initialize();

      // Group logs by activity
      final Map<int, List<DailyLogModel>> groupedLogs = {};
      for (final log in weeklyLogs) {
        groupedLogs.putIfAbsent(log.activityId, () => []).add(log);
      }

      final buffer = StringBuffer();
      buffer.writeln('Data amalan 7 hari terakhir:');
      buffer.writeln('');

      for (final activity in ActivityConstants.activities) {
        final logs = groupedLogs[activity.id] ?? [];
        final achieved = logs.where((l) => l.status == 'V').length;
        buffer.writeln('${activity.name}: $achieved/7 hari tercapai');
      }

      final prompt = '''
$sapaan, berikut analisis pola ibadah mingguan:

${buffer.toString()}

Tolong analisis:
1. Amalan yang paling konsisten
2. Amalan yang perlu ditingkatkan
3. Pola yang terlihat (misalnya: lebih rajin di hari tertentu)
4. Saran konkret untuk minggu depan

Gunakan bahasa yang supportive dan tidak menghakimi.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Tidak dapat menganalisis pola.';
    } catch (e) {
      return 'Maaf, tidak dapat menganalisis pola saat ini. Coba lagi nanti.';
    }
  }

  /// Fallback review jika offline
  static String _generateOfflineReview(
    List<DailyLogModel> logs,
    String sapaan,
  ) {
    final achieved = logs.where((l) => l.status == 'V').length;
    final total = ActivityConstants.activities.length;
    final percentage = total > 0 ? (achieved / total * 100).toInt() : 0;

    String motivation;
    String emoji;

    if (percentage >= 80) {
      motivation = 'MasyaAllah, luar biasa! Semoga istiqomah ya.';
      emoji = '🌟';
    } else if (percentage >= 60) {
      motivation = 'Alhamdulillah, pencapaian yang bagus. Terus tingkatkan!';
      emoji = '💪';
    } else if (percentage >= 40) {
      motivation = 'Semangat! Setiap usaha pasti dihitung oleh Allah.';
      emoji = '📈';
    } else {
      motivation =
          'Jangan menyerah! Besok adalah kesempatan baru untuk lebih baik.';
      emoji = '🤲';
    }

    return '''
Assalamu'alaikum $sapaan $emoji

📊 **Ringkasan Hari Ini**
Pencapaian: $achieved dari $total amalan ($percentage%)

$motivation

🤲 Semoga Allah mudahkan dan berkahi setiap amal ibadah kita. Aamiin.

_"Sebaik-baik amalan adalah yang paling konsisten meskipun sedikit."_
(HR. Bukhari & Muslim)
''';
  }
}
