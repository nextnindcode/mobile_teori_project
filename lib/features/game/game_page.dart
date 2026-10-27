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
        if (!mounted) return;
        if (controller.questions.isEmpty) return;
        if (controller.isGameOver) return;
        if (_isAnswered) return;
        setState(() {
          final optionCount = controller.currentQuestion.options.length;
          final visibleCount = optionCount > 2 ? 2 : optionCount;
          _highlightedIndex = (_highlightedIndex + direction) % visibleCount;
          if (_highlightedIndex < 0) _highlightedIndex = visibleCount - 1;
        });
      },
      onConfirm: () {
        if (!_isAnswered &&
            controller.questions.isNotEmpty &&
            !controller.isGameOver) {
          final selected = controller.currentQuestion.options[_highlightedIndex];
          _handleAnswer(_highlightedIndex, selected, controller);
        }
      },
    );
  }

  void _handleAnswer(int index, String option, GameController controller) async {
    if (_isAnswered) return;

    final correct = controller.currentCorrectAnswer?.trim().toUpperCase();
    final picked = option.split('.').first.trim().toUpperCase();
    final isCorrect = (correct == null || correct.isEmpty) ? null : correct == picked;

    controller.pauseTimer();

    setState(() {
      _highlightedIndex = index;
      _selectedOption = option;
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    await controller.answerQuestion(option);
  }

  Future<void> _startNewGame(GameController controller,
      {required bool memberChallenge}) async {
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
            if (_isLoadingMember) {
              return const CosmicLoading(message: 'Menyiapkan Game...');
            }
            if (controller.loadError != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    controller.loadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.error),
                  ),
                ),
              );
            }
            if (controller.questions.isEmpty) {
              return _buildStartScreen(context, controller);
            }
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.eclipseViolet.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.sports_esports, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text(
              'Guess the Member!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            CosmicCard(
              child: const Text(
                'Baca petunjuk, lalu tebak membernya.\n\n'
                'Miringkan HP ke Atas/Bawah untuk memilih, dan anggukkan HP untuk konfirmasi jawaban. '
                'Atau gunakan sentuhan (Tap).',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 40),

            // TOMBOL 1: Main Biasa
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.eclipseViolet,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _startNewGame(controller, memberChallenge: false),
                child: const Text('Mulai Bermain',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),

            if (!_isMember)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  '*Kumpulkan poin dan tukarkan dengan Photocard eksklusif dengan menjadi Member!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.coronaGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CosmicBadge(
                text: 'Ronde ${controller.currentRound + 1}/${controller.questions.length}',
                color: AppTheme.coolCyan,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (controller.timeLeft / controller.roundDuration).clamp(0.0, 1.0),
              backgroundColor: AppTheme.surfaceSecondary,
              color: controller.timeLeft > 5 ? AppTheme.coolCyan : AppTheme.error,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sisa waktu: ${controller.timeLeft} detik',
            style: TextStyle(
              color: controller.timeLeft > 5 ? AppTheme.textSecondary : AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          CosmicCard(
            child: Column(
              children: [
                const Icon(Icons.format_quote_rounded, size: 48, color: AppTheme.coolCyan),
                const SizedBox(height: 12),
                Text(
                  question.funFact,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: List.generate(
                question.options.length > 2 ? 2 : question.options.length,
                (index) {
                  final option = question.options[index];
                  final isSelected = option == _selectedOption;
                  final isHighlighted = index == _highlightedIndex;

                  Color buttonColor = AppTheme.surfaceElevated;
                  Color textColor = AppTheme.textPrimary;
                  Color borderColor = AppTheme.borderSubtle;

                  if (isHighlighted && !_isAnswered) {
                    buttonColor = AppTheme.eclipseViolet;
                    textColor = Colors.white;
                    borderColor = AppTheme.eclipseViolet;
                  }

                  if (_isAnswered && isSelected) {
                    if (_isCorrect == true) {
                      buttonColor = AppTheme.success;
                      borderColor = AppTheme.success;
                    } else if (_isCorrect == false) {
                      buttonColor = AppTheme.error;
                      borderColor = AppTheme.error;
                    } else {
                      buttonColor = AppTheme.coolCyan;
                      borderColor = AppTheme.coolCyan;
                    }
                    textColor = Colors.white;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: AnimatedScale(
                        scale: isHighlighted ? 1.02 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: textColor,
                              elevation: isHighlighted ? 8 : 2,
                              shadowColor: AppTheme.eclipseViolet.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: borderColor, width: 2),
                              ),
                            ),
                            onPressed: _isAnswered
                                ? null
                                : () => _handleAnswer(index, option, controller),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  option,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                if (_isAnswered && isSelected && _isCorrect != null) ...[
                                  const SizedBox(height: 6),
                                  Icon(
                                    _isCorrect! ? Icons.check_circle : Icons.cancel,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 12, right: 12),
            child: Text(
              'Miringkan HP ke atas/bawah untuk memilih jawaban. Anggukkan HP untuk konfirmasi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen(BuildContext context, GameController controller) {
    if (controller.isSubmitting) {
      return const CosmicLoading(message: 'Menghitung skor...');
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.coronaGold.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, size: 80, color: AppTheme.coronaGold),
            ),
            const SizedBox(height: 24),
            const Text('Permainan Selesai!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 24),
            CosmicCard(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      const Text('Skor Akhir', style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${controller.score}',
                          style: const TextStyle(color: AppTheme.coolCyan, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Terbaik: ${controller.bestScore}',
                          style: const TextStyle(color: AppTheme.coronaGold, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(height: 60, width: 1, color: AppTheme.borderSubtle, margin: const EdgeInsets.symmetric(horizontal: 24)),
                  Column(
                    children: [
                      const Text('Benar', style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${controller.correctCount}/${controller.questions.length}',
                          style: const TextStyle(color: AppTheme.success, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.eclipseViolet,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _startNewGame(controller, memberChallenge: _memberChallenge),
                child: const Text('Main Lagi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali ke Home',
                  style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}