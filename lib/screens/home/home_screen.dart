import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/menu_data.dart';
import '../../widgets/fly_to_cart_button.dart';
import '../../widgets/animated_cart_icon.dart';
import '../menu/menu_screen.dart';
import '../cart/cart_drawer.dart';
import '../../providers/cart_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const Color goldYellow = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF1A1A1A);
  
  late AnimationController _headerController;
  late AnimationController _heroController;
  late AnimationController _cardController;
  late Animation<double> _headerSlide;
  late Animation<double> _heroFade;
  late Animation<double> _cardStagger;
  final Map<int, bool> _hoveredCards = {};
  late GlobalKey _cartIconKey;
  
  String _selectedCategory = 'Pizza';
  final List<String> _categories = ['Pizza', 'Burgers', 'Sandwiches', 'Hot Dogs', 'Snacks', 'Specials'];

  @override
  void initState() {
    super.initState();
    _cartIconKey = GlobalKey();
    _headerController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _heroController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _cardController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    
    _headerSlide = Tween<double>(begin: -50, end: 0).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _heroFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeIn));
    _cardStagger = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
    
    _startAnimations();
  }

  void _startAnimations() async {
    _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _heroController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _cardController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _heroController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  _buildAnimatedHeader(),
                  _buildAnimatedHeroSection(),
                  _buildCategoryNav(),
                  _buildAnimatedFeaturedItems(),
                  _FooterWidget(),
                ],
              ),
            ),
          ),
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              if (!cartProvider.isCartOpen) return const SizedBox();
              return Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                left: 0,
                child: GestureDetector(
                  onTap: () => cartProvider.closeCart(),
                  child: Container(
                    color: Colors.black54,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          width: 420,
                          child: GestureDetector(
                            onTap: () {},
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF121212),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                              child: CartDrawer(
                                cartService: cartProvider.cartService,
                                onClose: () => cartProvider.closeCart(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerSlide,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlide.value),
          child: RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [black, darkGrey],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldYellow.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [goldYellow, darkGold],
                          ).createShader(bounds),
                          child: const Text(
                            'PAPICHULO',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      _buildAnimatedNavItem('Menu', () => Navigator.push(context, _createRoute(const MenuScreen()))),
                      const SizedBox(width: 20),
                      _buildAnimatedCartIcon(),
                      const SizedBox(width: 20),
                      _buildHeaderCTA(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedNavItem(String text, VoidCallback onTap) {
    return _NavItemWidget(text: text, onTap: onTap);
  }

  Widget _buildAnimatedCartIcon() {
    return AnimatedCartIcon(
      key: _cartIconKey,
      onCartTap: () => context.read<CartProvider>().openCart(),
    );
  }

  Widget _buildHeaderCTA() {
    return _HeaderCTAWidget(onTap: () => Navigator.push(context, _createRoute(const MenuScreen())));
  }

  Widget _buildAnimatedHeroSection() {
    return AnimatedBuilder(
      animation: _heroFade,
      builder: (context, child) {
        return Opacity(
          opacity: _heroFade.value,
          child: RepaintBoundary(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width > 768 ? 60 : 24,
                    vertical: MediaQuery.of(context).size.width > 768 ? 75 : 45,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0B0B),
                    boxShadow: [
                      BoxShadow(
                        color: goldYellow.withOpacity(0.08),
                        blurRadius: 120,
                        spreadRadius: 60,
                        offset: const Offset(150, 50),
                      ),
                    ],
                  ),
                  child: MediaQuery.of(context).size.width > 768
                      ? Row(
                          children: [
                            Expanded(
                              child: _buildHeroContent(),
                            ),
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 225,
                                  height: 225,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        goldYellow.withOpacity(0.12),
                                        goldYellow.withOpacity(0.04),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildHeroContent(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroContent() {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Order Fresh.\nEat Bold.',
          style: isMobile
              ? Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white)
              : Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'Premium quality. Fast delivery. Exceptional taste.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 32),
        _buildPrimaryCTA(),
      ],
    );
  }

  Widget _buildPrimaryCTA() {
    return _PrimaryCTAWidget(onTap: () => Navigator.push(context, _createRoute(const MenuScreen())));
  }

  Widget _buildCategoryNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          children: _categories.map((category) {
            final isActive = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? goldYellow : Colors.transparent,
                      border: Border.all(
                        color: isActive ? goldYellow : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isActive ? Colors.black : Colors.black87,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAnimatedFeaturedItems() {
    final filteredItems = papichuloMenu
        .where((item) => item.category == _selectedCategory)
        .take(4)
        .toList();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          Text(
            'Popular Right Now',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 28),
          if (filteredItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No items in this category',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[400],
                ),
              ),
            )
          else
            Row(
              children: List.generate(filteredItems.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildPremiumFoodCard(filteredItems[index], index),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumFoodCard(dynamic item, int index) {
    final isHovered = _hoveredCards[index] ?? false;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredCards[index] = true),
      onExit: (_) => setState(() => _hoveredCards[index] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, isHovered ? -8 : 0, 0),
        child: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isHovered ? 0.8 : 0.6),
                  blurRadius: isHovered ? 32 : 20,
                  offset: Offset(0, isHovered ? 16 : 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: Colors.black,
                  ),
                  child: item.imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            cacheHeight: 160,
                            cacheWidth: 300,
                            filterQuality: FilterQuality.low,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.fastfood, size: 50, color: Colors.grey)),
                          ),
                        )
                      : const Center(child: Icon(Icons.fastfood, size: 50, color: Colors.grey)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.star, size: 14, color: goldYellow),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.rating}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: goldYellow,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.ingredients.take(2).join(', '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${item.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          FlyToCartButton(
                            item: item,
                            cartIconKey: _cartIconKey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getCartWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 480;
    if (screenWidth >= 768) return 450;
    return screenWidth;
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: child,
        );
      },
    );
  }
}


class _NavItemWidget extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  static const Color goldYellow = Color(0xFFFFD700);

  _NavItemWidget({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: goldYellow.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: goldYellow,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}



class _HeaderCTAWidget extends StatelessWidget {
  final VoidCallback onTap;
  static const Color goldYellow = Color(0xFFFFD700);

  _HeaderCTAWidget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: goldYellow,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: goldYellow.withOpacity(0.4),
              blurRadius: 15,
            ),
          ],
        ),
        child: Text(
          'Order Now',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PrimaryCTAWidget extends StatelessWidget {
  final VoidCallback onTap;
  static const Color goldYellow = Color(0xFFFFD700);

  _PrimaryCTAWidget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          color: goldYellow,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: goldYellow.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          'Order Now',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FooterWidget extends StatelessWidget {
  _FooterWidget();

  static const Color goldYellow = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [black, darkGrey],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: goldYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('+123-456 789', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                  Text('info@papichulo.com', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                  Text('New York, USA', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Links',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: goldYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('About Us', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                  Text('FAQ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                  Text('Terms & Conditions', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Follow Us',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: goldYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.facebook, color: goldYellow, size: 20),
                      const SizedBox(width: 12),
                      Icon(Icons.camera_alt, color: goldYellow, size: 20),
                      const SizedBox(width: 12),
                      Icon(Icons.language, color: goldYellow, size: 20),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Methods',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: goldYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: goldYellow.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Visa', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: goldYellow)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: goldYellow.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('MC', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: goldYellow)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Divider(color: goldYellow.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            '© 2024 Papichulo. All rights reserved.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
