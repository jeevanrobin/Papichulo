# Papichulo Branding Guide

## Color Palette

### Primary Colors
- **Black (#000000)**: Primary background for headers, dark sections
- **Dark Grey (#1A1A1A)**: Secondary background for cards, drawers
- **Gold Yellow (#FFD700)**: Accent color for buttons, highlights, prices
- **Dark Gold (#B8860B)**: Gradient complement (deprecated - use solid yellow)

## Branding Standards

### Button Styling
All buttons follow a consistent pattern:
- **Background**: Solid Gold Yellow (#FFD700)
- **Text Color**: Black (#000000)
- **Border Radius**: 8-12px (rounded corners)
- **Shadow**: `BoxShadow(color: goldYellow.withOpacity(0.3), blurRadius: 12)`
- **No Gradients**: Use solid yellow only

**Applied to:**
- "Order Now" buttons (home hero, header)
- "Add to Cart" buttons (menu items, home cards)
- "Checkout" buttons (cart drawer, cart screen)
- Dialog action buttons

### Price Display
- **Color**: Solid Gold Yellow (#FFD700)
- **No ShaderMask**: Removed gradient overlays for consistency
- **Font Weight**: Bold (w600-w700)
- **Sizes**: 14px (item prices), 16px (totals), 24px (grand total)

### Icon Colors
- **Shopping Cart Icon**: Black on yellow background
- **Action Icons** (add/remove): Black on yellow buttons
- **Fallback Icons**: Grey for missing images

### Background Usage
- **Headers**: Black (#000000) with optional gold glow
- **Hero Section**: Dark (#0B0B0B) with subtle gold glow
- **Cards**: Dark Grey (#1A1A1A) on dark theme, White on light theme
- **Drawers**: Dark Grey (#1A1A1A)
- **Screens**: White (light theme) or Black (dark theme)

### Typography
- **Headlines**: Use theme.textTheme (displayLarge, displayMedium, headlineMedium)
- **Body Text**: Use theme.textTheme (bodyLarge, bodyMedium, bodySmall)
- **Accent Text**: Gold Yellow for prices and highlights

## Implementation Checklist

✅ **Home Screen**
- Black header with gold accents
- Dark hero section with yellow glow
- Solid yellow "Order Now" buttons
- Dark food cards with yellow "Add" buttons

✅ **Menu Screen**
- Black app bar with gold title
- White background with light cards
- Solid yellow "Add" buttons (no gradients)
- Gold prices (solid, no ShaderMask)

✅ **Cart Screen**
- White background (light theme)
- White cards with subtle shadows
- Solid yellow quantity buttons
- Solid yellow "Checkout" button
- Gold prices throughout

✅ **Cart Drawer**
- Dark grey background (#1A1A1A)
- Dark cards with gold accents
- Solid yellow "Checkout" button
- Gold prices and quantities

## Consistency Rules

1. **No Gradient Buttons**: All buttons use solid yellow (#FFD700)
2. **No ShaderMask Prices**: All prices use solid gold text
3. **Icon Consistency**: Black icons on yellow, grey fallbacks
4. **Shadow Consistency**: Use `goldYellow.withOpacity(0.3)` for button shadows
5. **Border Radius**: 8px for buttons, 12-16px for cards
6. **Dark Theme**: Black/Dark Grey backgrounds with white text
7. **Light Theme**: White backgrounds with black text

## Color Constants

```dart
static const Color goldYellow = Color(0xFFFFD700);
static const Color darkGold = Color(0xFFB8860B);  // Deprecated
static const Color black = Color(0xFF000000);
static const Color darkGrey = Color(0xFF1A1A1A);
```

**Note**: `darkGold` is deprecated. Use `goldYellow` for all accents.
