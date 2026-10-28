import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OfflineProfile {
  const OfflineProfile({
    required this.userId,
    required this.name,
    required this.email,
  });

  final String userId;
  final String name;
  final String email;
}

class OfflineAuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _saltKey = 'offline_auth_salt';
  static const String _hashKey = 'offline_auth_hash';
  static const String _emailKey = 'offline_auth_email';
  static const String _userIdKey = 'offline_auth_user_id';
  static const String _nameKey = 'offline_auth_name';
  static const String _profileEmailKey = 'offline_auth_profile_email';
  static const int _iterations = 60000;

  static Future<void> saveCredentials({
    required String email,
    required String password,
    required String userId,
    required String name,
    required String profileEmail,
  }) async {
    final saltBytes = List<int>.generate(
      16,
      (_) => Random.secure().nextInt(256),
    );
    final salt = base64UrlEncode(saltBytes);
    final passwordHash = await compute(
      _deriveKey,
      <String, Object>{
        'password': password,
        'salt': salt,
        'iterations': _iterations,
      },
    );

    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _hashKey, value: passwordHash);
    await _storage.write(key: _emailKey, value: email.trim().toLowerCase());
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _nameKey, value: name);
    await _storage.write(key: _profileEmailKey, value: profileEmail);
  }

  static Future<OfflineProfile?> verify({
    required String email,
    required String password,
  }) async {
    final savedEmail = await _storage.read(key: _emailKey);
    final savedSalt = await _storage.read(key: _saltKey);
    final savedHash = await _storage.read(key: _hashKey);
    final userId = await _storage.read(key: _userIdKey);
    final name = await _storage.read(key: _nameKey);
    final profileEmail = await _storage.read(key: _profileEmailKey);

    if (savedEmail == null ||
        savedSalt == null ||
        savedHash == null ||
        userId == null ||
        name == null ||
        profileEmail == null ||
        savedEmail != email.trim().toLowerCase()) {
      return null;
    }

    final attemptedHash = await compute(
      _deriveKey,
      <String, Object>{
        'password': password,
        'salt': savedSalt,
        'iterations': _iterations,
      },
    );
    if (!_constantTimeEquals(attemptedHash, savedHash)) return null;

    return OfflineProfile(userId: userId, name: name, email: profileEmail);
  }

  static Future<void> clear() async {
    for (final key in <String>[
      _saltKey,
      _hashKey,
      _emailKey,
      _userIdKey,
      _nameKey,
      _profileEmailKey,
    ]) {
      await _storage.delete(key: key);
    }
  }

  static String _deriveKey(Map<String, Object> input) {
    final password = input['password']! as String;
    final salt = input['salt']! as String;
    final iterations = input['iterations']! as int;
    final hmac = Hmac(sha256, utf8.encode(password));
    final saltBytes = base64Url.decode(base64Url.normalize(salt));
    final block = <int>[...saltBytes, 0, 0, 0, 1];
    var value = hmac.convert(block).bytes;
    final result = List<int>.from(value);

    for (var round = 1; round < iterations; round++) {
      value = hmac.convert(value).bytes;
      for (var index = 0; index < result.length; index++) {
        result[index] ^= value[index];
      }
    }
    return base64UrlEncode(result);
  }

  static bool _constantTimeEquals(String first, String second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first.codeUnitAt(index) ^ second.codeUnitAt(index);
    }
    return difference == 0;
  }
}
