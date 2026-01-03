import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../providers/ai_chat_provider.dart';

/// Halaman chat dengan AI Assistant
class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    ref.read(aiChatProvider.notifier).sendMessage(message);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);

    // Auto scroll when new messages
    ref.listen(aiChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/images/icon.png'),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Syeikh Syarafi',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Asisten Ibadah',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'review':
                  ref.read(aiChatProvider.notifier).generateDailyReview();
                  break;
                case 'analyze':
                  ref.read(aiChatProvider.notifier).analyzeWeeklyPatterns();
                  break;
                case 'clear':
                  _showClearDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'review',
                child: Row(
                  children: [
                    Icon(Icons.summarize, size: 20),
                    SizedBox(width: 8),
                    Text('Ringkasan Harian'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'analyze',
                child: Row(
                  children: [
                    Icon(Icons.analytics, size: 20),
                    SizedBox(width: 8),
                    Text('Analisis Mingguan'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus Chat', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAction(
                    '📊 Ringkasan Hari Ini',
                    () =>
                        ref.read(aiChatProvider.notifier).generateDailyReview(),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    '📈 Analisis Minggu Ini',
                    () => ref
                        .read(aiChatProvider.notifier)
                        .analyzeWeeklyPatterns(),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    '💡 Tips Istiqomah',
                    () => ref.read(aiChatProvider.notifier).sendMessage(
                          'Berikan tips untuk istiqomah dalam beribadah',
                        ),
                  ),
                ],
              ),
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Tanya sesuatu...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Text('🤖', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          message.content,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    )
                  : isUser
                      // User message - plain text
                      ? Text(
                          message.content,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.4,
                          ),
                        )
                      // AI message - markdown rendered
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: AppTheme.textPrimary,
                              height: 1.5,
                              fontSize: 14,
                            ),
                            h1: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            h2: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            h3: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            strong: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            em: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                            listBullet: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 14,
                            ),
                            blockquote: TextStyle(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: AppTheme.primaryColor,
                                  width: 3,
                                ),
                              ),
                            ),
                            code: TextStyle(
                              backgroundColor: Colors.grey.shade100,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          selectable: true,
                        ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Chat'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua riwayat percakapan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearChat();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
