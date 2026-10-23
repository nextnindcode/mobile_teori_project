// Game ini mirip dengan kahoot 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
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
  int _highlightedIndex = 0;
  bool _memberChallenge = false; 

  @override
  void dispose() {
    _sensorService.stopSensors(); 
    super.dispose();
  }

  void _startSensors(GameController controller) {
    _sensorService.listenSensors(
      onMove: (direction) {
        setState(() {
          // Navigasi melingkar untuk 2 pilihan (0 -> 1 -> 0)
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
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(_memberChallenge ? 'Tantangan Member' : 'Guess the Member'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<GameController>(
          builder: (context, controller, child) {
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
                    color: AppTheme.primaryDark.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.sports_esports, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              'Guess the Member!',
              style: AppTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.5)),
              ),
              child: Text(
                'Baca petunjuk, lalu tebak nama membernya.\n\nMiringkan HP ke Kiri/Kanan untuk memilih, dan anggukkan HP ke depan untuk konfirmasi jawaban. Atau gunakan sentuhan (Tap).',
                textAlign: TextAlign.center,
                style: AppTheme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppTheme.primaryButtonStyle,
                onPressed: () async {
                  setState(() => _memberChallenge = false);
                  await controller.startGame();
                  _startSensors(controller);
                },
                child: const Text('Mulai Bermain'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Tantangan Member · 10 detik/ronde'),
                onPressed: () async {
                  try {
                    final active = await MembershipService.isActive();
                    if (!mounted) return;
                    if (!active) {
                      Navigator.pushNamed(context, Routes.membership);
                      return;
                    }
                    setState(() => _memberChallenge = true);
                    await controller.startGame(memberChallenge: true);
                    _startSensors(controller);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Status membership gagal diperiksa: $e')),
                    );
                  }
                },
              ),
            ),
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
        // Header ronde dan skor 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge Ronde
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.white, 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryLight, width: 2), 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text('Ronde ${controller.currentRound + 1}/10', 
                  style: AppTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryDark, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )),
              ),
              
              // Badge Skor
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.white, 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryDark, width: 2), 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text('Skor: ${controller.score}', 
                  style: AppTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryDark, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: controller.timeLeft / 15,
              backgroundColor: AppTheme.greyLight,
              color: controller.timeLeft > 5 ? AppTheme.primaryDark : Colors.red,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text('Sisa waktu: ${controller.timeLeft} detik', 
            style: AppTheme.textTheme.bodySmall?.copyWith(color: controller.timeLeft > 5 ? AppTheme.grey : Colors.red, fontWeight: FontWeight.bold)),
          
          const SizedBox(height: 24),

          // Kotak Soal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryDark.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.format_quote_rounded, size: 48, color: AppTheme.primaryLight),
                const SizedBox(height: 12),
                Text(
                  question.funFact,
                  textAlign: TextAlign.center,
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2 Tombol Pilihan Jawaban Berdampingan Kiri dan Kanan 
          Expanded(
            child: Row(
              children: List.generate(question.options.length, (index) {
                final option = question.options[index];
                bool isCorrectAnswer = false;
                bool isSelected = option == _selectedOption;
                bool isHighlighted = index == _highlightedIndex;

                Color buttonColor = AppTheme.white;
                Color textColor = AppTheme.primaryDark;
                Color borderColor = AppTheme.primaryLight;

                // Sorotan Sensor
                if (isHighlighted && !_isAnswered) {
                  buttonColor = AppTheme.primaryDark; 
                  textColor = Colors.white;
                  borderColor = AppTheme.primaryDark;
                }

                // Feedback Jawaban Benar/Salah
                if (_isAnswered && isSelected) {
                  buttonColor = AppTheme.eclipseViolet;
                  textColor = Colors.white;
                  borderColor = AppTheme.eclipseViolet;
                }

                return Expanded(
                  child: Padding(
                    // Jarak antar tombol kiri dan kanan
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
                            shadowColor: AppTheme.primaryDark.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: borderColor, width: 2),
                            ),
                          ),
                          onPressed: () => _handleAnswer(index, option, controller),
                          child: Text(
                            option,
                            textAlign: TextAlign.center,
                            style: AppTheme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Teks Petunjuk
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Miring ke Kiri/Kanan: Geser • Anggukkan ke Depan: Konfirmasi Jawaban',
              style: AppTheme.textTheme.bodySmall?.copyWith(color: AppTheme.grey),
            ),
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
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, size: 80, color: Colors.amber),
            ),
            const SizedBox(height: 24),
            Text(
              'Permainan Selesai!',
              style: AppTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      Text('Skor Akhir', style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.grey)),
                      const SizedBox(height: 4),
                      Text('${controller.score}', style: AppTheme.textTheme.headlineMedium?.copyWith(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Terbaik: ${controller.bestScore}', 
                        style: AppTheme.textTheme.bodySmall?.copyWith(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    height: 60, 
                    width: 1,
                    color: AppTheme.greyLight,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  Column(
                    children: [
                      Text('Benar', style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.grey)),
                      const SizedBox(height: 4),
                      Text('${controller.correctCount}/10', style: AppTheme.textTheme.headlineMedium?.copyWith(color: AppTheme.success, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppTheme.primaryButtonStyle,
                onPressed: () {
                  controller.startGame();
                  _startSensors(controller);
                },
                child: const Text('Main Lagi'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali ke Home', style: TextStyle(color: AppTheme.grey, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}