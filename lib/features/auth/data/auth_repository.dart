import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  /// Login with Google Sign-In
  Future<String> loginWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw AppException('Google sign-in was cancelled by the user.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user == null) {
      throw AppException('Failed to sign in with Google.');
    }

    final String? idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw AppException('Failed to retrieve authentication token.');
    }

    // Attempt backend registration/sync if supported
    try {
      final response = await _client.post(
        '/user/auth-token',
        data: {
          'provider': 'google',
          'id_token': idToken,
          'email': user.email,
          'name': user.displayName,
        },
      );
      if (response is Map) {
        final token = response['access_token']?.toString() ??
            response['token']?.toString() ??
            idToken;
        await _storage.saveToken(token);
        return token;
      }
    } catch (e) {
      debugPrint('[Auth] Backend Google sign-in note: $e');
    }

    await _storage.saveToken(idToken);
    await _storage.saveUserInfo(
      userId: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
    );
    return idToken;
  }

  /// Fetch the current user's profile
  Future<UserModel> getProfile() async {
    final data = await _client.get('/user/');
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final user = UserModel.fromJson(map);
      await _storage.saveUserInfo(
        userId: user.uid,
        email: user.email ?? '',
        name: user.fullName,
      );
      return user;
    }
    throw AppException('Failed to load user profile.');
  }

  /// Register or sync device token with AWS backend endpoint
  Future<void> registerDeviceToken(String token) async {
    try {
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : 'web';

      final payload = {
        'device_token': token,
        'token': token,
        'fcm_token': token,
        'platform': platform,
        'device_type': platform,
      };

      try {
        await _client.post('/user/device-token', data: payload);
        debugPrint('[AuthRepository] FCM device token registered on /user/device-token');
      } catch (e) {
        debugPrint('[AuthRepository] /user/device-token endpoint attempt: $e');
        // Fallback to /user/fcm-token
        try {
          await _client.post('/user/fcm-token', data: payload);
          debugPrint('[AuthRepository] FCM device token registered on /user/fcm-token');
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[AuthRepository] registerDeviceToken notice: $e');
    }
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
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await _storage.clearAll();
  }
}
