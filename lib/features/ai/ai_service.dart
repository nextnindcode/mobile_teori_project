import '../../core/api_service.dart';

class AiService {
  // Mengirim pesan ke endpoint/ai/chat
  static Future<String> kirimPesan(String pesan) async {
    try {
      // Memakai ApiService.post 
      final response = await ApiService.post('/ai/chat', {
        'message': pesan,
      });
      
      // Mengambil balasan 'reply' dari JSON
      return response['reply'] ?? 'Maaf, AI tidak memberikan jawaban.';
      
    } on ApiException catch (e) {
      // Lempar error agar ditangkap oleh UI
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal menghubungi server. Periksa koneksi internet anda!.');
    }
  }
}