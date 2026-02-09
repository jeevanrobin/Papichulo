import 'dart:html' as html;

const _cartStorageKey = 'papichulo_cart_v1';

Future<void> saveCart(String value) async {
  html.window.localStorage[_cartStorageKey] = value;
}

Future<String?> readCart() async {
  return html.window.localStorage[_cartStorageKey];
}

Future<void> clearCart() async {
  html.window.localStorage.remove(_cartStorageKey);
}
