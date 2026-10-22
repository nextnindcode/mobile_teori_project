import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'constants.dart';
import 'secure_store.dart';

class ApiService {
  static const _timeout = Duration(seconds: 30);

  static Uri _buildUri(String endpoint, [Map<String, dynamic>? query]) {
    final base = Constants.baseUrl.endsWith('/')
        ? Constants.baseUrl.substring(0, Constants.baseUrl.length - 1)
        : Constants.baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    var uri = Uri.parse('$base$path');
    if (query != null && query.isNotEmpty) {
      final stringParams = query.map((k, v) => MapEntry(k, v.toString()));
      uri = uri.replace(
        queryParameters: {...uri.queryParameters, ...stringParams},
      );
    }
    return uri;
  }

  // ===== GET =====
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final token = await SecureStore.getToken();
      final uri = _buildUri(endpoint, query);
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        'Tidak dapat terhubung ke server. Periksa jaringan atau URL API (${e.message}).',
        'NETWORK_ERROR',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Koneksi ke server gagal: ${e.message}',
        'CLIENT_ERROR',
      );
    }
  }

  // ===== POST =====
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await SecureStore.getToken();
      final uri = _buildUri(endpoint);
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        'Tidak dapat terhubung ke server. Periksa jaringan atau URL API (${e.message}).',
        'NETWORK_ERROR',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Koneksi ke server gagal: ${e.message}',
        'CLIENT_ERROR',
      );
    }
  }

  // ===== PUT =====
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await SecureStore.getToken();
      final uri = _buildUri(endpoint);
      final response = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        'Tidak dapat terhubung ke server. Periksa jaringan atau URL API (${e.message}).',
        'NETWORK_ERROR',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Koneksi ke server gagal: ${e.message}',
        'CLIENT_ERROR',
      );
    }
  }

  // ===== DELETE =====
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final token = await SecureStore.getToken();
      final uri = _buildUri(endpoint);
      final response = await http
          .delete(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        'Tidak dapat terhubung ke server. Periksa jaringan atau URL API (${e.message}).',
        'NETWORK_ERROR',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        'Koneksi ke server gagal: ${e.message}',
        'CLIENT_ERROR',
      );
    }
  }

  // ===== HANDLE RESPONSE =====
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else {
        data = {'data': decoded, 'success': response.statusCode >= 200 && response.statusCode < 300};
      }
    } catch (_) {
      throw ApiException(
        'Server tidak merespons dengan JSON valid (HTTP ${response.statusCode})',
        'BAD_RESPONSE',
      );
    }

    // 401 Unauthorized -> token expired -> hapus token
    if (response.statusCode == 401) {
      SecureStore.deleteToken();
      throw ApiException(
        data['message']?.toString() ?? 'Sesi berakhir, silakan login ulang',
        data['code']?.toString() ?? 'TOKEN_EXPIRED',
      );
    }

    // Status bukan 2xx -> throw error
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['message']?.toString() ?? 'Terjadi kesalahan pada server (HTTP ${response.statusCode})',
        data['code']?.toString() ?? 'ERROR',
      );
    }

    return data;
  }
}

// ===== EXCEPTION =====
class ApiException implements Exception {
  final String message;
  final String code;

  ApiException(this.message, [this.code = 'ERROR']);

  @override
  String toString() => message;
}
