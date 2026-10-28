import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../theme/app_theme.dart';
import 'ai_service.dart';
import '../membership/membership_service.dart';
import '../game/game_service.dart';

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
  String _membershipLabel = 'Memeriksa membership...';
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _loadLandingInfo();
  }

  Future<void> _loadLandingInfo() async {
    try {
      final results = await Future.wait<dynamic>([
        MembershipService.currentMembership(),
        GameService.getBestScore(),
      ]);
      if (!mounted) return;
      final membership = results[0] as Map<String, dynamic>?;
      final plan = membership?['membership_plans'];
      final isActive = await MembershipService.isActive();
      if (!mounted) return;
      setState(() {
        _membershipLabel = isActive
            ? (plan is Map ? '${plan['name'] ?? 'Member aktif'}' : 'Member aktif')
            : 'Belum menjadi member';
        _bestScore = results[1] as int? ?? 0;
      });
    } catch (_) {
      if (mounted) setState(() => _membershipLabel = 'Status belum tersedia');
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final reply = await AiService.kirimPesan(text);
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
      backgroundColor: AppTheme.deepSpace, 
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.textPrimary),
            const SizedBox(width: 8),
            Text('Eclipse AI', style: AppTheme.textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppTheme.deepSpace,
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
                color: AppTheme.deepSpace,
                border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
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
                          hintStyle: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                        ),
                        onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Tombol Kirim Bulat
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.eclipseViolet,
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.eclipseViolet.withValues(alpha: 0.18),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 54, color: AppTheme.coolCyan),
            ),
            const SizedBox(height: 16),
            Text(
              'Eclipse AI siap membantu!',
              style: AppTheme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      color: AppTheme.surfaceElevated,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.workspace_premium, color: AppTheme.coronaGold),
                            const SizedBox(height: 8),
                            const Text('Membership', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(_membershipLabel, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      color: AppTheme.surfaceElevated,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.emoji_events, color: AppTheme.coolCyan),
                            const SizedBox(height: 8),
                            const Text('Skor tertinggi', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('$_bestScore poin', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tanya apa saja seputar member, event, atau produk.',
              style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                  : (isError ? Colors.red.shade50 : AppTheme.surfaceElevated),
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
                  if (isUser || isError)
                    Text(
                      msg['text'] as String,
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        color: isUser ? AppTheme.white : Colors.red.shade700,
                        height: 1.4,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: msg['text'] as String,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: AppTheme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                        h1: AppTheme.textTheme.titleLarge?.copyWith(color: AppTheme.black),
                        h2: AppTheme.textTheme.titleMedium?.copyWith(color: AppTheme.black),
                        h3: AppTheme.textTheme.titleSmall?.copyWith(color: AppTheme.black),
                        code: const TextStyle(fontFamily: 'monospace', color: AppTheme.black),
                        blockquote: const TextStyle(color: AppTheme.black),
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