import 'dart:async';
import 'package:flutter/material.dart';
import 'game_model.dart';
import 'game_service.dart'; 

class GameController extends ChangeNotifier {
  final List<Map<String, String>> _allMembers = [
    {'name': 'Solen', 'funFact': 'Menulis lagu debut Eclipse di kamar kos'},
    {'name': 'Lunar', 'funFact': 'Hafal 40 lagu tema film animasi'},
    {'name': 'Astra', 'funFact': 'Pernah menjadi penyiar radio kampus'},
    {'name': 'Orion', 'funFact': 'Juara kompetisi breakdance tingkat provinsi'},
    {'name': 'Vega', 'funFact': 'Koreografer pertama lagu "Penumbra"'},
    {'name': 'Nova', 'funFact': 'Bisa menari sambil memainkan yo-yo'},
    {'name': 'Zephyr', 'funFact': 'Menulis lirik rap dalam tiga bahasa'},
    {'name': 'Atlas', 'funFact': 'Kolektor sepatu edisi terbatas'},
    {'name': 'Lyra', 'funFact': 'Pernah menjadi juara lomba debat sekolah'},
    {'name': 'Cassio', 'funFact': 'Pernah menjadi model majalah sekolah'},
    {'name': 'Rigel', 'funFact': 'Membuat 10 beat dalam satu malam'},
    {'name': 'Altair', 'funFact': 'Bermain gitar sejak usia 7 tahun'},
    {'name': 'Mira', 'funFact': 'Anggota termuda yang hobi merakit puzzle 1000 keping'},
  ];

  final List<GameQuestion> _questions = [];
  int _currentRound = 0;
  int _score = 0;
  int _correctCount = 0;
  int _timeLeft = 15;
  int _bestScore = 0; 
  Timer? _timer;

  List<GameQuestion> get questions => _questions;
  int get currentRound => _currentRound;
  int get score => _score;
  int get timeLeft => _timeLeft;
  int get bestScore => _bestScore; 
  int get correctCount => _correctCount; 
  bool get isGameOver => _currentRound >= 10;
  GameQuestion get currentQuestion => _questions[_currentRound];

  void startGame() async {
    try {
      _bestScore = await GameService.getBestScore();
    } catch (e) {
      _bestScore = 0; 
      debugPrint('SQLite tidak didukung di Web, best score di-reset.');
    }
    
    _generateQuestions();
    _currentRound = 0;
    _score = 0;
    _correctCount = 0;
    _startTimer();
    notifyListeners();
  }

  void _generateQuestions() {
    _questions.clear();
    final shuffledMembers = List<Map<String, String>>.from(_allMembers)..shuffle();
    final selectedMembers = shuffledMembers.take(10).toList();

    for (var member in selectedMembers) {
      String correct = member['name']!;
      String fact = member['funFact']!;
      List<String> wrongOptions = _allMembers.where((m) => m['name'] != correct).map((m) => m['name']!).toList()..shuffle();
      
      // Hanya mengambil 1 jawaban salah (total ada 2 pilihan jawaban)
      List<String> options = [correct, ...wrongOptions.take(1)]..shuffle();

      _questions.add(GameQuestion(funFact: fact, options: options, correctAnswer: correct));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 15;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        _timer?.cancel();
        nextRound(isCorrect: false);
      }
    });
  }

  void answerQuestion(String selectedAnswer) {
    _timer?.cancel();
    bool isCorrect = selectedAnswer == currentQuestion.correctAnswer;
    nextRound(isCorrect: isCorrect);
  }

  void nextRound({required bool isCorrect}) async {
    if (isCorrect) {
      _score += 10;
      _correctCount++;
    }

    if (_currentRound < 9) {
      _currentRound++;
      _startTimer();
      return;
    }

    _currentRound++;

    if (_score > _bestScore) {
      _bestScore = _score;
      try {
        await GameService.saveBestScore(_bestScore);
      } catch (e) {
        debugPrint('Gagal menyimpan skor lokal: $e');
      }
    }

    // Kegagalan jaringan tidak boleh membuat layar hasil permainan menggantung.
    try {
      await GameService.kirimSkorKeServer(_score, _correctCount);
    } catch (e) {
      debugPrint('Gagal mengirim skor ke server: $e');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}