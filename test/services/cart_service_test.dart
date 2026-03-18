import 'package:flutter_test/flutter_test.dart';
import 'package:papichulo/models/food_item.dart';
import 'package:papichulo/services/cart_service.dart';

void main() {

  group('CartService', () {
    final food1 = FoodItem(
      id: 1,
      name: 'Burger',
      price: 10.0,
      category: 'Food',
      type: 'Non-Veg',
      ingredients: [],
      imagePath: 'img.png',
    );

    final food1Duplicate = FoodItem(
      id: 1,
      name: 'Burger',
      price: 10.0,
      category: 'Food',
      type: 'Non-Veg',
      ingredients: [],
      imagePath: 'img.png',
    );

    final food2 = FoodItem(
      id: 2,
      name: 'Fries',
      price: 5.0,
      category: 'Sides',
      type: 'Veg',
      ingredients: [],
      imagePath: 'img.png',
    );

    test('addItem adds item and increments quantity on duplicate matches()', () {
      final cart = CartService();
      cart.clearCart(); // Reset singleton

      cart.addItem(food1);
      expect(cart.items.length, 1);
      expect(cart.itemCount, 1);
      expect(cart.totalAmount, 10.0);

      cart.addItem(food1Duplicate);
      expect(cart.items.length, 1); // Should match FoodItem via matches()
      expect(cart.items.first.quantity, 2);
      expect(cart.itemCount, 2);
      expect(cart.totalAmount, 20.0);
    });

    test('removeItem removes correctly by matches()', () {
      final cart = CartService();
      cart.clearCart();

      cart.addItem(food1);
      cart.addItem(food2);
      expect(cart.items.length, 2);

      cart.removeItem(food1Duplicate);
      expect(cart.items.length, 1);
      expect(cart.items.first.foodItem.matches(food2), isTrue);
    });

    test('updateQuantity updates quantity correctly', () {
      final cart = CartService();
      cart.clearCart();

      cart.addItem(food1);
      cart.updateQuantity(food1, 5);
      
      expect(cart.items.first.quantity, 5);
      expect(cart.itemCount, 5);
      expect(cart.totalAmount, 50.0);
    });

    test('updateQuantity removes item if quantity <= 0', () {
      final cart = CartService();
      cart.clearCart();

      cart.addItem(food1);
      cart.updateQuantity(food1, 0);
      
      expect(cart.items.isEmpty, isTrue);
    });
  });
}
