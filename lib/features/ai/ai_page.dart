import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'ai_service.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final previousMessages = _messages.where((msg) => msg['isError'] != true).toList();
    final history = previousMessages
        .skip(previousMessages.length > 10 ? previousMessages.length - 10 : 0)
        .map((msg) => <String, String>{
              'role': msg['isUser'] == true ? 'user' : 'assistant',
              'text': msg['text']?.toString() ?? '',
            })
        .toList();

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final reply = await AiService.kirimPesan(text, history: history);
      setState(() {
        _messages.add({'text': reply, 'isUser': false});
      });
        } catch (e) {
        setState(() {
          // TAMPILKAN ERROR ASLI
          _messages.add({
            'text': 'Error: $e', 
            'isUser': false, 
            'isError': true
          });
        });
        } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background, 
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.white),
            const SizedBox(width: 8),
            Text('Eclipse AI', style: AppTheme.textTheme.titleMedium?.copyWith(color: AppTheme.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Area Chat
          Expanded(
            child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildChatBubble(msg);
                  },
                ),
          ),
          
          // Area Input 
          SafeArea(
            top: false, 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                border: Border(top: BorderSide(color: AppTheme.greyLight, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLength: 500, // Syarat Brief Maksimal 500 Karakter 
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Tanya seputar Eclipse...',
                          counterText: '', // Sembunyikan hitungan
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          hintStyle: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.grey),
                        ),
                        onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Tombol Kirim Bulat
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, color: AppTheme.white),
                      onPressed: _isLoading ? null : _sendMessage,
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

  // Widget Tampilan Saat Kosong (Empty State)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_rounded, size: 80, color: AppTheme.primaryLight),
          const SizedBox(height: 16),
          Text(
            'Halo, Eclipse Lovers!',
            style: AppTheme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tanya apa saja seputar member, event, atau produk.',
            style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widget Bubble Chat Modern
  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final isUser = msg['isUser'] as bool;
    final isError = msg['isError'] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar AI (Hanya muncul di pesan AI)
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.3),
              radius: 16,
              child: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.primaryDark),
            ),
            const SizedBox(width: 8),
          ],
          
          // Bubble Pesan
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                  ? AppTheme.primaryDark 
                  : (isError ? Colors.red.shade50 : AppTheme.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                ),
                border: isError ? Border.all(color: Colors.red.shade200) : null,
                boxShadow: isUser || isError ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['text'],
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                      color: isUser ? AppTheme.white : (isError ? Colors.red.shade700 : AppTheme.black),
                      height: 1.4,
                    ),
                  ),
                  if (isError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: InkWell(
                        onTap: _isLoading ? null : () {
                          setState(() {
                            _messages.removeLast();
                          });
                          _sendMessage();
                        },
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
} 