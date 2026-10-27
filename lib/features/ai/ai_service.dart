import 'package:supabase_flutter/supabase_flutter.dart';

class AiService {
  static final _client = Supabase.instance.client;

  static Future<String> kirimPesan(String pesan) async {
    final prompt = pesan.trim();
    if (prompt.isEmpty) throw Exception('Pesan tidak boleh kosong.');
    try {
      final context = await _buildKnowledgeContext();
      final contextualPrompt = context.isEmpty
          ? prompt
          : 'KONTEKS DATA APLIKASI (gunakan sebagai sumber utama; jangan mengarang stok/harga):\n$context\n\nPERTANYAAN PENGGUNA: $prompt';
      final response = await _client.functions
          .invoke('eclipse-ai', body: {'message': contextualPrompt})
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

  static Future<String> _buildKnowledgeContext() async {
    final sections = <String>[];
    try {
      final products = await _client
          .from('products')
          .select('name,description,price_idr,stock,categories(name)')
          .eq('is_published', true)
          .limit(30)
          .timeout(const Duration(seconds: 5));
      final lines = products.map((raw) {
        final row = Map<String, dynamic>.from(raw);
        final category = row['categories'] is Map
            ? (row['categories']['name']?.toString() ?? 'Merchandise')
            : 'Merchandise';
        return '- ${row['name']}; kategori: $category; harga: Rp${row['price_idr'] ?? 'tidak tersedia'}; stok: ${row['stock'] ?? 'tidak tersedia'}; deskripsi: ${row['description'] ?? '-'}';
      }).join('\n');
      if (lines.isNotEmpty) sections.add('PRODUK YANG TERSEDIA:\n$lines');
    } catch (_) {}
    try {
      final members = await _client
          .from('members')
          .select('stage_name,position,team,description,fun_fact')
          .order('sort_order')
          .limit(30)
          .timeout(const Duration(seconds: 5));
      final lines = members.map((raw) {
        final row = Map<String, dynamic>.from(raw);
        return '- ${row['stage_name']}; posisi: ${row['position'] ?? '-'}; tim: ${row['team'] ?? '-'}; deskripsi: ${row['description'] ?? '-'}; fakta: ${row['fun_fact'] ?? '-'}';
      }).join('\n');
      if (lines.isNotEmpty) sections.add('DATA MEMBER ECLIPSE:\n$lines');
    } catch (_) {}
    return sections.join('\n\n');
  }
}
