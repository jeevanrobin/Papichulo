import '../models/food_item.dart';

final List<FoodItem> papichuloMenu = [
  // Pizza - Veg
  FoodItem(
    name: 'Cheese Pizza',
    category: 'Pizza',
    type: 'Veg',
    ingredients: ['Cheese', 'Dough', 'Tomato Sauce'],
  ),
  FoodItem(
    name: 'Veg Delight',
    category: 'Pizza',
    type: 'Veg',
    ingredients: ['Mixed Vegetables', 'Cheese', 'Dough'],
  ),
  FoodItem(
    name: 'Crispy Onion',
    category: 'Pizza',
    type: 'Veg',
    ingredients: ['Onions', 'Cheese', 'Spices'],
  ),
  FoodItem(
    name: 'Veggie Surprise',
    category: 'Pizza',
    type: 'Veg',
    ingredients: ['Broccoli', 'Peppers', 'Cheese'],
  ),
  FoodItem(
    name: 'Paneer Tikka',
    category: 'Pizza',
    type: 'Veg',
    ingredients: ['Paneer', 'Cheese', 'Spices'],
  ),
  FoodItem(
    name: 'Veggie Blast',
    category: 'Pizza',
    type: 'Veg',
    ingredients: ['Mushrooms', 'Olives', 'Cheese'],
  ),

  // Pizza - Non-Veg
  FoodItem(
    name: 'Chicken Paprika',
    category: 'Pizza',
    type: 'Non-Veg',
    ingredients: ['Chicken', 'Cheese', 'Paprika'],
  ),
  FoodItem(
    name: 'Cheesy Oregano Chicken',
    category: 'Pizza',
    type: 'Non-Veg',
    ingredients: ['Chicken', 'Double Cheese', 'Oregano'],
  ),
  FoodItem(
    name: 'Spicy Chicken',
    category: 'Pizza',
    type: 'Non-Veg',
    ingredients: ['Chicken', 'Green Chilli', 'Cheese'],
  ),
  FoodItem(
    name: 'Chicken Cheese Blast',
    category: 'Pizza',
    type: 'Non-Veg',
    ingredients: ['Chicken', 'Triple Cheese', 'Spices'],
  ),

  // Burgers - Veg
  FoodItem(
    name: 'Veg Burger',
    category: 'Burgers',
    type: 'Veg',
    ingredients: ['Veg Patty', 'Lettuce', 'Tomato', 'Sauce'],
  ),
  FoodItem(
    name: 'Tando Twist',
    category: 'Burgers',
    type: 'Veg',
    ingredients: ['Veg Patty', 'Tandoori Sauce', 'Onions'],
  ),
  FoodItem(
    name: 'Coleslaw Veg',
    category: 'Burgers',
    type: 'Veg',
    ingredients: ['Veg Patty', 'Coleslaw', 'Cheese'],
  ),
  FoodItem(
    name: 'Yogurt Veg',
    category: 'Burgers',
    type: 'Veg',
    ingredients: ['Veg Patty', 'Yogurt', 'Cucumber'],
  ),
  FoodItem(
    name: 'DD Veg Burger',
    category: 'Burgers',
    type: 'Veg',
    ingredients: ['Double Veg Patty', 'Cheese', 'Sauce'],
  ),

  // Burgers - Non-Veg
  FoodItem(
    name: 'Chicken Burger',
    category: 'Burgers',
    type: 'Non-Veg',
    ingredients: ['Chicken Patty', 'Cheese', 'Sauce'],
  ),
  FoodItem(
    name: 'Coleslaw Chicken',
    category: 'Burgers',
    type: 'Non-Veg',
    ingredients: ['Chicken Patty', 'Coleslaw', 'Cheese'],
  ),
  FoodItem(
    name: 'Yogurt Cheesy',
    category: 'Burgers',
    type: 'Non-Veg',
    ingredients: ['Chicken Patty', 'Yogurt', 'Cheese'],
  ),
  FoodItem(
    name: 'DD Chicken',
    category: 'Burgers',
    type: 'Non-Veg',
    ingredients: ['Double Chicken Patty', 'Cheese', 'Sauce'],
  ),

  // Sandwiches - Veg
  FoodItem(
    name: 'Veg Sandwich',
    category: 'Sandwiches',
    type: 'Veg',
    ingredients: ['Mixed Vegetables', 'Bread', 'Sauce'],
  ),
  FoodItem(
    name: 'Club Sandwich',
    category: 'Sandwiches',
    type: 'Veg',
    ingredients: ['Vegetables', 'Cheese', 'Multiple Layers'],
  ),
  FoodItem(
    name: 'Corn Sandwich',
    category: 'Sandwiches',
    type: 'Veg',
    ingredients: ['Sweet Corn', 'Cheese', 'Bread'],
  ),
  FoodItem(
    name: 'Coleslaw Veg',
    category: 'Sandwiches',
    type: 'Veg',
    ingredients: ['Coleslaw', 'Veg', 'Cheese'],
  ),
  FoodItem(
    name: 'Paneer Tikka Sandwich',
    category: 'Sandwiches',
    type: 'Veg',
    ingredients: ['Paneer', 'Tikka Sauce', 'Bread'],
  ),

  // Sandwiches - Non-Veg
  FoodItem(
    name: 'Chicken Tikka Sandwich',
    category: 'Sandwiches',
    type: 'Non-Veg',
    ingredients: ['Chicken Tikka', 'Bread', 'Sauce'],
  ),
  FoodItem(
    name: 'Coleslaw Chicken',
    category: 'Sandwiches',
    type: 'Non-Veg',
    ingredients: ['Chicken', 'Coleslaw', 'Bread'],
  ),
  FoodItem(
    name: 'Cheesy Ditch Chicken',
    category: 'Sandwiches',
    type: 'Non-Veg',
    ingredients: ['Chicken', 'Double Cheese', 'Bread'],
  ),

  // Hot Dogs
  FoodItem(
    name: 'Chilli Cheese Dog',
    category: 'Hot Dogs',
    type: 'Non-Veg',
    ingredients: ['Hot Dog', 'Chilli', 'Cheese'],
  ),
  FoodItem(
    name: 'Spicy Dog',
    category: 'Hot Dogs',
    type: 'Non-Veg',
    ingredients: ['Hot Dog', 'Spicy Sauce', 'Onions'],
  ),
  FoodItem(
    name: 'BBQ Dog',
    category: 'Hot Dogs',
    type: 'Non-Veg',
    ingredients: ['Hot Dog', 'BBQ Sauce', 'Cheese'],
  ),
  FoodItem(
    name: 'Papichulo Special Dog',
    category: 'Hot Dogs',
    type: 'Non-Veg',
    ingredients: ['Hot Dog', 'Special Sauce', 'Toppings'],
  ),

  // Snacks
  FoodItem(
    name: 'Fries',
    category: 'Snacks',
    type: 'Veg',
    ingredients: ['Potatoes', 'Salt', 'Spices'],
  ),
  FoodItem(
    name: 'Chilly Potato Nuggets',
    category: 'Snacks',
    type: 'Veg',
    ingredients: ['Potatoes', 'Chilli', 'Spices'],
  ),
  FoodItem(
    name: 'Chicken Popcorn',
    category: 'Snacks',
    type: 'Non-Veg',
    ingredients: ['Chicken', 'Batter', 'Spices'],
  ),
  FoodItem(
    name: 'Chicken Nuggets',
    category: 'Snacks',
    type: 'Non-Veg',
    ingredients: ['Chicken', 'Crispy Coating', 'Spices'],
  ),
  FoodItem(
    name: 'Smilies with Cheese',
    category: 'Snacks',
    type: 'Veg',
    ingredients: ['Potatoes', 'Cheese', 'Spices'],
  ),
  FoodItem(
    name: 'Nachos with Cheese',
    category: 'Snacks',
    type: 'Veg',
    ingredients: ['Tortilla Chips', 'Cheese Sauce', 'Spices'],
  ),

  // Specials
  FoodItem(
    name: 'Papichulo Special Combo',
    category: 'Specials',
    type: 'Non-Veg',
    ingredients: ['Pizza', 'Burger', 'Hot Dog', 'Fries'],
  ),
  FoodItem(
    name: 'Veg Combo Pack',
    category: 'Specials',
    type: 'Veg',
    ingredients: ['Pizza', 'Burger', 'Sandwich', 'Fries'],
  ),
  FoodItem(
    name: 'Family Feast',
    category: 'Specials',
    type: 'Non-Veg',
    ingredients: ['2 Pizzas', '2 Burgers', 'Chicken Wings', 'Fries'],
  ),
  FoodItem(
    name: 'Cheese Lovers',
    category: 'Specials',
    type: 'Veg',
    ingredients: ['Extra Cheese Pizza', 'Cheesy Burger', 'Cheesy Sandwich'],
  ),
];
