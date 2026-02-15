import 'package:flutter/material.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  bool _isCartOpen = false;
  final CartService cartService;

  CartProvider({CartService? cartService})
      : cartService = cartService ?? CartService() {
    this.cartService.addListener(_onCartChanged);
  }

  void _onCartChanged() {
    // Forward cart item/quantity updates so widgets listening to CartProvider
    // (like header badge and drawer state) stay in sync.
    notifyListeners();
  }

  bool get isCartOpen => _isCartOpen;

  void toggleCart() {
    _isCartOpen = !_isCartOpen;
    notifyListeners();
  }

  void openCart() {
    _isCartOpen = true;
    notifyListeners();
  }

  void closeCart() {
    _isCartOpen = false;
    notifyListeners();
  }

  @override
  void dispose() {
    cartService.removeListener(_onCartChanged);
    super.dispose();
  }
}
