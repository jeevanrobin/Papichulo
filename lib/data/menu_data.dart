import '../models/food_item.dart';

final List<FoodItem> papichuloMenu = [
  // Pizza - Veg
  FoodItem(name: 'Cheese Pizza', category: 'Pizza', type: 'Veg', ingredients: ['Cheese', 'Dough', 'Tomato Sauce'], imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591', price: 299, rating: 4.5),
  FoodItem(name: 'Veg Delight', category: 'Pizza', type: 'Veg', ingredients: ['Mixed Vegetables', 'Cheese', 'Dough'], imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002', price: 349, rating: 4.3),
  FoodItem(name: 'Crispy Onion Pizza', category: 'Pizza', type: 'Veg', ingredients: ['Onions', 'Cheese', 'Spices'], imageUrl: 'https://images.unsplash.com/photo-1593560708920-61dd98c46a4e', price: 279, rating: 4.4),
  FoodItem(name: 'Veggie Surprise', category: 'Pizza', type: 'Veg', ingredients: ['Broccoli', 'Peppers', 'Cheese'], imageUrl: 'https://images.unsplash.com/photo-1571407970349-bc81e7e96a47', price: 329, rating: 4.6),
  FoodItem(name: 'Paneer Tikka Pizza', category: 'Pizza', type: 'Veg', ingredients: ['Paneer', 'Cheese', 'Spices'], imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38', price: 399, rating: 4.7),
  FoodItem(name: 'Veggie Blast', category: 'Pizza', type: 'Veg', ingredients: ['Mushrooms', 'Olives', 'Cheese'], imageUrl: 'https://images.unsplash.com/photo-1595854341625-f33ee10dbf94', price: 359, rating: 4.5),

  // Pizza - Non-Veg
  FoodItem(name: 'Chicken Paprika Pizza', category: 'Pizza', type: 'Non-Veg', ingredients: ['Chicken', 'Cheese', 'Paprika'], imageUrl: 'https://images.unsplash.com/photo-1628840042765-356cda07f4ee', price: 349, rating: 4.6),
  FoodItem(name: 'Cheesy Orange Chicken Pizza', category: 'Pizza', type: 'Non-Veg', ingredients: ['Chicken', 'Double Cheese', 'Orange Sauce'], imageUrl: 'https://images.unsplash.com/photo-1565958011504-4b36aea463bf', price: 379, rating: 4.4),
  FoodItem(name: 'Spicy Chicken Pizza', category: 'Pizza', type: 'Non-Veg', ingredients: ['Chicken', 'Green Chilli', 'Cheese'], imageUrl: 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee', price: 329, rating: 4.5),
  FoodItem(name: 'Chicken Cheese Blast', category: 'Pizza', type: 'Non-Veg', ingredients: ['Chicken', 'Triple Cheese', 'Spices'], imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561486', price: 399, rating: 4.7),

  // Burgers - Veg
  FoodItem(name: 'Veg Burger', category: 'Burgers', type: 'Veg', ingredients: ['Veg Patty', 'Lettuce', 'Tomato', 'Sauce'], imageUrl: 'https://images.unsplash.com/photo-1520072959219-c595dc870360', price: 199, rating: 4.3),
  FoodItem(name: 'Tandoori Veg Burger', category: 'Burgers', type: 'Veg', ingredients: ['Veg Patty', 'Tandoori Sauce', 'Onions'], imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd', price: 219, rating: 4.4),
  FoodItem(name: 'Coleslaw Veg Burger', category: 'Burgers', type: 'Veg', ingredients: ['Veg Patty', 'Coleslaw', 'Cheese'], imageUrl: 'https://images.unsplash.com/photo-1571407614011-11b6a4db5e5b', price: 229, rating: 4.2),
  FoodItem(name: 'Yogurt Veg Burger', category: 'Burgers', type: 'Veg', ingredients: ['Veg Patty', 'Yogurt', 'Cucumber'], imageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349', price: 189, rating: 4.5),
  FoodItem(name: 'DD Veg Burger', category: 'Burgers', type: 'Veg', ingredients: ['Double Veg Patty', 'Cheese', 'Sauce'], imageUrl: 'https://images.unsplash.com/photo-1572802419224-296b0aeee0d9', price: 249, rating: 4.6),

  // Burgers - Non-Veg
  FoodItem(name: 'Chicken Burger', category: 'Burgers', type: 'Non-Veg', ingredients: ['Chicken Patty', 'Cheese', 'Sauce'], imageUrl: 'https://images.unsplash.com/photo-1562547256-7eb01d277f1f', price: 249, rating: 4.5),
  FoodItem(name: 'Coleslaw Chicken Burger', category: 'Burgers', type: 'Non-Veg', ingredients: ['Chicken Patty', 'Coleslaw', 'Cheese'], imageUrl: 'https://images.unsplash.com/photo-1553979459-d2229ba7433b', price: 269, rating: 4.4),
  FoodItem(name: 'Yogurt Cheesy Chicken Burger', category: 'Burgers', type: 'Non-Veg', ingredients: ['Chicken Patty', 'Yogurt', 'Cheese'], imageUrl: 'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5', price: 239, rating: 4.3),
  FoodItem(name: 'DD Chicken Burger', category: 'Burgers', type: 'Non-Veg', ingredients: ['Double Chicken Patty', 'Cheese', 'Sauce'], imageUrl: 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90', price: 299, rating: 4.7),

  // Sandwiches - Veg
  FoodItem(name: 'Veg Sandwich', category: 'Sandwiches', type: 'Veg', ingredients: ['Mixed Vegetables', 'Bread', 'Sauce'], imageUrl: 'https://images.unsplash.com/photo-1588195538326-c5b1e9f80a1b', price: 149, rating: 4.2),
  FoodItem(name: 'Corn Sandwich', category: 'Sandwiches', type: 'Veg', ingredients: ['Sweet Corn', 'Cheese', 'Bread'], imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff', price: 159, rating: 4.3),
  FoodItem(name: 'Coleslaw Veg Sandwich', category: 'Sandwiches', type: 'Veg', ingredients: ['Coleslaw', 'Veg', 'Cheese'], imageUrl: 'https://images.unsplash.com/photo-1528735602780-cf17bffc9987', price: 169, rating: 4.1),
  FoodItem(name: 'Paneer Tikka Sandwich', category: 'Sandwiches', type: 'Veg', ingredients: ['Paneer', 'Tikka Sauce', 'Bread'], imageUrl: 'https://images.unsplash.com/photo-1621852004158-f3bc188ace2d', price: 199, rating: 4.5),

  // Sandwiches - Non-Veg
  FoodItem(name: 'Club Sandwich', category: 'Sandwiches', type: 'Non-Veg', ingredients: ['Chicken', 'Cheese', 'Multiple Layers'], imageUrl: 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d', price: 189, rating: 4.4),
  FoodItem(name: 'Chicken Tikka Sandwich', category: 'Sandwiches', type: 'Non-Veg', ingredients: ['Chicken Tikka', 'Bread', 'Sauce'], imageUrl: 'https://images.unsplash.com/photo-1606787620077-e51df1bdc82f', price: 199, rating: 4.4),
  FoodItem(name: 'Coleslaw Chicken Sandwich', category: 'Sandwiches', type: 'Non-Veg', ingredients: ['Chicken', 'Coleslaw', 'Bread'], imageUrl: 'https://images.unsplash.com/photo-1619740455993-9e4e0b27e49f', price: 179, rating: 4.3),
  FoodItem(name: 'Cheesy Dish Chicken Sandwich', category: 'Sandwiches', type: 'Non-Veg', ingredients: ['Chicken', 'Double Cheese', 'Bread'], imageUrl: 'https://images.unsplash.com/photo-1567234669003-dce7a7a88821', price: 219, rating: 4.5),

  // Hot Dogs
  FoodItem(name: 'Chilli Cheese Dog', category: 'Hot Dogs', type: 'Non-Veg', ingredients: ['Hot Dog', 'Chilli', 'Cheese'], imageUrl: 'https://images.unsplash.com/photo-1612392062798-2dbaa4d3d6e4', price: 129, rating: 4.2),
  FoodItem(name: 'Spicy Dog', category: 'Hot Dogs', type: 'Non-Veg', ingredients: ['Hot Dog', 'Spicy Sauce', 'Onions'], imageUrl: 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32', price: 119, rating: 4.1),
  FoodItem(name: 'BBQ Dog', category: 'Hot Dogs', type: 'Non-Veg', ingredients: ['Hot Dog', 'BBQ Sauce', 'Cheese'], imageUrl: 'https://images.unsplash.com/photo-1590588469668-adf3e6c1e9e1', price: 139, rating: 4.3),
  FoodItem(name: 'Papichulo Special Dog', category: 'Hot Dogs', type: 'Non-Veg', ingredients: ['Hot Dog', 'Special Sauce', 'Toppings'], imageUrl: 'https://images.unsplash.com/photo-1612392062422-2c3e6b3e8f19', price: 159, rating: 4.6),

  // Snacks
  FoodItem(name: 'French Fries', category: 'Snacks', type: 'Veg', ingredients: ['Potatoes', 'Salt', 'Spices'], imageUrl: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877', price: 79, rating: 4.4),
  FoodItem(name: 'Chilli Potato Nuggets', category: 'Snacks', type: 'Veg', ingredients: ['Potatoes', 'Chilli', 'Spices'], imageUrl: 'https://images.unsplash.com/photo-1601924582970-9238bcb495d9', price: 99, rating: 4.5),
  FoodItem(name: 'Chicken Popcorn', category: 'Snacks', type: 'Non-Veg', ingredients: ['Chicken', 'Batter', 'Spices'], imageUrl: 'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58', price: 119, rating: 4.6),
  FoodItem(name: 'Chicken Nuggets', category: 'Snacks', type: 'Non-Veg', ingredients: ['Chicken', 'Crispy Coating', 'Spices'], imageUrl: 'https://images.unsplash.com/photo-1562967914-608f82629710', price: 129, rating: 4.5),
  FoodItem(name: 'Smilies (with cheese)', category: 'Snacks', type: 'Veg', ingredients: ['Potatoes', 'Cheese', 'Spices'], imageUrl: 'https://images.unsplash.com/photo-1600891964092-4316c288032e', price: 109, rating: 4.3),
  FoodItem(name: 'Nachos (with cheese)', category: 'Snacks', type: 'Veg', ingredients: ['Tortilla Chips', 'Cheese Sauce', 'Spices'], imageUrl: 'https://images.unsplash.com/photo-1582169296194-e4d644c48063', price: 139, rating: 4.4),
];
