class GameQuestion {
  final String funFact;
  final List<String> options;
  final String correctAnswer;

  GameQuestion({
    required this.funFact,
    required this.options,
    required this.correctAnswer,
  });
}

class GameResult {
  final int score;
  final int correctCount;

  GameResult({required this.score, required this.correctCount});
}