import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart';
import 'game_controller.dart';
import 'sensor_service.dart';
import '../membership/membership_service.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final SensorService _sensorService = SensorService();
  String? _selectedOption;
  bool _isAnswered = false;
  bool _isAnswering = false;
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
    _isAnswering = false;
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
          if (_highlightedIndex < 0) _highlightedIndex += count;
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

  Future<void> _handleAnswer(int index, String option, GameController controller) async {
    if (_isAnswered || _isAnswering) return;
    _isAnswering = true;
    controller.pauseTimer();

    setState(() {
      _highlightedIndex = index;
      _selectedOption = option;
      _isAnswered = true;
    });

    // Tidak menampilkan benar/salah atau kunci jawaban di perangkat.
    await Future.delayed(const Duration(milliseconds: 650));
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.eclipseViolet.withValues(alpha: .4), blurRadius: 30, spreadRadius: 5)],
              ),
              child: const Icon(Icons.sports_esports, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 28),
            const Text('Guess the Member!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 14),
            CosmicCard(
              child: const Text(
                'Kenali member Eclipse lewat fun fact mereka.\n\nMiringkan HP untuk berpindah pilihan dan gunakan gerakan gyroscope untuk memilih. Kamu juga bisa langsung tap salah satu jawaban.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.eclipseViolet,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _startNewGame(controller, memberChallenge: false),
                child: const Text('Mulai Bermain', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            if (!_isMember)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  '*Kumpulkan poin dan tukarkan dengan Photocard eksklusif dengan menjadi Member!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.coronaGold, fontSize: 12, fontWeight: FontWeight.bold),
                ),
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
    final progress = ((controller.currentRound + 1) / controller.questions.length).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progres kuis', style: TextStyle(color: AppTheme.textSecondary)),
              Text('${controller.currentRound + 1} / ${controller.questions.length}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, backgroundColor: AppTheme.surfaceSecondary, color: AppTheme.eclipseViolet, minHeight: 7),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (controller.timeLeft / controller.roundDuration).clamp(0.0, 1.0),
                    backgroundColor: AppTheme.surfaceSecondary,
                    color: controller.timeLeft > 5 ? AppTheme.coolCyan : AppTheme.error,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${controller.timeLeft}s', style: TextStyle(color: controller.timeLeft > 5 ? AppTheme.textSecondary : AppTheme.error, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          CosmicCard(
            child: Column(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 40, color: AppTheme.coolCyan),
                const SizedBox(height: 10),
                Text(question.funFact, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.65,
              padding: EdgeInsets.zero,
              children: List.generate(question.options.length, (index) {
                final option = question.options[index];
                final selected = option == _selectedOption;
                final highlighted = index == _highlightedIndex;
                final active = !_isAnswered && highlighted;
                return AnimatedScale(
                  scale: active ? 1.02 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected ? AppTheme.eclipseViolet : AppTheme.surfaceElevated,
                      foregroundColor: Colors.white,
                      elevation: active ? 7 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: active ? AppTheme.coolCyan : AppTheme.borderSubtle, width: active ? 2 : 1),
                      ),
                    ),
                    onPressed: _isAnswered ? null : () => _handleAnswer(index, option, controller),
                    child: Text(option, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Miringkan HP untuk berpindah pilihan • gerakkan HP untuk konfirmasi • atau tap jawaban', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen(BuildContext context, GameController controller) {
    if (controller.isSubmitting) return const CosmicLoading(message: 'Menghitung skor...');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.coronaGold.withValues(alpha: .2), shape: BoxShape.circle),
              child: const Icon(Icons.emoji_events_rounded, size: 80, color: AppTheme.coronaGold),
            ),
            const SizedBox(height: 24),
            const Text('Permainan Selesai!', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            Text('Skor ${controller.score}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppTheme.coolCyan)),
            const SizedBox(height: 6),
            Text('${controller.correctCount} jawaban benar dari ${controller.questions.length} soal', style: const TextStyle(color: AppTheme.textSecondary)),
            if (controller.loadError != null) ...[
              const SizedBox(height: 12),
              Text(controller.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startNewGame(controller, memberChallenge: _memberChallenge),
                child: const Text('Main Lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
