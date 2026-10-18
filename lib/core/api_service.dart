import 'dart:convert';

import 'package:http/http.dart' as http;

import 'constants.dart';
import 'secure_store.dart';

class ApiService {
  static const _timeout = Duration(seconds: 30);

  // ===== GET =====
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? query,
  }) async {
    final token = await SecureStore.getToken();
    var uri = Uri.parse('${Constants.baseUrl}$endpoint');
    if (query != null && query.isNotEmpty) {
      final stringParams = query.map((k, v) => MapEntry(k, v.toString()));
      uri = uri.replace(
        queryParameters: {...uri.queryParameters, ...stringParams},
      );
    }
    final response = await http
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(_timeout);
    return _handleResponse(response);
  }

  // ===== POST =====
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await SecureStore.getToken();
    final response = await http
        .post(
          Uri.parse('${Constants.baseUrl}$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _handleResponse(response);
  }

  // ===== PUT =====
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await SecureStore.getToken();
    final response = await http
        .put(
          Uri.parse('${Constants.baseUrl}$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _handleResponse(response);
  }

  // ===== DELETE =====
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final token = await SecureStore.getToken();
    final response = await http
        .delete(
          Uri.parse('${Constants.baseUrl}$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(_timeout);
    return _handleResponse(response);
  }

  // ===== HANDLE RESPONSE =====
  static Map<String, dynamic> _handleResponse(http.Response response) {
    // Server mengirim HTML (hosting memblokir / salah alamat) -> pesan ramah, bukan crash.
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Server tidak merespons dengan benar', 'BAD_RESPONSE');
    }

    // Kalau 401 -> token expired -> hapus token
    if (response.statusCode == 401) {
      SecureStore.deleteToken();
      throw ApiException(
        data['message'] ?? 'Sesi berakhir',
        data['code'] ?? 'TOKEN_EXPIRED',
      );
    }

    // Kalau bukan 2xx -> throw error
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['message'] ?? 'Terjadi kesalahan',
        data['code'] ?? 'ERROR',
      );
    }

    return data;
  }
}

// ===== EXCEPTION =====
class ApiException implements Exception {
  final String message;
  final String code;

  ApiException(this.message, this.code);

  @override
  String toString() => message;
}
