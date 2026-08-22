import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction over secure token persistence.
///
/// Allows swapping the real [FlutterSecureStorage] implementation for a
/// test double without coupling business logic to a concrete class.
abstract class TokenStorage {
  /// Returns the persisted JWT access token, or `null` if absent.
  Future<String?> getAccessToken();

  /// Returns the persisted JWT refresh token, or `null` if absent.
  Future<String?> getRefreshToken();

  /// Persists both JWT tokens atomically.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Removes all stored tokens (logout / session expiry).
  Future<void> clearTokens();
}

/// Production implementation backed by [FlutterSecureStorage]
/// (Android Keystore / iOS Keychain).
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';

  @override
  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
