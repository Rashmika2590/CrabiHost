import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys
  static const _keyAuthToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserName = 'user_name';

  // --- Token ---
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _keyAuthToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyAuthToken);
  }

  // --- User info ---
  Future<void> saveUserInfo({
    required String userId,
    required String email,
    String? name,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserEmail, value: email);
    if (name != null) {
      await _storage.write(key: _keyUserName, value: name);
    }
  }

  Future<String?> getUserId() => _storage.read(key: _keyUserId);
  Future<String?> getUserEmail() => _storage.read(key: _keyUserEmail);
  Future<String?> getUserName() => _storage.read(key: _keyUserName);

  // --- Clear all ---
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
