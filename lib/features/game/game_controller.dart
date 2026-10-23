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
  int _bestScore = 0; 
  Timer? _timer;

  List<GameQuestion> get questions => _questions;
  int get currentRound => _currentRound;
  int get score => _score;
  int get timeLeft => _timeLeft;
  int get bestScore => _bestScore; 
  int get correctCount => _correctCount; 
  bool get isGameOver => _currentRound >= 10;
  String? get loadError => _loadError;
  GameQuestion get currentQuestion => _questions[_currentRound];

  Future<void> startGame({bool memberChallenge = false}) async {
    _timer?.cancel();
    _loadError = null;
    _questions.clear();
    _answers.clear();
    notifyListeners();
    try {
      _bestScore = await GameService.getBestScore();
      final rows = await GameService.fetchQuestions();
      _questions.addAll(rows.map((row) {
        final options = Map<String, dynamic>.from(row['options'] as Map);
        final labels = options.entries.map((entry) => '${entry.key}. ${entry.value}').toList()..shuffle();
        return GameQuestion(
          id: (row['id'] as num).toInt(),
          funFact: '${row['question_text']}',
          options: labels,
        );
      }));
      _roundDuration = memberChallenge ? 10 : 15;
      _currentRound = 0;
      _score = 0;
      _correctCount = 0;
      _startTimer();
      notifyListeners();
    } catch (e) {
      _loadError = 'Soal belum dapat dimuat dari Supabase. Periksa migrasi dan data seed. $e';
      _questions.clear();
      notifyListeners();
    }
  }

  void _generateQuestions() {
    // Soal diambil dari quiz_questions_public; kunci jawaban hanya berada di database.
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
        nextRound();
      }
    });
  }

  void answerQuestion(String selectedAnswer) {
    _timer?.cancel();
    final question = currentQuestion;
    final answerKey = selectedAnswer.split('.').first.trim();
    _answers[question.id] = answerKey;
    nextRound();
  }

  void nextRound() async {
    if (_currentRound < _questions.length - 1) {
      _currentRound++;
      _startTimer();
      return;
    }

    _currentRound++;
    _timer?.cancel();
    try {
      final answers = _questions.map((question) => {
        'question_id': question.id,
        'answer': _answers[question.id] ?? '',
      }).toList();
      final result = await GameService.submitAnswers(answers);
      _score = (result['score'] as num?)?.toInt() ?? 0;
      _correctCount = (result['correct_count'] as num?)?.toInt() ?? 0;
      if (_score > _bestScore) {
        _bestScore = _score;
        await GameService.saveBestScore(_bestScore);
      }
      _loadError = null;
    } catch (e) {
      _loadError = 'Skor belum dapat diverifikasi oleh Supabase: $e';
      GameService.logFailure(e);
      // Do not award local points when server verification fails.
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}