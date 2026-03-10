import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papichulo/models/cart_item.dart';
import 'package:papichulo/models/food_item.dart';

void main() {
  group('CartItem', () {
    final food = FoodItem(
      id: 1,
      name: 'Test Food',
      price: 15.0,
      category: 'Test',
      description: 'Desc',
      imageAsset: 'img.png',
    );

    test('totalPrice calculates correctly', () {
      final item = CartItem(foodItem: food, quantity: 3);
      expect(item.totalPrice, 45.0);
    });

    test('copyWith() preserves existing values while applying overrides', () {
      final item = CartItem(foodItem: food, quantity: 2);
      
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.foodItem.matches(food), isTrue);
      expect(updated.totalPrice, 75.0);
    });

    test('copyWith() works with no arguments to create exact shallow copy', () {
      final item = CartItem(foodItem: food, quantity: 2);
      
      final copy = item.copyWith();
      expect(copy.quantity, 2);
      expect(copy.foodItem.name, 'Test Food');
    });
  });
}
