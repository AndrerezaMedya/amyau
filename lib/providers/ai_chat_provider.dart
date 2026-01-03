import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/gemini_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/utils/timezone_helper.dart';
import 'auth_provider.dart';
import 'prayer_time_provider.dart';

/// Model untuk chat message
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// State untuk AI Chat
class AIChatState {
  final List<ChatMessage> messages;
  final bool isGeneratingReview;
  final String? dailyReview;

  const AIChatState({
    this.messages = const [],
    this.isGeneratingReview = false,
    this.dailyReview,
  });

  AIChatState copyWith({
    List<ChatMessage>? messages,
    bool? isGeneratingReview,
    String? dailyReview,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isGeneratingReview: isGeneratingReview ?? this.isGeneratingReview,
      dailyReview: dailyReview,
    );
  }
}

/// Notifier untuk AI Chat
class AIChatNotifier extends StateNotifier<AIChatState> {
  final String sapaan;
  final Ref _ref;

  AIChatNotifier(this.sapaan, this._ref) : super(const AIChatState()) {
    _initializeChat();
  }

  void _initializeChat() {
    GeminiService.initialize();

    // Set prayer schedule if available
    final prayerState = _ref.read(prayerTimeProvider);
    if (prayerState.schedule != null) {
      GeminiService.setPrayerSchedule(prayerState.schedule);
    }

    // Get greeting based on time
    final greeting = TimezoneHelper.getIslamicGreeting();

    // Add welcome message
    final welcomeMessage = ChatMessage(
      id: 'welcome',
      content: '''
$greeting $sapaan! 👋

Assalamu'alaikum. Saya Syeikh Syarafi, asisten mutabaah yaumi kamu.

Saya siap membantu: • Menganalisis pencapaian ibadah harian. • Memberikan motivasi dan tips istiqomah. • Membuat ringkasan ibadah dan pengingat waktu sholat.

Ada yang ingin kamu laporkan atau tanyakan hari ini?
''',
      isUser: false,
      timestamp: TimezoneHelper.nowWIB(),
    );

    state = state.copyWith(messages: [welcomeMessage]);
  }

  /// Send message to AI
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Get current prayer context
    final prayerContext = _ref.read(prayerTimeAIContextProvider);

    // Update prayer schedule in GeminiService
    final prayerState = _ref.read(prayerTimeProvider);
    if (prayerState.schedule != null) {
      GeminiService.setPrayerSchedule(prayerState.schedule);
    }

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isUser: true,
      timestamp: TimezoneHelper.nowWIB(),
    );

    final loadingMessage = ChatMessage(
      id: 'loading',
      content: 'Sedang mengetik...',
      isUser: false,
      timestamp: TimezoneHelper.nowWIB(),
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, loadingMessage],
    );

    try {
      final response = await GeminiService.sendMessage(
        message,
        prayerContext: prayerContext,
      );

      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: TimezoneHelper.nowWIB(),
      );

      // Remove loading message and add AI response
      final messages = state.messages.where((m) => m.id != 'loading').toList()
        ..add(aiMessage);

      state = state.copyWith(messages: messages);
    } catch (e) {
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Maaf, terjadi kesalahan. Silakan coba lagi.',
        isUser: false,
        timestamp: TimezoneHelper.nowWIB(),
      );

      final messages = state.messages.where((m) => m.id != 'loading').toList()
        ..add(errorMessage);

      state = state.copyWith(messages: messages);
    }
  }

  /// Generate daily review
  Future<void> generateDailyReview() async {
    state = state.copyWith(isGeneratingReview: true);

    try {
      // Get prayer context
      final prayerContext = _ref.read(prayerTimeAIContextProvider);

      final logs =
          LocalStorageService.getDailyLogsByDate(TimezoneHelper.todayWIB());
      final review = await GeminiService.generateDailyReview(
        logs,
        sapaan,
        prayerContext: prayerContext,
      );

      state = state.copyWith(
        isGeneratingReview: false,
        dailyReview: review,
      );

      // Also add as chat message
      final reviewMessage = ChatMessage(
        id: 'daily-review-${DateTime.now().millisecondsSinceEpoch}',
        content: '📋 **Ringkasan Harian**\n\n$review',
        isUser: false,
        timestamp: TimezoneHelper.nowWIB(),
      );

      state = state.copyWith(
        messages: [...state.messages, reviewMessage],
      );
    } catch (e) {
      state = state.copyWith(isGeneratingReview: false);
    }
  }

  /// Analyze weekly patterns
  Future<void> analyzeWeeklyPatterns() async {
    final loadingMessage = ChatMessage(
      id: 'loading',
      content: 'Menganalisis pola mingguan...',
      isUser: false,
      timestamp: TimezoneHelper.nowWIB(),
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...state.messages, loadingMessage],
    );

    try {
      final now = TimezoneHelper.nowWIB();
      final weekAgo = now.subtract(const Duration(days: 7));
      final logs = LocalStorageService.getDailyLogsByDateRange(weekAgo, now);

      final analysis = await GeminiService.analyzeHabitPatterns(logs, sapaan);

      final analysisMessage = ChatMessage(
        id: 'analysis-${DateTime.now().millisecondsSinceEpoch}',
        content: '📈 **Analisis Pola Mingguan**\n\n$analysis',
        isUser: false,
        timestamp: TimezoneHelper.nowWIB(),
      );

      final messages = state.messages.where((m) => m.id != 'loading').toList()
        ..add(analysisMessage);

      state = state.copyWith(messages: messages);
    } catch (e) {
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Maaf, tidak dapat menganalisis pola saat ini.',
        isUser: false,
        timestamp: TimezoneHelper.nowWIB(),
      );

      final messages = state.messages.where((m) => m.id != 'loading').toList()
        ..add(errorMessage);

      state = state.copyWith(messages: messages);
    }
  }

  /// Clear chat history
  void clearChat() {
    GeminiService.resetChat();
    _initializeChat();
  }
}

/// Provider untuk AI Chat
final aiChatProvider =
    StateNotifierProvider<AIChatNotifier, AIChatState>((ref) {
  final user = ref.watch(currentUserProvider);
  return AIChatNotifier(user?.sapaan ?? 'Akhi', ref);
});
