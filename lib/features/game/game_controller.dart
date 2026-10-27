import 'dart:async';
import 'package:flutter/material.dart';
import 'game_model.dart';
import 'game_service.dart';

class GameController extends ChangeNotifier {
  final List<GameQuestion> _questions = [];
  int _currentRound = 0;
  int _score = 0;
  int _correctCount = 0;
  int _timeLeft = 15;
  int _roundDuration = 15;
  String? _loadError;
  final Map<int, String> _answers = {};
  bool _memberChallenge = false;
  int _bestScore = 0;
  bool _isSubmitting = false;

  // Mencegah /10 -> /20 dan poin hilang 
  int _session = 0;
  bool _isTransitioning = false;

  Timer? _timer;

  List<GameQuestion> get questions => _questions;
  int get currentRound => _currentRound;
  int get score => _score;
  int get timeLeft => _timeLeft;
  int get roundDuration => _roundDuration;
  int get bestScore => _bestScore;
  int get correctCount => _correctCount;
  bool get isGameOver => _currentRound >= _questions.length;
  bool get isMemberMode => _memberChallenge;
  String? get loadError => _loadError;
  bool get isSubmitting => _isSubmitting;
  GameQuestion get currentQuestion => _questions[_currentRound];

  // Jawaban benar soal aktif ('A'/'B')
  // Null = tidak tersedia 
  String? get currentCorrectAnswer {
    if (_questions.isEmpty || _currentRound >= _questions.length) return null;
    return _questions[_currentRound].correctAnswer;
  }

  Future<void> startGame({bool memberChallenge = false}) async {
    final session = ++_session;
    _timer?.cancel();
    _loadError = null;
    _questions.clear();
    _answers.clear();
    _currentRound = 0;
    _score = 0;
    _correctCount = 0;
    _isSubmitting = false;
    _isTransitioning = false;
    notifyListeners();

    try {
      final bestScore = await GameService.getBestScore();
      final rows = await GameService.fetchQuestions();
      if (session != _session) return; 

      final parsed = rows.map((row) {
        final options = Map<String, dynamic>.from(row['options'] as Map);
        final labels = options.entries
            .map((entry) => '${entry.key}. ${entry.value}')
            .toList();
        return GameQuestion(
          id: (row['id'] as num).toInt(),
          funFact: '${row['question_text']}',
          options: labels,
          correctAnswer: row['correct_option']?.toString(),  
        );
      }).toList();

      final seenIds = <int>{};
      final unique = <GameQuestion>[];
      for (final q in parsed) {
        if (seenIds.add(q.id)) unique.add(q);
      }

      _questions.addAll(unique);
      _bestScore = bestScore;
      _memberChallenge = memberChallenge;
      _roundDuration = 15; 
      _startTimer();
      notifyListeners();
    } catch (e) {
      if (session != _session) return;
      _bestScore = 0;
      _loadError = 'Soal belum dapat dimuat. Periksa koneksi internet. $e';
      _questions.clear();
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _roundDuration;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _answers[currentQuestion.id] = '';
        _goToNextRound();
      }
    });
  }

  // Hentikan timer tanpa memajukan ronde — dipanggil saat user menjawab
  // Supaya timer tidak auto-advance saat UI menampilkan feedback benar/salah
  void pauseTimer() {
    _timer?.cancel();
  }

  // Rekam jawaban user lalu maju ke ronde berikutnya
  Future<void> answerQuestion(String selectedAnswer) async {
    if (_isTransitioning) return;
    _timer?.cancel();
    final question = currentQuestion;
    final answerKey = selectedAnswer.split('.').first.trim();
    _answers[question.id] = answerKey;
    await _goToNextRound();
  }

  Future<void> _goToNextRound() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    if (_currentRound < _questions.length - 1) {
      _currentRound++;
      _isTransitioning = false;
      _startTimer();
      return;
    }

    // Ronde terakhir — submit ke server
    _currentRound++;
    _timer?.cancel();
    _isSubmitting = true;
    notifyListeners();

    try {
      final answers = _questions
          .map((q) => {
                'question_id': q.id,
                'answer': _answers[q.id] ?? '',
              })
          .toList();
      final result = await GameService.submitAnswers(
        answers,
        memberChallenge: _memberChallenge,
      );
      _score = (result['score'] as num?)?.toInt() ?? 0;
      _correctCount = (result['correct_count'] as num?)?.toInt() ?? 0;
      if (_score > _bestScore) {
        _bestScore = _score;
        await GameService.saveBestScore(_bestScore);
      }
      _loadError = null;
    } catch (e) {
      _loadError = 'Skor belum dapat diverifikasi oleh server: $e';
      GameService.logFailure(e);
    } finally {
      _isSubmitting = false;
      _isTransitioning = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _session++;
    _timer?.cancel();
    super.dispose();
  }
} 