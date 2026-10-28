import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/cosmic_widgets.dart';
import 'game_controller.dart';
import 'sensor_service.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final SensorService _sensorService = SensorService();

  String? _selectedOption;
  bool _isAnswered = false;
  int _highlightedIndex = 0;
  int _lastRound = -1;

  @override
  void dispose() {
    _sensorService.stopSensors();
    super.dispose();
  }

  void _resetAnswerState() {
    _selectedOption = null;
    _isAnswered = false;
    _highlightedIndex = 0;
  }

  void _startSensors(GameController controller) {
    _sensorService.stopSensors();

    _sensorService.listenSensors(
      onMove: (direction) {
        if (!mounted ||
            controller.questions.isEmpty ||
            controller.isGameOver ||
            _isAnswered) {
          return;
        }

        final options = controller.currentQuestion.options.take(2).toList();

        if (options.length < 2) return;

        setState(() {
          const visibleCount = 2;
          _highlightedIndex = (_highlightedIndex + direction) % visibleCount;

          if (_highlightedIndex < 0) {
            _highlightedIndex += visibleCount;
          }
        });
      },
      onConfirm: () {
        if (!mounted ||
            controller.questions.isEmpty ||
            controller.isGameOver ||
            _isAnswered) {
          return;
        }

        final options = controller.currentQuestion.options.take(2).toList();

        if (options.isEmpty) return;

        final index = _highlightedIndex.clamp(0, options.length - 1);

        _handleAnswer(index, options[index], controller);
      },
    );
  }

  Future<void> _handleAnswer(
    int index,
    String option,
    GameController controller,
  ) async {
    if (_isAnswered) return;

    controller.pauseTimer();

    setState(() {
      _highlightedIndex = index;
      _selectedOption = option;
      _isAnswered = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    await controller.answerQuestion(option);
  }

  Future<void> _startNewGame(GameController controller) async {
    _sensorService.stopSensors();

    setState(() {
      _lastRound = -1;
      _resetAnswerState();
    });

    await controller.startGame();

    if (!mounted) return;

    if (controller.questions.isNotEmpty && !controller.isGameOver) {
      _startSensors(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameController(),
      child: Scaffold(
        backgroundColor: AppTheme.deepSpace,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Guess the Member'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<GameController>(
          builder: (context, controller, _) {
            if (controller.loadError != null && controller.questions.isEmpty) {
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
              return _buildStart(context, controller);
            }

            if (controller.isGameOver) {
              _sensorService.stopSensors();
              return _buildResult(context, controller);
            }

            // Halaman kuis dan status sensor di bagian bawah.
            return Column(
              children: [
                Expanded(child: _buildQuiz(context, controller)),
                SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      border: Border(
                        top: BorderSide(color: AppTheme.borderSubtle, width: 1),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.screen_rotation_alt_rounded,
                          size: 17,
                          color: AppTheme.coolCyan,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Miringkan HP untuk berpindah pilihan, '
                            'gerakkan HP untuk konfirmasi, '
                            'atau tap jawaban.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStart(BuildContext context, GameController controller) {
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
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.eclipseViolet.withValues(alpha: .35),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Guess the Member!',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const CosmicCard(
              child: Text(
                'Kenali member Eclipse lewat posisi dan fun fact mereka.\n\n'
                'Miringkan HP ke kiri/kanan untuk berpindah pilihan, '
                'lalu gerakkan HP untuk memilih. Kamu juga bisa '
                'langsung tap jawaban.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.eclipseViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _startNewGame(controller),
                child: const Text(
                  'Mulai Bermain',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz(BuildContext context, GameController controller) {
    if (controller.currentRound != _lastRound) {
      _lastRound = controller.currentRound;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(_resetAnswerState);
        }
      });
    }

    final question = controller.currentQuestion;
    final options = question.options.take(2).toList();

    final progress =
        ((controller.currentRound + 1) / controller.questions.length).clamp(
          0.0,
          1.0,
        );

    final timeProgress = (controller.timeLeft / controller.roundDuration).clamp(
      0.0,
      1.0,
    );

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progres kuis',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                Text(
                  '${controller.currentRound + 1}/'
                  '${controller.questions.length}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceSecondary,
                color: AppTheme.eclipseViolet,
              ),
            ),
            const SizedBox(height: 10),

            // Timer
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: timeProgress,
                      minHeight: 5,
                      backgroundColor: AppTheme.surfaceSecondary,
                      color: controller.timeLeft > 5
                          ? AppTheme.coolCyan
                          : AppTheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${controller.timeLeft}s',
                  style: TextStyle(
                    color: controller.timeLeft > 5
                        ? AppTheme.textSecondary
                        : AppTheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Kartu soal
            CosmicCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 28,
                    color: AppTheme.coronaGold,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.funFact,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Dua kartu jawaban
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(options.length, (index) {
                  final option = options[index];

                  // Hilangkan awalan A. atau B. dari teks jawaban.
                  final displayOption = option.replaceFirst(
                    RegExp(r'^[A-D]\.\s*'),
                    '',
                  );

                  final selected = option == _selectedOption;
                  final highlighted =
                      index == _highlightedIndex && !_isAnswered;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == 0 ? 5 : 0,
                        left: index == 1 ? 5 : 0,
                      ),
                      child: AnimatedScale(
                        scale: highlighted ? 1.015 : 1.0,
                        duration: const Duration(milliseconds: 160),
                        child: ElevatedButton(
                          onPressed: _isAnswered
                              ? null
                              : () => _handleAnswer(index, option, controller),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selected || highlighted
                                ? AppTheme.eclipseViolet
                                : AppTheme.surfaceElevated,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: selected
                                ? AppTheme.eclipseViolet
                                : AppTheme.surfaceElevated,
                            disabledForegroundColor: Colors.white,
                            elevation: highlighted ? 3 : 1,
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: highlighted
                                    ? AppTheme.coolCyan
                                    : AppTheme.borderSubtle,
                                width: highlighted ? 1.5 : 1,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                String.fromCharCode(65 + index),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: Text(
                                  displayOption,
                                  textAlign: TextAlign.center,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, GameController controller) {
    if (controller.isSubmitting) {
      return const CosmicLoading(message: 'Menghitung skor...');
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.coronaGold.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 78,
                color: AppTheme.coronaGold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Permainan Selesai!',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            CosmicCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Skor Akhir',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${controller.score}',
                          style: const TextStyle(
                            color: AppTheme.coolCyan,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Poin',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 70, color: AppTheme.borderSubtle),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Jawaban Benar',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${controller.correctCount}/'
                          '${controller.questions.length}',
                          style: const TextStyle(
                            color: AppTheme.success,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Tertinggi: ${controller.bestScore}',
                          style: const TextStyle(
                            color: AppTheme.coronaGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (controller.loadError != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.error),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startNewGame(controller),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Main Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.eclipseViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.shell,
                (route) => false,
              ),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Kembali ke Home'),
            ),
          ],
        ),
      ),
    );
  }
}
