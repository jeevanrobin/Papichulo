class FoodItem {
  final String name;
  final String category;
  final String type; // Veg / Non-Veg
  final List<String> ingredients;

  FoodItem({
    required this.name,
    required this.category,
    required this.type,
    required this.ingredients,
  });
}
