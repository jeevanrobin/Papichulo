import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papichulo/models/food_item.dart';

void main() {
  group('FoodItem', () {
    test('matches() returns true for same ID regardless of name', () {
      final item1 = FoodItem(id: 1, name: 'Burger', price: 10, category: 'A', type: 'Non-Veg', ingredients: [], imagePath: 'img.png');
      final item2 = FoodItem(id: 1, name: 'Hamburger', price: 10, category: 'A', type: 'Non-Veg', ingredients: [], imagePath: 'img.png');
      expect(item1.matches(item2), isTrue);
    });

    test('matches() falls back to name if ID is missing or null for one', () {
      final item1 = FoodItem(id: null, name: 'Burger', price: 10, category: 'A', type: 'Non-Veg', ingredients: [], imagePath: 'img.png');
      final item2 = FoodItem(id: 2, name: 'Burger', price: 15, category: 'B', type: 'Non-Veg', ingredients: [], imagePath: 'img2.png');
      expect(item1.matches(item2), isTrue);
    });

    test('matches() returns false if ID and name do not match', () {
      final item1 = FoodItem(id: 1, name: 'Burger', price: 10, category: 'A', type: 'Non-Veg', ingredients: [], imagePath: 'img.png');
      final item2 = FoodItem(id: 2, name: 'Fries', price: 5, category: 'B', type: 'Veg', ingredients: [], imagePath: 'img2.png');
      expect(item1.matches(item2), isFalse);
    });

    test('toJson() and fromJson() perform accurate round-trip serialization', () {
      final item = FoodItem(
        id: 42,
        name: 'Deluxe Burger',
        price: 15.99,
        category: 'Burgers',
        type: 'Non-Veg',
        ingredients: ['Beef', 'Cheese'],
        imagePath: 'assets/deluxe.png',
      );

      final json = item.toJson();
      expect(json['id'], 42);
      expect(json['name'], 'Deluxe Burger');
      expect(json['type'], 'Non-Veg');

      final restored = FoodItem.fromJson(json);
      expect(restored.matches(item), isTrue);
      expect(restored.type, 'Non-Veg');
      expect(restored.price, 15.99);
    });
  });
}
