import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'local_auth_storage.dart';

class AuthUser {
  final int id;
  final String name;
  final String? email;
  final String role;
  final String? phone;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      role: (json['role'] ?? 'customer').toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
  };
}

class AuthService extends ChangeNotifier {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  factory AuthService() => instance;

  final LocalAuthStorage _storage = LocalAuthStorage();
  final http.Client _client = http.Client();

  String? _token;
  AuthUser? _user;
  bool _loading = false;
  bool _bootstrapped = false;

  String? get authToken => _token;
  AuthUser? get user => _user;
  bool get isLoading => _loading;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isAdmin => (_user?.role.toLowerCase() ?? '') == 'admin';

  List<String> get _baseUrls => ApiConfig.candidateBaseUrls();

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    final raw = await _storage.readAuth();
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      _token = decoded['token']?.toString();
      final userJson = decoded['user'];
      if (_token != null && userJson is Map<String, dynamic>) {
        _user = AuthUser.fromJson(userJson);
        notifyListeners();
      } else {
        await logout(silent: true);
        return;
      }
      await refreshMe(silent: true);
    } catch (_) {
      await logout(silent: true);
    }
  }

  Future<void> refreshMe({bool silent = false}) async {
    if (_token == null) return;
    try {
      final response = await _getWithFallback(
        '/me',
        headers: {'Authorization': 'Bearer $_token'},
      );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw Exception('Invalid /me');
      _user = AuthUser.fromJson(decoded);
      await _persist();
      notifyListeners();
    } catch (_) {
      if (!silent) rethrow;
      await logout(silent: true);
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final response = await _postWithFallback('/signup', {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      });
      await _setSessionFromResponse(response.body);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> sendOtp({required String phone}) async {
    final normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.length != 10) {
      throw Exception('Enter a valid 10-digit mobile number');
    }
    final response = await _postWithFallback('/auth/send-otp', {
      'phone': normalized,
    });
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid send OTP response');
    }
    return decoded;
  }

  Future<void> verifyOtp({required String phone, required String otp}) async {
    final normalizedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final normalizedOtp = otp.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalizedPhone.length != 10 || normalizedOtp.length != 6) {
      throw Exception('Invalid phone or OTP');
    }
    _loading = true;
    notifyListeners();
    try {
      final response = await _postWithFallback('/auth/verify-otp', {
        'phone': normalizedPhone,
        'otp': normalizedOtp,
      });
      await _setSessionFromResponse(response.body);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _loading = true;
    notifyListeners();
    try {
      final response = await _postWithFallback('/login', {
        'email': email,
        'password': password,
      });
      await _setSessionFromResponse(response.body);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout({bool silent = false}) async {
    _token = null;
    _user = null;
    await _storage.clearAuth();
    if (!silent) notifyListeners();
  }

  Future<void> _setSessionFromResponse(String body) async {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid auth response');
    }
    final token = decoded['token']?.toString();
    final userJson = decoded['user'];
    if (token == null || userJson is! Map<String, dynamic>) {
      throw Exception('Invalid auth response payload');
    }
    _token = token;
    _user = AuthUser.fromJson(userJson);
    await _persist();
  }

  Future<void> _persist() async {
    if (_token == null || _user == null) return;
    final payload = jsonEncode({'token': _token, 'user': _user!.toJson()});
    await _storage.saveAuth(payload);
  }

  Future<http.Response> _getWithFallback(
    String path, {
    Map<String, String>? headers,
  }) async {
    Exception? lastError;
    var hadNetworkError = false;
    var hadHttpResponse = false;
    for (final baseUrl in _baseUrls) {
      try {
        final response = await _client.get(
          Uri.parse('$baseUrl$path'),
          headers: headers,
        );
        hadHttpResponse = true;
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        lastError = Exception(_extractError(response, baseUrl, path));
      } catch (error) {
        hadNetworkError = true;
        lastError = Exception(error.toString());
      }
    }
    if (hadNetworkError && !hadHttpResponse) {
      throw Exception(
        'Unable to reach backend. Start backend and verify API URL. Tried: ${_baseUrls.join(', ')}',
      );
    }
    throw lastError ?? Exception('Request failed ($path)');
  }

  Future<http.Response> _postWithFallback(String path, Object payload) async {
    Exception? lastError;
    var hadNetworkError = false;
    var hadHttpResponse = false;
    for (final baseUrl in _baseUrls) {
      try {
        final response = await _client.post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
        hadHttpResponse = true;
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        lastError = Exception(_extractError(response, baseUrl, path));
      } catch (error) {
        hadNetworkError = true;
        lastError = Exception(error.toString());
      }
    }
    if (hadNetworkError && !hadHttpResponse) {
      throw Exception(
        'Unable to reach backend. Start backend and verify API URL. Tried: ${_baseUrls.join(', ')}',
      );
    }
    throw lastError ?? Exception('Request failed ($path)');
  }

  String _extractError(http.Response response, String baseUrl, String path) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded['error'] is Map &&
          (decoded['error'] as Map)['message'] != null) {
        return '${(decoded['error'] as Map)['message']} [$baseUrl$path]';
      }
    } catch (_) {}
    return 'Request failed [$baseUrl$path] (${response.statusCode})';
  }
}
