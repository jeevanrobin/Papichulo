# Papichulo - Food Ordering Web Application

A modern, responsive Flutter web application for food ordering with cart functionality, beautiful UI, and smooth user experience.

## Features

- **Modern UI Design**: Clean, professional interface with smooth animations
- **Shopping Cart**: Add items to cart, manage quantities, and checkout
- **Menu Categories**: Pizza, Burgers, Sandwiches, Hot Dogs, and Snacks
- **Responsive Design**: Works perfectly on desktop and mobile browsers
- **Real-time Updates**: Cart badge updates in real-time
- **Image Loading**: High-quality food images with fallback icons
- **Web Optimized**: Fast loading and smooth performance

## Getting Started

### Prerequisites
- Flutter SDK (3.10.7 or higher)
- Chrome browser for development

### Installation

1. Clone or navigate to the project directory:
   ```bash
   cd papichulo
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the web application:
   ```bash
   flutter run -d chrome
   ```

### Building for Production

1. Build the web app:
   ```bash
   flutter build web --release
   ```

2. The built files will be in the `build/web` directory

3. Deploy the contents of `build/web` to your web server

### Quick Build (Windows)

Run the provided batch file:
```bash
build_web.bat
```

## Project Structure

```
lib/
├── core/
│   └── theme.dart          # App theme configuration
├── data/
│   └── menu_data.dart      # Food menu data
├── models/
│   ├── food_item.dart      # Food item model
│   └── cart_item.dart      # Cart item model
├── screens/
│   ├── splash/
│   │   └── splash_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── menu/
│   │   └── menu_screen.dart
│   └── cart/
│       └── cart_screen.dart
├── services/
│   └── cart_service.dart   # Cart state management
└── main.dart               # App entry point
```

## Key Components

### Cart Service
- Singleton pattern for global cart state
- Add, remove, and update item quantities
- Real-time cart total calculation
- Persistent cart state across screens

### Food Menu
- 30+ food items across 5 categories
- High-quality images from Unsplash
- Detailed ingredients and pricing
- Vegetarian and non-vegetarian options

### Responsive Design
- Mobile-first approach
- Flexible grid layouts
- Touch-friendly buttons
- Optimized for various screen sizes

## Customization

### Adding New Food Items
Edit `lib/data/menu_data.dart` to add new items:

```dart
FoodItem(
  name: 'Your Food Name',
  category: 'Category',
  type: 'Veg' or 'Non-Veg',
  ingredients: ['ingredient1', 'ingredient2'],
  imageUrl: 'https://your-image-url.com',
  price: 12.99,
  rating: 4.5,
)
```

### Changing Colors
Modify colors in `lib/screens/home/home_screen.dart`:

```dart
static const Color accentColor = Color(0xFFFF6B35); // Orange
static const Color primaryColor = Color(0xFF66BB6A); // Green
```

## Deployment Options

### Firebase Hosting
1. Install Firebase CLI
2. Run `firebase init hosting`
3. Set public directory to `build/web`
4. Run `firebase deploy`

### Netlify
1. Build the project: `flutter build web`
2. Drag and drop `build/web` folder to Netlify

### GitHub Pages
1. Build the project
2. Push `build/web` contents to `gh-pages` branch

## Performance Tips

- Images are loaded from CDN (Unsplash) for better performance
- Lazy loading implemented for menu items
- Optimized animations and transitions
- Minimal dependencies for faster load times

## Browser Support

- Chrome (recommended)
- Firefox
- Safari
- Edge

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is for educational and demonstration purposes.

---

**Enjoy your food ordering experience with Papichulo!** 🍕🍔
