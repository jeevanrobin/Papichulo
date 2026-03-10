import 'dart:convert';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'api_config.dart';
import 'local_auth_storage.dart';

class AuthUser {
  final int id;
  final String name;
  final String? email;
  final String role;
  final String? phone;
  final DateTime? createdAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      role: (json['role'] ?? 'customer').toString(),
      phone: json['phone']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
    'createdAt': createdAt?.toIso8601String(),
  };
}

class AuthService extends ChangeNotifier {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  factory AuthService() => instance;

  final LocalAuthStorage _storage = LocalAuthStorage();
  final ApiClient _api = ApiClient();

  String? _token;
  AuthUser? _user;
  bool _loading = false;
  bool _bootstrapped = false;

  String? get authToken => _token;
  AuthUser? get user => _user;
  bool get isLoading => _loading;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isAdmin => (_user?.role.toLowerCase() ?? '') == 'admin';

  Map<String, String> _authHeaders() {
    if (_token == null || _token!.isEmpty) return const {};
    return {'Authorization': 'Bearer $_token'};
  }

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
      final response = await _api.get(
        '/me',
        headers: _authHeaders(),
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
      final response = await _api.post('/signup', {
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
    final response = await _api.post('/auth/send-otp', {
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
      final response = await _api.post('/auth/verify-otp', {
        'phone': normalizedPhone,
        'otp': normalizedOtp,
      });
      await _setSessionFromResponse(response.body);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Firebase Phone Auth flow: after Firebase verifies the OTP, call backend
  /// with the Firebase ID token so it can create/find the user and issue a JWT.
  Future<void> firebaseLogin({
    required String phone,
    required String firebaseIdToken,
  }) async {
    final normalizedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    _loading = true;
    notifyListeners();
    try {
      final response = await _api.post('/auth/firebase-login', {
        'phone': normalizedPhone,
        'firebaseIdToken': firebaseIdToken,
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
      final response = await _api.post('/login', {
        'email': email,
        'password': password,
      });
      await _setSessionFromResponse(response.body);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({required String name, String? email}) async {
    if (_token == null || _user == null) {
      throw Exception('Please login first.');
    }

    final normalizedName = name.trim();
    final normalizedEmail = (email ?? '').trim();

    final response = await _api.patch(
      '/me',
      {
        'name': normalizedName,
        'email': normalizedEmail.isEmpty ? null : normalizedEmail,
      },
      headers: _authHeaders(),
    );

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid profile update response');
    }

    _user = AuthUser.fromJson(decoded);
    await _persist();
    notifyListeners();
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
}
