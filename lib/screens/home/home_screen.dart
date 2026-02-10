import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/menu_data.dart';
import '../../widgets/fly_to_cart_button.dart';
import '../../widgets/animated_cart_icon.dart';
import '../../services/analytics_service.dart';
import '../menu/menu_screen.dart';
import '../admin/orders_admin_screen.dart';
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
  final List<String> _categories = [
    'Pizza',
    'Burgers',
    'Sandwiches',
    'Hot Dogs',
    'Snacks',
    'Specials',
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService().track('page_view', params: {'screen': 'home'});
    _cartIconKey = GlobalKey();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerSlide = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _heroFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeIn));
    _cardStagger = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

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
      backgroundColor: const Color(0xFF070707),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF060606), Color(0xFF111111)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    _buildAnimatedHeader(),
                    _buildAnimatedHeroSection(),
                    _buildCategoryNav(),
                    _buildAnimatedFeaturedItems(),
                    const _FooterWidget(),
                  ],
                ),
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
                            onTap: () => FocusScope.of(context).unfocus(),
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
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF050505), Color(0xFF121212)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: goldYellow.withOpacity(0.18)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldYellow.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
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
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      _buildAnimatedNavItem(
                        'Menu',
                        () => Navigator.push(
                          context,
                          _createRoute(const MenuScreen()),
                        ),
                      ),
                      const SizedBox(width: 20),
                      _buildAnimatedNavItem(
                        'Admin',
                        () => Navigator.push(
                          context,
                          _createRoute(const OrdersAdminScreen()),
                        ),
                      ),
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
    return _HeaderCTAWidget(
      onTap: () => Navigator.push(context, _createRoute(const MenuScreen())),
    );
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
                    horizontal: MediaQuery.of(context).size.width > 768
                        ? 60
                        : 24,
                    vertical: MediaQuery.of(context).size.width > 768 ? 75 : 45,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF090909), Color(0xFF050505)],
                    ),
                  ),
                  foregroundDecoration: BoxDecoration(
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
                            Expanded(child: _buildHeroContent()),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: goldYellow.withOpacity(0.5)),
            color: Colors.white.withOpacity(0.03),
          ),
          child: Text(
            'Premium Street Kitchen',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: goldYellow,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Order Fresh.\nEat Bold.',
          style: isMobile
              ? Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  height: 1.04,
                )
              : Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  height: 1.02,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          'Chef-curated menu, bold flavors, and fast doorstep delivery.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.72),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 32),
        _buildPrimaryCTA(),
      ],
    );
  }

  Widget _buildPrimaryCTA() {
    return _PrimaryCTAWidget(
      onTap: () => Navigator.push(context, _createRoute(const MenuScreen())),
    );
  }

  Widget _buildCategoryNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? goldYellow : Colors.transparent,
                        border: Border.all(
                          color: isActive
                              ? goldYellow
                              : Colors.white.withOpacity(0.25),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isActive
                              ? Colors.black
                              : Colors.white.withOpacity(0.9),
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
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
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Top picks from ${_selectedCategory.toUpperCase()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.62),
            ),
          ),
          const SizedBox(height: 28),
          if (filteredItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No items in this category',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[400]),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1180) {
                  return Row(
                    children: List.generate(filteredItems.length, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildPremiumFoodCard(
                            filteredItems[index],
                            index,
                          ),
                        ),
                      );
                    }),
                  );
                }
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: List.generate(filteredItems.length, (index) {
                    return SizedBox(
                      width: constraints.maxWidth > 760
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth,
                      child: _buildPremiumFoodCard(filteredItems[index], index),
                    );
                  }),
                );
              },
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
      child: GestureDetector(
        onTap: () => Navigator.push(context, _createRoute(const MenuScreen())),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, isHovered ? -8 : 0, 0),
          child: RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B1B1B), Color(0xFF0E0E0E)],
                ),
                border: Border.all(color: Colors.white12),
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
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      color: Colors.black,
                    ),
                    child: item.imageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              cacheHeight: 160,
                              cacheWidth: 300,
                              filterQuality: FilterQuality.low,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.fastfood,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.fastfood,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 14,
                                        color: goldYellow,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.rating}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[400], fontSize: 11),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rs ${item.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
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
          position:
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
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

  const _NavItemWidget({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.03),
                Colors.white.withOpacity(0.01),
              ],
            ),
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

class _HeaderCTAWidget extends StatefulWidget {
  final VoidCallback onTap;

  const _HeaderCTAWidget({required this.onTap});

  @override
  State<_HeaderCTAWidget> createState() => _HeaderCTAWidgetState();
}

class _HeaderCTAWidgetState extends State<_HeaderCTAWidget> {
  static const Color goldYellow = Color(0xFFFFD700);
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _hovered ? 1.03 : 1.0,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE168), Color(0xFFFFD700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: goldYellow.withOpacity(_hovered ? 0.46 : 0.32),
                  blurRadius: _hovered ? 28 : 20,
                  offset: Offset(0, _hovered ? 10 : 8),
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
        ),
      ),
    );
  }
}

class _PrimaryCTAWidget extends StatefulWidget {
  final VoidCallback onTap;

  const _PrimaryCTAWidget({required this.onTap});

  @override
  State<_PrimaryCTAWidget> createState() => _PrimaryCTAWidgetState();
}

class _PrimaryCTAWidgetState extends State<_PrimaryCTAWidget> {
  static const Color goldYellow = Color(0xFFFFD700);
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _hovered ? 1.03 : 1.0,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE168), Color(0xFFFFD700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: goldYellow.withOpacity(_hovered ? 0.52 : 0.35),
                  blurRadius: _hovered ? 32 : 24,
                  offset: Offset(0, _hovered ? 11 : 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Now',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterWidget extends StatelessWidget {
  const _FooterWidget();

  static const Color goldYellow = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF1A1A1A);
  static const String contactPhone = '7829999976';

  Future<void> _openPhoneDialer() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: contactPhone);
    await launchUrl(phoneUri);
  }

  Future<void> _openEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto', path: 'info@papichulo.com');
    await launchUrl(emailUri);
  }

  Future<void> _openLocation() async {
    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=Hyderabad%2C%20India',
    );
    await launchUrl(mapUri);
  }

  Future<void> _showAboutUsDialog(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'About Us',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final double screenWidth = MediaQuery.of(dialogContext).size.width;
        final double dialogWidth = screenWidth > 900
            ? screenWidth * 0.5
            : screenWidth - 48;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: dialogWidth,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: goldYellow.withOpacity(0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldYellow.withOpacity(0.2),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant_menu, color: goldYellow, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'About Papichulo',
                        style: Theme.of(dialogContext).textTheme.titleLarge
                            ?.copyWith(
                              color: goldYellow,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'We are Papichulo, focused on serving fresh, tasty food with premium quality and quick service. '
                    'Our team is committed to giving you a better food experience with every order.',
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[300], height: 1.6),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: goldYellow,
                        foregroundColor: black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFaqDialog(BuildContext context) async {
    await _showAnimatedInfoDialog(
      context,
      title: 'FAQ',
      content:
          'We deliver fresh food quickly, with menu quality and customer support as top priorities.',
    );
  }

  Future<void> _showTermsDialog(BuildContext context) async {
    await _showAnimatedInfoDialog(
      context,
      title: 'Terms & Conditions',
      content:
          'Orders are prepared after confirmation. Delivery time may vary by location and traffic conditions.',
    );
  }

  Future<void> _showAnimatedInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: title,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final double screenWidth = MediaQuery.of(dialogContext).size.width;
        final double dialogWidth = screenWidth > 900
            ? screenWidth * 0.5
            : screenWidth - 48;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: dialogWidth,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: goldYellow.withOpacity(0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldYellow.withOpacity(0.2),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(dialogContext).textTheme.titleLarge
                        ?.copyWith(
                          color: goldYellow,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[300], height: 1.6),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: goldYellow,
                        foregroundColor: black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        final double screenWidth = MediaQuery.of(dialogContext).size.width;
        final double dialogWidth = screenWidth > 900
            ? screenWidth * 0.5
            : screenWidth - 48;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: dialogWidth,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: goldYellow.withOpacity(0.5),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(dialogContext).textTheme.titleLarge
                        ?.copyWith(
                          color: goldYellow,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[300], height: 1.6),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: goldYellow,
                        foregroundColor: black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterLink(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[400],
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: goldYellow, size: 20),
      ),
    );
  }

  Widget _buildPaymentMethodChip(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: goldYellow.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: goldYellow),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headingStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: goldYellow,
      fontWeight: FontWeight.bold,
    );

    final footerSections = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact', style: headingStyle),
          const SizedBox(height: 18),
          _buildFooterLink(
            context,
            label: contactPhone,
            onTap: _openPhoneDialer,
          ),
          _buildFooterLink(
            context,
            label: 'info@papichulo.com',
            onTap: _openEmail,
          ),
          _buildFooterLink(
            context,
            label: 'Hyderabad, India',
            onTap: _openLocation,
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Links', style: headingStyle),
          const SizedBox(height: 18),
          _buildFooterLink(
            context,
            label: 'About Us',
            onTap: () => _showAboutUsDialog(context),
          ),
          _buildFooterLink(
            context,
            label: 'FAQ',
            onTap: () => _showFaqDialog(context),
          ),
          _buildFooterLink(
            context,
            label: 'Terms & Conditions',
            onTap: () => _showTermsDialog(context),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Follow Us', style: headingStyle),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildFooterIcon(
                icon: Icons.facebook,
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Facebook',
                  content: 'Our Facebook page will be available soon.',
                ),
              ),
              const SizedBox(width: 12),
              _buildFooterIcon(
                icon: Icons.camera_alt,
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Instagram',
                  content: 'Our Instagram handle will be available soon.',
                ),
              ),
              const SizedBox(width: 12),
              _buildFooterIcon(
                icon: Icons.language,
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Website',
                  content:
                      'You are already on our website. More updates coming soon.',
                ),
              ),
            ],
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Methods', style: headingStyle),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildPaymentMethodChip(
                context,
                label: 'Visa',
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Payment - Visa',
                  content:
                      'Visa card payments are accepted for all online orders.',
                ),
              ),
              const SizedBox(width: 8),
              _buildPaymentMethodChip(
                context,
                label: 'MC',
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Payment - MasterCard',
                  content:
                      'MasterCard payments are accepted for all online orders.',
                ),
              ),
            ],
          ),
        ],
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [black, darkGrey],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 980) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: footerSections
                          .map((section) => Expanded(child: section))
                          .toList(growable: false),
                    );
                  }
                  return Wrap(
                    spacing: 38,
                    runSpacing: 24,
                    children: footerSections
                        .map(
                          (section) => SizedBox(
                            width: constraints.maxWidth > 560
                                ? (constraints.maxWidth - 38) / 2
                                : constraints.maxWidth,
                            child: section,
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
              const SizedBox(height: 34),
              Divider(color: goldYellow.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(
                '(c) 2024 Papichulo. All rights reserved.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
