import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/menu_data.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/fly_to_cart_button.dart';
import '../../widgets/animated_cart_icon.dart';
import '../cart/cart_drawer.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  static const Color goldYellow = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF1A1A1A);
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late GlobalKey _cartIconKey;

  @override
  void initState() {
    super.initState();
    _cartIconKey = GlobalKey();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const categories = ['Pizza', 'Burgers', 'Sandwiches', 'Hot Dogs', 'Snacks'];

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [goldYellow, darkGold],
          ).createShader(bounds),
          child: const Text(
            'Papichulo Menu',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: black,
        foregroundColor: goldYellow,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedCartIcon(
              key: _cartIconKey,
              onCartTap: () => context.read<CartProvider>().openCart(),
              isCompact: true,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categories.map((category) {
                      final items = papichuloMenu.where((item) => item.category == category).toList();
                      if (items.isEmpty) return const SizedBox.shrink();
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [goldYellow, darkGold]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: goldYellow.withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, itemIndex) {
                                final item = items[itemIndex];
                                return _MenuItem(
                                  item: item,
                                  cartProvider: context.read<CartProvider>(),
                                  cartIconKey: _cartIconKey,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
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

}

class _MenuItem extends StatefulWidget {
  final item;
  final CartProvider cartProvider;
  final GlobalKey cartIconKey;

  _MenuItem({
    required this.item,
    required this.cartProvider,
    required this.cartIconKey,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> with SingleTickerProviderStateMixin {
  static const Color goldYellow = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color black = Color(0xFF000000);
  
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
        decoration: BoxDecoration(
          gradient: _isHovered
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, goldYellow.withOpacity(0.1)],
                )
              : null,
          color: _isHovered ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? goldYellow : Colors.grey[200]!,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? goldYellow.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: _isHovered ? 15 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [goldYellow.withOpacity(0.1), Colors.transparent],
                  ),
                ),
                child: widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty
                    ? Image.network(
                        widget.item.imageUrl!,
                        fit: BoxFit.cover,
                        cacheHeight: 130,
                        cacheWidth: 220,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [darkGold, goldYellow],
                          ).createShader(bounds),
                          child: Text(
                            '₹${widget.item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        FlyToCartButton(
                          item: widget.item,
                          cartIconKey: widget.cartIconKey,
                          isCompact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
