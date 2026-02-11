import 'local_auth_storage_stub.dart'
    if (dart.library.html) 'local_auth_storage_web.dart' as impl;

class LocalAuthStorage {
  Future<void> saveAuth(String value) => impl.saveAuth(value);
  Future<String?> readAuth() => impl.readAuth();
  Future<void> clearAuth() => impl.clearAuth();
}

