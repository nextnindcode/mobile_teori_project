class GameQuestion {
  final int id;
  final String funFact;
  final List<String> options;
  final String? correctAnswer;
  final String explanation;

  const GameQuestion({
    required this.id,
    required this.funFact,
    required this.options,
    this.correctAnswer,
    this.explanation = '',
  });
}

class GameResult {
  final int score;
  final int correctCount;
  final int pointsEarned;
  const GameResult({
    required this.score,
    required this.correctCount,
    required this.pointsEarned,
  });
} 