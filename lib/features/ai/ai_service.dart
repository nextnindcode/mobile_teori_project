import '../../core/api_service.dart';

class AiService {
  // Mengirim pesan ke endpoint/ai/chat
  static Future<String> kirimPesan(String pesan) async {
    try {
      // Memakai ApiService.post 
      final response = await ApiService.post('/ai/chat', {
        'message': pesan,
      });
      
      // Response API dibungkus dalam key `data` oleh Response::success.
      final payload = response['data'];
      if (payload is Map && payload['reply'] is String) {
        return (payload['reply'] as String).trim();
      }
      // Fallback untuk kompatibilitas jika server mengirim format lama.
      return response['reply']?.toString() ??
          'Maaf, AI tidak memberikan jawaban.';
      
    } on ApiException catch (e) {
      // Lempar error agar ditangkap oleh UI
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal menghubungi server. Periksa koneksi internet anda!.');
    }
  }
}