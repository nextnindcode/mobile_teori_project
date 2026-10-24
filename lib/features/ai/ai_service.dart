import 'package:supabase_flutter/supabase_flutter.dart';

class AiService {
  static final _client = Supabase.instance.client;

  static Future<String> kirimPesan(String pesan) async {
    final prompt = pesan.trim();
    if (prompt.isEmpty) throw Exception('Pesan tidak boleh kosong.');
    try {
      final response = await _client.functions
          .invoke('eclipse-ai', body: {'message': prompt})
          .timeout(const Duration(seconds: 28));
      if (response.status < 200 || response.status >= 300) {
        throw Exception('Eclipse AI belum dapat menjawab. Coba lagi nanti.');
      }
      final body = response.data;
      if (body is Map && body['reply'] is String) {
        return (body['reply'] as String).trim();
      }
      throw Exception('Format jawaban Eclipse AI tidak valid.');
    } on FunctionException catch (e) {
      throw Exception(e.details?.toString() ?? 'Eclipse AI sementara tidak tersedia.');
    } on AuthException {
      throw Exception('Sesi login tidak valid. Silakan login kembali.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Eclipse AI terlalu lama merespons. Coba lagi.');
      }
      rethrow;
    }
  }
}
