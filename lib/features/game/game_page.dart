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
  int _highlightedIndex = 0;
  bool _memberChallenge = false; 

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
    } catch (e) {
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

  void _startSensors(GameController controller) {
    _sensorService.listenSensors(
      onMove: (direction) {
        if (controller.questions.isEmpty) return;
        setState(() {
          final optionCount = controller.currentQuestion.options.length;
          _highlightedIndex = (_highlightedIndex + direction) % optionCount;
          if (_highlightedIndex < 0) _highlightedIndex = optionCount - 1;
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

    if (!mounted) return;

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
                  child: Text(controller.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error)),
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
                onPressed: () async {
                  setState(() => _memberChallenge = false);
                  await controller.startGame(memberChallenge: false);
                  if (!mounted) return;
                  _startSensors(controller); 
                },
                child: const Text('Mulai Bermain', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    if (!context.mounted) return;
                    if (!active) {
                      Navigator.pushNamed(context, Routes.membership);
                      return;
                    }
                    setState(() => _memberChallenge = true);
                    await controller.startGame(memberChallenge: true);
                    if (!mounted) return;
                    _startSensors(controller);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Status membership gagal diperiksa: $e')),
                    );
                  }
                },
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
              CosmicBadge(text: 'Ronde ${controller.currentRound + 1}/${controller.questions.length}', color: AppTheme.coolCyan),
            ],
          ),
          const SizedBox(height: 16),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: controller.timeLeft / (controller.isGameOver ? 10 : 15),
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
              fontWeight: FontWeight.bold
            )
          ),
          
          const SizedBox(height: 24),

          // Kotak Soal Kuis 
          CosmicCard(
            child: Column(
              children: [
                const Icon(Icons.format_quote_rounded, size: 48, color: AppTheme.coolCyan),
                const SizedBox(height: 12),
                Text(
                  question.funFact, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    height: 1.4
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tombol 2 Pilihan Jawaban 
          Expanded(
            child: Row(
              children: List.generate(question.options.length > 2 ? 2 : question.options.length, (index) {
                final option = question.options[index];
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

                if (_isAnswered && isSelected) {
                  buttonColor = AppTheme.coolCyan; 
                  textColor = Colors.white; 
                  borderColor = AppTheme.coolCyan;
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
                              side: BorderSide(color: borderColor, width: 2)
                            ),
                          ),
                          onPressed: _isAnswered ? null : () => _handleAnswer(index, option, controller),
                          child: Text(
                            option, 
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
                          ),
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
            child: Text(
              'Miring Kiri/Kanan: Geser • Anggukkan: Konfirmasi',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)
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
                      Text('${controller.correctCount}/${controller.questions.length}', style: const TextStyle(color: AppTheme.success, fontSize: 32, fontWeight: FontWeight.bold)),
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
                  setState(() => _memberChallenge = false);
                  controller.startGame(memberChallenge: false);
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