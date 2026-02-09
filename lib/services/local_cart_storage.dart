import 'local_cart_storage_stub.dart'
    if (dart.library.html) 'local_cart_storage_web.dart' as impl;

class LocalCartStorage {
  Future<void> saveCart(String value) => impl.saveCart(value);
  Future<String?> readCart() => impl.readCart();
  Future<void> clearCart() => impl.clearCart();
}
