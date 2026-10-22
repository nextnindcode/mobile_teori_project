import 'package:eclipseverse/core/api_service.dart';
import '../fandom/shared/json_utils.dart';

class FeedbackService {
  static Future<List<Map<String, dynamic>>> fetchReviews() async {
    final response = await ApiService.get('/feedback');
    return asList(response['data']);
  }

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
