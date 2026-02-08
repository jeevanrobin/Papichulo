import 'package:flutter/material.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  bool _isCartOpen = false;
  final CartService cartService;

  CartProvider({CartService? cartService}) : cartService = cartService ?? CartService();

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
}
