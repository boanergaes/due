import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const String _tokenKey = 'due_sanctum_token';

  final FlutterSecureStorage? _storage;
  final Map<String, String> _memoryFallback = {};

  TokenStorage({FlutterSecureStorage? storage, bool inMemoryOnly = false})
      : _storage = inMemoryOnly
            ? null
            : (storage ??
                const FlutterSecureStorage(
                  aOptions: AndroidOptions(encryptedSharedPreferences: true),
                  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
                ));

  /// Save personal access token
  Future<void> saveToken(String token) async {
    _memoryFallback[_tokenKey] = token;
    if (_storage != null) {
      try {
        await _storage.write(key: _tokenKey, value: token).timeout(const Duration(milliseconds: 500));
      } catch (_) {}
    }
  }

  /// Retrieve stored personal access token
  Future<String?> getToken() async {
    if (_storage == null) {
      return _memoryFallback[_tokenKey];
    }
    try {
      final val = await _storage.read(key: _tokenKey).timeout(const Duration(milliseconds: 500));
      return val ?? _memoryFallback[_tokenKey];
    } catch (_) {
      return _memoryFallback[_tokenKey];
    }
  }

  /// Delete personal access token (upon logout or 401 session expiry)
  Future<void> deleteToken() async {
    _memoryFallback.remove(_tokenKey);
    if (_storage != null) {
      try {
        await _storage.delete(key: _tokenKey).timeout(const Duration(milliseconds: 500));
      } catch (_) {}
    }
  }

  /// Check whether a token exists
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
