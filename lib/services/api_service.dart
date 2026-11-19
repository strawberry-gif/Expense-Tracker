import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import 'auth_service.dart';

class ApiResult {
  final bool ok;
  final int statusCode;
  final Map<String, dynamic>? body;
  final String? error;

  ApiResult({
    required this.ok,
    required this.statusCode,
    this.body,
    this.error,
  });
}

class ApiService {
  ApiService._();

  static const Duration _timeout = Duration(seconds: 10);
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'auth_token';

  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  static Uri _uri(String path) {
    final normalizedBase = AppConstants.apiBaseUrl.trim();
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  static bool _isAuthPath(String path) {
    return path.contains('/api/auth/');
  }

  static Future<Map<String, String>> _headers({
    bool withJson = false,
    bool withAuth = true,
  }) async {
    final headers = <String, String>{};
    if (withJson) headers['Content-Type'] = 'application/json';
    if (withAuth) {
      final token = await _storage.read(key: _keyToken);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<ApiResult> get(String path, {bool auth = true}) {
    return _sendWithRetry(
      path: path,
      withAuth: auth,
      buildRequest: (headers) =>
          http.get(_uri(path), headers: headers).timeout(_timeout),
    );
  }

  static Future<ApiResult> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) {
    return _sendWithRetry(
      path: path,
      withJson: true,
      withAuth: auth,
      buildRequest: (headers) => http
          .post(_uri(path), headers: headers, body: jsonEncode(body))
          .timeout(_timeout),
    );
  }

  static Future<ApiResult> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) {
    return _sendWithRetry(
      path: path,
      withJson: true,
      withAuth: auth,
      buildRequest: (headers) => http
          .put(_uri(path), headers: headers, body: jsonEncode(body))
          .timeout(_timeout),
    );
  }

  static Future<ApiResult> delete(String path, {bool auth = true}) {
    return _sendWithRetry(
      path: path,
      withAuth: auth,
      buildRequest: (headers) =>
          http.delete(_uri(path), headers: headers).timeout(_timeout),
    );
  }

  static Future<ApiResult> _sendWithRetry({
    required String path,
    required Future<http.Response> Function(Map<String, String> headers)
        buildRequest,
    bool withJson = false,
    bool withAuth = true,
  }) async {
    int retries = 0;
    bool refreshed = false;
    ApiResult? last;

    while (true) {
      final headers = await _headers(withJson: withJson, withAuth: withAuth);
      last = await _send(() => buildRequest(headers));

      if (last.ok) return last;

      if (last.statusCode == 401 &&
          withAuth &&
          !refreshed &&
          !_isAuthPath(path)) {
        refreshed = true;
        final token = await AuthService.refreshToken();
        if (token != null) {
          continue;
        }
      }

      if (last.statusCode >= 400 && last.statusCode < 500) {
        return last;
      }

      retries++;
      if (retries <= _maxRetries) {
        await Future.delayed(_retryDelay * retries);
        continue;
      }

      return last;
    }
  }

  static Future<ApiResult> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request();
      final code = response.statusCode;

      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {}

      final ok = code >= 200 && code < 300;
      return ApiResult(
        ok: ok,
        statusCode: code,
        body: body,
        error: ok ? null : (body?['message'] ?? 'Request failed ($code)'),
      );
    } on http.ClientException {
      return ApiResult(
        ok: false,
        statusCode: 0,
        error: 'Cannot reach server.',
      );
    } on TimeoutException {
      return ApiResult(ok: false, statusCode: 0, error: 'Request timeout');
    } catch (e) {
      return ApiResult(ok: false, statusCode: 0, error: e.toString());
    }
  }
}