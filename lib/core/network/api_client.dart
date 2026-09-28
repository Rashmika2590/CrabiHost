import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  final http.Client _client = http.Client();
  final _storage = SecureStorageService.instance;

  // Callback to trigger logout when a 401 is received
  VoidCallback? onUnauthorized;

  void init() {
    debugPrint('[ApiClient] Native HTTP client initialized with base: ${AppConfig.apiBaseUrl}');
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final baseUrl = AppConfig.apiBaseUrl.trim();
    final sanitizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final sanitizedPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$sanitizedBase$sanitizedPath';

    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = <String, String>{};
      queryParameters.forEach((key, value) {
        if (value != null) {
          stringParams[key] = value.toString();
        }
      });
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...stringParams,
      });
    }
    return uri;
  }

  Future<Map<String, String>> _getHeaders({Map<String, String>? extraHeaders}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // 1. Try fresh Firebase Auth ID token first (force refresh for valid JWT)
    String? token;
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          token = await user.getIdToken(true); // force refresh to get valid JWT
        }
      }
    } catch (e) {
      debugPrint('[ApiClient] Firebase token refresh notice: $e');
    }

    // 2. Fallback to SecureStorage stored token
    token ??= await _storage.getToken();

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        body = response.body;
      }
    }

    if (kDebugMode) {
      debugPrint('[HTTP] [${response.statusCode}] ${response.request?.url}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw AppException(
        _extractErrorMessage(body, 'Session expired. Please log in again.'),
        statusCode: 401,
      );
    }

    throw AppException(
      _extractErrorMessage(body, 'Request failed with status: ${response.statusCode}'),
      statusCode: response.statusCode,
    );
  }

  String _extractErrorMessage(dynamic body, String fallback) {
    if (body is Map) {
      if (body['detail'] != null) {
        final detail = body['detail'];
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
        }
        return detail.toString();
      }
      if (body['message'] != null) {
        return body['message'].toString();
      }
      if (body['error'] != null) {
        return body['error'].toString();
      }
    }
    if (body is String && body.isNotEmpty) {
      return body;
    }
    return fallback;
  }

  // ── HTTP Methods ────────────────────────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final requestHeaders = await _getHeaders(extraHeaders: headers);
      final response = await _client
          .get(uri, headers: requestHeaders)
          .timeout(AppConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException catch (_) {
      throw AppException('No internet connection. Please check your network.', statusCode: 503);
    } on TimeoutException catch (_) {
      throw AppException('Connection timed out. Please try again.', statusCode: 408);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('An unexpected error occurred: $e');
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final requestHeaders = await _getHeaders(extraHeaders: headers);
      final body = data is String ? data : (data != null ? jsonEncode(data) : null);
      final response = await _client
          .post(uri, headers: requestHeaders, body: body)
          .timeout(AppConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException catch (_) {
      throw AppException('No internet connection. Please check your network.', statusCode: 503);
    } on TimeoutException catch (_) {
      throw AppException('Connection timed out. Please try again.', statusCode: 408);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('An unexpected error occurred: $e');
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final requestHeaders = await _getHeaders(extraHeaders: headers);
      final body = data is String ? data : (data != null ? jsonEncode(data) : null);
      final response = await _client
          .put(uri, headers: requestHeaders, body: body)
          .timeout(AppConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException catch (_) {
      throw AppException('No internet connection. Please check your network.', statusCode: 503);
    } on TimeoutException catch (_) {
      throw AppException('Connection timed out. Please try again.', statusCode: 408);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('An unexpected error occurred: $e');
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final requestHeaders = await _getHeaders(extraHeaders: headers);
      final body = data is String ? data : (data != null ? jsonEncode(data) : null);
      final response = await _client
          .patch(uri, headers: requestHeaders, body: body)
          .timeout(AppConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException catch (_) {
      throw AppException('No internet connection. Please check your network.', statusCode: 503);
    } on TimeoutException catch (_) {
      throw AppException('Connection timed out. Please try again.', statusCode: 408);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('An unexpected error occurred: $e');
    }
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final requestHeaders = await _getHeaders(extraHeaders: headers);
      final response = await _client
          .delete(uri, headers: requestHeaders)
          .timeout(AppConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException catch (_) {
      throw AppException('No internet connection. Please check your network.', statusCode: 503);
    } on TimeoutException catch (_) {
      throw AppException('Connection timed out. Please try again.', statusCode: 408);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('An unexpected error occurred: $e');
    }
  }
}
