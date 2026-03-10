class FoodItem {
  final int? id;
  final String name;
  final String category;
  final String type; // Veg / Non-Veg
  final List<String> ingredients;
  final String? imageUrl; // Network URL for food image
  final String? imagePath; // Local asset path for food image
  final double price;
  final double rating;

  FoodItem({
    this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.ingredients,
    this.imageUrl,
    this.imagePath,
    this.price = 0.0,
    this.rating = 4.5,
  });

  /// Returns true if this item matches [other].
  /// Checks by [id] first (if both are non-null), falls back to [name].
  bool matches(FoodItem other) {
    if (id != null && other.id != null) {
      return id == other.id;
    }
    return name == other.name;
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: (json['id'] as num?)?.toInt(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      imageUrl: json['imageUrl']?.toString(),
      imagePath: json['imagePath']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'type': type,
        'ingredients': ingredients,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'price': price,
        'rating': rating,
      };
}
