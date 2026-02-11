import 'dart:html' as html;

const _authStorageKey = 'papichulo_auth_v1';

Future<void> saveAuth(String value) async {
  html.window.localStorage[_authStorageKey] = value;
}

Future<String?> readAuth() async {
  return html.window.localStorage[_authStorageKey];
}

Future<void> clearAuth() async {
  html.window.localStorage.remove(_authStorageKey);
}

