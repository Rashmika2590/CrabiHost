import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final _client = ApiClient.instance;
  final _storage = SecureStorageService.instance;

  /// Login with email + password
  /// 1. POST /user/auth-token
  /// 2. Extract token / custom_token
  /// 3. Sign in to Firebase with custom token if available
  /// 4. Store token in SecureStorage
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/user/auth-token',
      data: {'email': email, 'password': password},
    );

    String? rawToken;
    String? customToken;

    if (data is Map) {
      if (data['data'] is Map) {
        customToken = data['data']['custom_token']?.toString() ??
            data['data']['token']?.toString();
      }
      customToken ??= data['custom_token']?.toString();
      rawToken = customToken ??
          data['access_token']?.toString() ??
          data['token']?.toString() ??
          data['auth_token']?.toString();
    } else if (data is String) {
      rawToken = data;
    }

    if (rawToken == null || rawToken.isEmpty) {
      throw AppException('Login failed: no valid authentication token returned.');
    }

    String authToken = rawToken;

    // Exchange custom_token with Firebase Auth if present
    if (customToken != null && customToken.isNotEmpty) {
      try {
        final userCredential =
            await FirebaseAuth.instance.signInWithCustomToken(customToken);
        final firebaseIdToken = await userCredential.user?.getIdToken();
        if (firebaseIdToken != null && firebaseIdToken.isNotEmpty) {
          authToken = firebaseIdToken;
        }
      } catch (e) {
        debugPrint('[Auth] Firebase signInWithCustomToken warning: $e');
      }
    }

    await _storage.saveToken(authToken);
    return authToken;
  }

  /// Fetch the current user's profile
  Future<UserModel> getProfile() async {
    final data = await _client.get('/user/');
    if (data is Map<String, dynamic>) {
      final user = UserModel.fromJson(data);
      await _storage.saveUserInfo(
        userId: user.uid,
        email: user.email ?? '',
        name: user.fullName,
      );
      return user;
    }
    throw AppException('Failed to load user profile.');
  }

  /// Validate current stored token
  Future<bool> validateToken() async {
    try {
      await _client.get('/user/auth-token/validate');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Trigger password reset email via Firebase / API
  Future<void> forgotPassword(String email) async {
    await _client.post(
      '/user/forgot-password',
      data: {'email': email},
    );
  }

  /// Clear token + user data from secure storage and Firebase
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await _storage.clearAll();
  }
}
