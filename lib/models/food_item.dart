class FoodItem {
  final String name;
  final String category;
  final String type; // Veg / Non-Veg
  final List<String> ingredients;
  final String? imageUrl; // Network URL for food image
  final String? imagePath; // Local asset path for food image
  final double price;
  final double rating;

  FoodItem({
    required this.name,
    required this.category,
    required this.type,
    required this.ingredients,
    this.imageUrl,
    this.imagePath,
    this.price = 0.0,
    this.rating = 4.5,
  });
}
