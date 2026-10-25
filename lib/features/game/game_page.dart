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
  int _highlightedIndex = 0; 

  bool _isLoadingMember = true;
  bool _isMember = false; 

  @override
  void initState() {
    super.initState();
    _cekStatusMember();
  }

  Future<void> _cekStatusMember() async {
    final isMember = await MembershipService.checkIsMember();
    if (mounted) {
      setState(() {
        _isMember = isMember;
        _isLoadingMember = false;
      });
    }
  }

  @override
  void dispose() {
    _sensorService.stopSensors(); 
    super.dispose();
  }

  void _startSensors(GameController controller) {
    _sensorService.listenSensors(
      onMove: (direction) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + direction) % 2;
          if (_highlightedIndex < 0) _highlightedIndex = 1;
        });
      },
      onConfirm: () {
        if (!_isAnswered && controller.questions.isNotEmpty && !controller.isGameOver) {
          String selectedOption = controller.currentQuestion.options[_highlightedIndex];
          _handleAnswer(_highlightedIndex, selectedOption, controller);
        }
      },
    );
  }

  void _handleAnswer(int index, String option, GameController controller) async {
    if (_isAnswered) return; 
    setState(() {
      _highlightedIndex = index; 
      _selectedOption = option;
      _isAnswered = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    controller.answerQuestion(option);

    setState(() {
      _selectedOption = null;
      _isAnswered = false;
      _highlightedIndex = 0; 
    });
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
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<GameController>(
          builder: (context, controller, child) {
            if (_isLoadingMember) {
              return const CosmicLoading(message: 'Menyiapkan Game...');
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
    // Semua member bisa mengakses mini game 
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
                  BoxShadow(color: AppTheme.eclipseViolet.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5),
                ],
              ),
              child: const Icon(Icons.sports_esports, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text(
              'Guess the Member!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            CosmicCard(
              child: const Text(
                'Baca petunjuk, lalu tebak membernya.\n\nMiringkan HP ke Kiri/Kanan untuk memilih, dan anggukkan HP untuk konfirmasi jawaban. Atau gunakan sentuhan (Tap).',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
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
                onPressed: () {
                  controller.startGame(isMemberMode: _isMember);
                  _startSensors(controller); 
                },
                child: const Text('Mulai Bermain', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isMember)
              const Text(
                '*Kumpulkan poin dan tukarkan dengan Photocard eksklusif dengan menjadi Member!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.coronaGold, fontSize: 12, fontWeight: FontWeight.bold),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildPlayScreen(BuildContext context, GameController controller) {
    final question = controller.currentQuestion;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CosmicBadge(text: 'Ronde ${controller.currentRound + 1}/${controller.maxRounds}', color: AppTheme.coolCyan),
              CosmicBadge(text: 'Skor: ${controller.score}', color: AppTheme.eclipseViolet, textColor: Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: controller.timeLeft / 15,
              backgroundColor: AppTheme.surfaceSecondary,
              color: controller.timeLeft > 5 ? AppTheme.coolCyan : AppTheme.error,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text('Sisa waktu: ${controller.timeLeft} detik', 
            style: TextStyle(color: controller.timeLeft > 5 ? AppTheme.textSecondary : AppTheme.error, fontWeight: FontWeight.bold)),
          
          const SizedBox(height: 24),

          CosmicCard(
            child: Column(
              children: [
                const Icon(Icons.format_quote_rounded, size: 48, color: AppTheme.coolCyan),
                const SizedBox(height: 12),
                Text(question.funFact, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: Row(
              children: List.generate(question.options.length, (index) {
                final option = question.options[index];
                bool isCorrectAnswer = option == question.correctAnswer;
                bool isSelected = option == _selectedOption;
                bool isHighlighted = index == _highlightedIndex;

                Color buttonColor = AppTheme.surfaceElevated;
                Color textColor = AppTheme.textPrimary;
                Color borderColor = AppTheme.borderSubtle;

                if (isHighlighted && !_isAnswered) {
                  buttonColor = AppTheme.eclipseViolet; 
                  textColor = Colors.white;
                  borderColor = AppTheme.eclipseViolet;
                }

                if (_isAnswered) {
                  if (isCorrectAnswer) {
                    buttonColor = AppTheme.success; textColor = Colors.white; borderColor = AppTheme.success;
                  } else if (isSelected && !isCorrectAnswer) {
                    buttonColor = AppTheme.error; textColor = Colors.white; borderColor = AppTheme.error;
                  }
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: borderColor, width: 2)),
                          ),
                          onPressed: () => _handleAnswer(index, option, controller),
                          child: Text(option, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Miring ke Kiri/Kanan: Geser • Anggukkan ke Depan: Konfirmasi',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen(BuildContext context, GameController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.coronaGold.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.emoji_events_rounded, size: 80, color: AppTheme.coronaGold),
            ),
            const SizedBox(height: 24),
            const Text('Permainan Selesai!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 24),
            
            CosmicCard(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      const Text('Skor Akhir', style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${controller.score}', style: const TextStyle(color: AppTheme.coolCyan, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Terbaik: ${controller.bestScore}', style: const TextStyle(color: AppTheme.coronaGold, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(height: 60, width: 1, color: AppTheme.borderSubtle, margin: const EdgeInsets.symmetric(horizontal: 24)),
                  Column(
                    children: [
                      const Text('Benar', style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${controller.correctCount}/${controller.maxRounds}', style: const TextStyle(color: AppTheme.success, fontSize: 32, fontWeight: FontWeight.bold)),
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
                onPressed: () {
                  controller.startGame(isMemberMode: _isMember);
                  _startSensors(controller);
                },
                child: const Text('Main Lagi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali ke Home', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}