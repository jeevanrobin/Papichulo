import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/menu_data.dart';
import '../../models/food_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/analytics_service.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  _FoodTypeFilter _selectedTypeFilter = _FoodTypeFilter.all;
  _MenuSortOption _selectedSortOption = _MenuSortOption.popular;

  @override
  void initState() {
    super.initState();
    AnalyticsService().track('page_view', params: {'screen': 'menu'});
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
    _searchController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final values = <String>{'All'};
    for (final item in papichuloMenu) {
      values.add(item.category);
    }
    return values.toList();
  }

  List<FoodItem> get _filteredItems {
    Iterable<FoodItem> items = papichuloMenu;

    if (_selectedCategory != 'All') {
      items = items.where((item) => item.category == _selectedCategory);
    }
    if (_selectedTypeFilter == _FoodTypeFilter.veg) {
      items = items.where((item) => item.type.toLowerCase() == 'veg');
    } else if (_selectedTypeFilter == _FoodTypeFilter.nonVeg) {
      items = items.where((item) => item.type.toLowerCase() == 'non-veg');
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((item) {
        final ingredients = item.ingredients.join(' ').toLowerCase();
        return item.name.toLowerCase().contains(q) ||
            item.category.toLowerCase().contains(q) ||
            ingredients.contains(q);
      });
    }

    final list = items.toList();
    switch (_selectedSortOption) {
      case _MenuSortOption.popular:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _MenuSortOption.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _MenuSortOption.priceLowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _MenuSortOption.priceHighToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [goldYellow, darkGold],
          ).createShader(bounds),
          child: const Text(
            'Papichulo Menu',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DottedPatternPainter(
                  dotColor: Colors.black.withOpacity(0.03),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 14,
            left: 12,
            child: _DecorCircle(size: 34, color: Color(0x22FFD700)),
          ),
          const Positioned(
            top: 76,
            right: 18,
            child: _DecorSquiggle(color: Color(0x448B5E00)),
          ),
          SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterPanel(),
                      const SizedBox(height: 20),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [goldYellow, darkGold],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: goldYellow.withOpacity(0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              '${_selectedCategory.toUpperCase()} MENU',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const Positioned(
                            right: -12,
                            top: -8,
                            child: _DecorCircle(
                              size: 14,
                              color: Color(0x33FFD700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (filteredItems.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          alignment: Alignment.center,
                          child: const Text(
                            'No items match your filters',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, itemIndex) {
                            final item = filteredItems[itemIndex];
                            return _MenuItem(
                              item: item,
                              cartProvider: context.read<CartProvider>(),
                              cartIconKey: _cartIconKey,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              if (!cartProvider.isCartOpen) return const SizedBox();
              final drawerWidth = MediaQuery.of(context).size.width >= 450
                  ? 420.0
                  : MediaQuery.of(context).size.width;
              return Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                left: 0,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => cartProvider.closeCart(),
                              child: Container(color: Colors.black54),
                            ),
                          ),
                          SizedBox(width: drawerWidth),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      width: drawerWidth,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF121212),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: CartDrawer(
                            cartService: cartProvider.cartService,
                            onClose: () => cartProvider.closeCart(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search menu...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
                    selectedColor: goldYellow,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildTypeFilterChip('All', _FoodTypeFilter.all),
                    _buildTypeFilterChip('Veg', _FoodTypeFilter.veg),
                    _buildTypeFilterChip('Non-Veg', _FoodTypeFilter.nonVeg),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<_MenuSortOption>(
                value: _selectedSortOption,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedSortOption = value);
                },
                items: const [
                  DropdownMenuItem(
                    value: _MenuSortOption.popular,
                    child: Text('Sort: Popular'),
                  ),
                  DropdownMenuItem(
                    value: _MenuSortOption.rating,
                    child: Text('Sort: Rating'),
                  ),
                  DropdownMenuItem(
                    value: _MenuSortOption.priceLowToHigh,
                    child: Text('Sort: Price Low'),
                  ),
                  DropdownMenuItem(
                    value: _MenuSortOption.priceHighToLow,
                    child: Text('Sort: Price High'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(String label, _FoodTypeFilter type) {
    final isSelected = _selectedTypeFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTypeFilter = type),
      selectedColor: goldYellow.withOpacity(0.22),
      side: BorderSide(color: isSelected ? goldYellow : Colors.grey.shade300),
      labelStyle: TextStyle(
        color: Colors.black87,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

enum _FoodTypeFilter { all, veg, nonVeg }

enum _MenuSortOption { popular, rating, priceLowToHigh, priceHighToLow }

class _MenuItem extends StatefulWidget {
  final dynamic item;
  final CartProvider cartProvider;
  final GlobalKey cartIconKey;

  const _MenuItem({
    required this.item,
    required this.cartProvider,
    required this.cartIconKey,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  static const Color goldYellow = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFB8860B);

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
        child: Stack(
          children: [
            const Positioned(
              top: 8,
              right: 8,
              child: _DecorCircle(size: 10, color: Color(0x22FFD700)),
            ),
            const Positioned(
              top: 18,
              right: 24,
              child: _DecorCircle(size: 6, color: Color(0x228B5E00)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          goldYellow.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child:
                        widget.item.imageUrl != null &&
                            widget.item.imageUrl!.isNotEmpty
                        ? Image.network(
                            widget.item.imageUrl!,
                            fit: BoxFit.cover,
                            cacheHeight: 130,
                            cacheWidth: 220,
                            filterQuality: FilterQuality.low,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.fastfood,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.fastfood,
                              size: 40,
                              color: Colors.grey,
                            ),
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
          ],
        ),
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DecorSquiggle extends StatelessWidget {
  final Color color;

  const _DecorSquiggle({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SquigglePainter(color: color),
      size: const Size(36, 18),
    );
  }
}

class _SquigglePainter extends CustomPainter {
  final Color color;

  _SquigglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.2,
        0,
        size.width * 0.4,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height,
        size.width * 0.8,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.1,
        size.width,
        size.height * 0.5,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DottedPatternPainter extends CustomPainter {
  final Color dotColor;

  _DottedPatternPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    const spacing = 28.0;
    const radius = 1.2;

    for (double x = 10; x < size.width; x += spacing) {
      for (double y = 10; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
