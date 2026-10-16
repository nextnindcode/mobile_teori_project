import 'package:eclipseverse/core/api_service.dart';

class FeedbackService {
  static Future<void> submit({
    required int rating,
    required String impression,
    required String suggestion,
  }) async {
    await ApiService.post('/feedback', {
      'rating': rating,
      'impression': impression,
      'suggestion': suggestion,
    });
  }
}
