import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../data/menu_data.dart';
import '../models/cart_item.dart';
import '../models/food_item.dart';
import 'analytics_service.dart';
import 'local_cart_storage.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal() {
    _loadPersistedCart();
  }

  final List<CartItem> _items = [];
  final LocalCartStorage _storage = LocalCartStorage();

  List<CartItem> get items => List.unmodifiable(_items);
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalAmount => _items.fold(0, (sum, item) => sum + item.totalPrice);

  void addItem(FoodItem foodItem) {
    final existingIndex = _items.indexWhere((item) => item.foodItem.name == foodItem.name);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(foodItem: foodItem));
    }
    final quantity = _items.firstWhere((item) => item.foodItem.name == foodItem.name).quantity;
    AnalyticsService().track(
      'add_to_cart',
      params: {
        'item_name': foodItem.name,
        'category': foodItem.category,
        'price': foodItem.price,
        'quantity': quantity,
      },
    );
    _persistCart();
    notifyListeners();
  }

  void removeItem(FoodItem foodItem) {
    _items.removeWhere((item) => item.foodItem.name == foodItem.name);
    _persistCart();
    notifyListeners();
  }

  void updateQuantity(FoodItem foodItem, int quantity) {
    final existingIndex = _items.indexWhere((item) => item.foodItem.name == foodItem.name);
    
    if (existingIndex >= 0) {
      if (quantity <= 0) {
        _items.removeAt(existingIndex);
      } else {
        _items[existingIndex].quantity = quantity;
      }
      _persistCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _storage.clearCart();
    notifyListeners();
  }

  Future<void> _loadPersistedCart() async {
    final rawCart = await _storage.readCart();
    if (rawCart == null || rawCart.isEmpty) return;

    try {
      final decoded = jsonDecode(rawCart);
      if (decoded is! List) return;

      _items.clear();
      for (final entry in decoded) {
        if (entry is! Map) continue;

        final name = entry['name'];
        final quantity = entry['quantity'];
        if (name is! String || quantity is! int) continue;

        final food = papichuloMenu.cast<FoodItem?>().firstWhere(
              (item) => item?.name == name,
              orElse: () => null,
            );
        if (food == null) continue;

        _items.add(
          CartItem(
            foodItem: food,
            quantity: quantity <= 0 ? 1 : quantity,
          ),
        );
      }
      notifyListeners();
    } catch (_) {
      // Ignore invalid persisted payloads and continue with empty cart.
    }
  }

  Future<void> _persistCart() async {
    final payload = _items
        .map(
          (item) => {
            'name': item.foodItem.name,
            'quantity': item.quantity,
          },
        )
        .toList(growable: false);
    await _storage.saveCart(jsonEncode(payload));
  }
}
