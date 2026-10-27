import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart';
import 'game_controller.dart';
import 'sensor_service.dart';
import '../membership/membership_service.dart';
import '../../core/routes.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final SensorService _sensorService = SensorService();
  String? _selectedOption;
  bool _isAnswered = false;
  bool? _isCorrect;
  int _highlightedIndex = 0;
  bool _memberChallenge = false;
  int _lastRound = -1;
  bool _isLoadingMember = true;
  bool _isMember = false;

  @override
  void initState() {
    super.initState();
    _cekStatusMember();
  }

  Future<void> _cekStatusMember() async {
    try {
      final isMember = await MembershipService.isActive();
      if (mounted) {
        setState(() {
          _isMember = isMember;
          _isLoadingMember = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isMember = false;
          _isLoadingMember = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _sensorService.stopSensors();
    super.dispose();
  }

  void _resetLocalState() {
    _selectedOption = null;
    _isAnswered = false;
    _isCorrect = null;
    _highlightedIndex = 0;
  }

  void _startSensors(GameController controller) {
    _sensorService.stopSensors();
    _sensorService.listenSensors(
      onMove: (direction) {
        if (!mounted || controller.questions.isEmpty || controller.isGameOver || _isAnswered) return;
        setState(() {
          final count = controller.currentQuestion.options.length;
          if (count == 0) return;
          _highlightedIndex = (_highlightedIndex + direction) % count;
          if (_highlightedIndex < 0) _highlightedIndex = count - 1;
        });
      },
      onConfirm: () {
        if (!_isAnswered && controller.questions.isNotEmpty && !controller.isGameOver) {
          final selected = controller.currentQuestion.options[_highlightedIndex];
          _handleAnswer(_highlightedIndex, selected, controller);
        }
      },
    );
  }

  void _handleAnswer(int index, String option, GameController controller) async {
    if (_isAnswered) return;
    controller.pauseTimer();
    setState(() {
      _highlightedIndex = index;
      _selectedOption = option;
      _isAnswered = true;
      _isCorrect = null;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await controller.answerQuestion(option);
  }

  Future<void> _startNewGame(GameController controller, {required bool memberChallenge}) async {
    _sensorService.stopSensors();
    setState(() {
      _memberChallenge = memberChallenge;
      _lastRound = -1;
      _resetLocalState();
    });
    await controller.startGame(memberChallenge: memberChallenge);
    if (!mounted) return;
    _startSensors(controller);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameController(),
      child: Scaffold(
        backgroundColor: AppTheme.deepSpace,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(_memberChallenge ? 'Tantangan Member' : 'Guess the Member'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<GameController>(
          builder: (context, controller, child) {
            if (_isLoadingMember) return const CosmicLoading(message: 'Menyiapkan Game...');
            if (controller.loadError != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(controller.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
                ),
              );
            }
            if (controller.questions.isEmpty) return _buildStartScreen(context, controller);
            if (controller.isGameOver) {
              _sensorService.stopSensors();
              return _buildGameOverScreen(context, controller);
            }
            return _buildPlayScreen(context, controller);
          },
        ),
      ),
    );
  }

  Widget _buildStartScreen(BuildContext context, GameController controller) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.eclipseViolet.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5)],
              ),
              child: const Icon(Icons.auto_awesome, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 28),
            const Text('Guess the Member', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('10 soal acak • 15 detik per ronde', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 22),
            CosmicCard(
              child: const Text(
                'Baca petunjuknya, lalu pilih member Eclipse yang paling tepat.\n\n'
                'Kamu bisa tap jawaban atau gunakan sensor: miringkan HP untuk berpindah pilihan dan anggukkan HP untuk memilih.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.eclipseViolet,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _startNewGame(controller, memberChallenge: false),
                label: const Text('Mulai Bermain', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Tantangan Member • 10 detik'),
                onPressed: () async {
                  try {
                    final active = await MembershipService.isActive();
                    if (!context.mounted) return;
                    if (!active) {
                      Navigator.pushNamed(context, Routes.membership);
                      return;
                    }
                    await _startNewGame(controller, memberChallenge: true);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status membership gagal diperiksa: $e')));
                  }
                },
              ),
            ),
            if (!_isMember)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('*Mode Member membuka tantangan dengan waktu lebih singkat.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.coronaGold, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayScreen(BuildContext context, GameController controller) {
    if (controller.currentRound != _lastRound) {
      _lastRound = controller.currentRound;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(_resetLocalState);
      });
    }

    final question = controller.currentQuestion;
    final options = question.options;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CosmicBadge(text: 'Soal ${controller.currentRound + 1}/${controller.questions.length}', color: AppTheme.coolCyan),
              Text('${controller.score} poin', style: const TextStyle(color: AppTheme.coronaGold, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (controller.timeLeft / controller.roundDuration).clamp(0.0, 1.0),
              backgroundColor: AppTheme.surfaceSecondary,
              color: controller.timeLeft > 5 ? AppTheme.coolCyan : AppTheme.error,
              minHeight: 9,
            ),
          ),
          const SizedBox(height: 7),
          Text('Sisa waktu ${controller.timeLeft} detik', style: TextStyle(color: controller.timeLeft > 5 ? AppTheme.textSecondary : AppTheme.error, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          CosmicCard(
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, size: 34, color: AppTheme.coolCyan),
                const SizedBox(height: 10),
                Text(question.funFact, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: options.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.45),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == _selectedOption;
                final isHighlighted = index == _highlightedIndex;
                final active = !_isAnswered && isHighlighted;
                final buttonColor = active ? AppTheme.eclipseViolet : AppTheme.surfaceElevated;
                final borderColor = active ? AppTheme.eclipseViolet : AppTheme.borderSubtle;
                return AnimatedScale(
                  scale: active ? 1.02 : 1,
                  duration: const Duration(milliseconds: 160),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      elevation: active ? 8 : 2,
                      shadowColor: AppTheme.eclipseViolet.withValues(alpha: 0.25),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: borderColor, width: 1.5)),
                    ),
                    onPressed: _isAnswered ? null : () => _handleAnswer(index, option, controller),
                    child: Text(option, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text('Miringkan HP untuk berpindah • Anggukkan untuk memilih', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen(BuildContext context, GameController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 78, color: AppTheme.coronaGold),
            const SizedBox(height: 20),
            const Text('Round Complete!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            CosmicCard(
              child: Column(
                children: [
                  Text('${controller.score}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: AppTheme.coronaGold)),
                  const Text('poin', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 14),
                  Text('${controller.correctCount}/${controller.questions.length} jawaban benar', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Best score: ${controller.bestScore}', style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (controller.isSubmitting) const CircularProgressIndicator(),
            if (!controller.isSubmitting)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.replay_rounded),
                  onPressed: () => _startNewGame(controller, memberChallenge: _memberChallenge),
                  label: const Text('Main Lagi'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
