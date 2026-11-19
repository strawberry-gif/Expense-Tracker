import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../database/sqlite_database.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  AuthService._();

  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUser = 'auth_user_json';

  static Future<User> login(String email, String password) async {
    final result = await ApiService.post('/api/auth/login', {
      'email': email.trim(),
      'password': password,
    });

    if (!result.ok || result.body == null) {
      throw Exception(result.error ?? 'Login failed');
    }

    final data = result.body!['data'];
    if (data is! Map) throw Exception('Malformed login response');

    final token = data['token'] as String?;
    final refreshToken = data['refresh_token'] as String?;
    final userMap = data['user'];
    if (token == null || userMap is! Map) {
      throw Exception('Missing token or user in response');
    }

    final user = _parseUser(userMap);

    await _storage.write(key: _keyToken, value: token);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
    await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));

    await _activateUser(user);

    return user;
  }

  static Future<User> register(
    String name,
    String email,
    String password,
  ) async {
    final result = await ApiService.post('/api/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    });

    if (!result.ok || result.body == null) {
      throw Exception(result.error ?? 'Registration failed');
    }

    final data = result.body!['data'];
    if (data is! Map) throw Exception('Malformed register response');

    final token = data['token'] as String?;
    final refreshToken = data['refresh_token'] as String?;
    final userMap = data['user'];
    if (token == null || userMap is! Map) {
      throw Exception('Missing token or user in response');
    }

    final user = _parseUser(userMap);

    await _storage.write(key: _keyToken, value: token);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
    await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));

    await _activateUser(user);

    return user;
  }

  static Future<void> logout() async {
    try {
      await ApiService.post('/api/auth/logout', {});
    } catch (_) {}
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUser);
    SQLiteDatabase().clearActiveUser();
  }

  static Future<String?> refreshToken() async {
    try {
      final currentRefreshToken = await _storage.read(key: _keyRefreshToken);
      if (currentRefreshToken == null) return null;

      final result = await ApiService.post(
        '/api/auth/refresh',
        {'refresh_token': currentRefreshToken},
        auth: false,
      );

      if (!result.ok || result.body == null) return null;

      final data = result.body!['data'];
      if (data is! Map) return null;

      final newToken = data['token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;

      if (newToken != null) {
        await _storage.write(key: _keyToken, value: newToken);
        if (newRefreshToken != null) {
          await _storage.write(key: _keyRefreshToken, value: newRefreshToken);
        }
        return newToken;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _keyToken);
  }

  static Future<User?> getStoredUser() async {
    final raw = await _storage.read(key: _keyUser);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _parseUser(map);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasSession() async {
    final token = await _storage.read(key: _keyToken);
    if (token == null || token.isEmpty) return false;

    final user = await getStoredUser();
    if (user != null) {
      await _activateUser(user);
    }
    return true;
  }

  static Future<bool> verifyOnline() async {
    final result = await ApiService.get('/api/auth/me');
    return result.ok;
  }

  static Future<void> _activateUser(User user) async {
    final db = SQLiteDatabase();
    final uid = user.id.toString();
    db.setActiveUser(uid);
    try {
      await db.claimLocalUserData(uid);
    } catch (_) {}
  }

  static User _parseUser(Map raw) {
    final map = Map<String, dynamic>.from(raw);
    final idRaw = map['id'];
    if (idRaw is String) {
      final parsed = int.tryParse(idRaw);
      if (parsed == null) {
        throw Exception('User id is not numeric: $idRaw');
      }
      map['id'] = parsed;
    } else if (idRaw is! int) {
      throw Exception('Missing or invalid user id');
    }
    return User.fromJson(map);
  }
}