import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../data/menu_data.dart';
import '../../models/food_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/order_api_service.dart';
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
  final OrderApiService _orderApi = OrderApiService();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  _FoodTypeFilter _selectedTypeFilter = _FoodTypeFilter.all;
  _MenuSortOption _selectedSortOption = _MenuSortOption.popular;
  List<FoodItem> _menuItems = List<FoodItem>.from(papichuloMenu);
  bool _isMenuLoading = true;
  String? _menuLoadError;

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
    _loadMenuFromApi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final values = <String>{'All'};
    for (final item in _menuItems) {
      values.add(item.category);
    }
    return values.toList();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Pizza':
        return Icons.local_pizza_outlined;
      case 'Burgers':
        return Icons.lunch_dining_outlined;
      case 'Sandwiches':
        return Icons.breakfast_dining_outlined;
      case 'Hot Dogs':
        return Icons.hot_tub_outlined;
      case 'Snacks':
        return Icons.fastfood_outlined;
      default:
        return Icons.grid_view_rounded;
    }
  }

  List<FoodItem> get _filteredItems {
    Iterable<FoodItem> items = _menuItems;

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
                      if (_isMenuLoading) ...[
                        const LinearProgressIndicator(minHeight: 2),
                        const SizedBox(height: 8),
                      ],
                      if (_menuLoadError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5E8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFD9A3)),
                          ),
                          child: Text(
                            _menuLoadError!,
                            style: const TextStyle(
                              color: Color(0xFF7B4A00),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildFilterPanel(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                colors: [goldYellow, darkGold],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                const TextSpan(
                                  text: 'Explore ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                                TextSpan(
                                  text: _selectedCategory.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                              ],
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
                                childAspectRatio: 0.68,
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _categoryIcon(category),
                          size: 14,
                          color: isSelected ? Colors.black : Colors.black87,
                        ),
                        const SizedBox(width: 6),
                        Text(category),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
                    selectedColor: goldYellow,
                    backgroundColor: const Color(0xFFF7F7F7),
                    checkmarkColor: Colors.black87,
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return goldYellow;
                      }
                      return const Color(0xFFF7F7F7);
                    }),
                    side: BorderSide(
                      color: isSelected ? goldYellow : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
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
    final Color selectedFill;
    final Color selectedBorder;
    final Color selectedText;

    switch (type) {
      case _FoodTypeFilter.veg:
        selectedFill = const Color(0xFFDFF7E8);
        selectedBorder = const Color(0xFF34C759);
        selectedText = const Color(0xFF1F7A3D);
        break;
      case _FoodTypeFilter.nonVeg:
        selectedFill = const Color(0xFFFFE1E1);
        selectedBorder = const Color(0xFFE65353);
        selectedText = const Color(0xFF9A1F1F);
        break;
      case _FoodTypeFilter.all:
        selectedFill = const Color(0xFFFFE07A);
        selectedBorder = goldYellow;
        selectedText = Colors.black87;
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _selectedTypeFilter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedFill : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? selectedBorder : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBorder.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 16, color: selectedText),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedText : Colors.black87,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMenuFromApi() async {
    setState(() {
      _isMenuLoading = true;
      _menuLoadError = null;
    });
    try {
      final menu = await _orderApi.fetchMenu();
      final liveItems = menu
          .map(_mapMenuItem)
          .whereType<FoodItem>()
          .toList(growable: false);

      if (liveItems.isEmpty) {
        throw Exception('No menu items returned from server.');
      }

      if (!mounted) return;
      setState(() {
        _menuItems = liveItems;
        _isMenuLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        // Keep local menu fallback if API is unavailable.
        _isMenuLoading = false;
        _menuLoadError = 'Using local menu fallback (backend not reachable).';
      });
    }
  }

  FoodItem? _mapMenuItem(Map<String, dynamic> raw) {
    final available = raw['available'];
    if (available is bool && !available) return null;

    final name = (raw['name'] ?? '').toString().trim();
    final category = (raw['category'] ?? '').toString().trim();
    final type = (raw['type'] ?? '').toString().trim();
    if (name.isEmpty || category.isEmpty || type.isEmpty) return null;

    final ingredientsRaw = raw['ingredients'];
    final ingredients = ingredientsRaw is List
        ? ingredientsRaw
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];

    return FoodItem(
      name: name,
      category: category,
      type: type,
      ingredients: ingredients.isEmpty
          ? const ['Fresh ingredients']
          : ingredients,
      imageUrl: (raw['imageUrl'] ?? '').toString().trim().isEmpty
          ? null
          : (raw['imageUrl'] as String).trim(),
      price: (raw['price'] as num?)?.toDouble() ?? 0,
      rating: (raw['rating'] as num?)?.toDouble() ?? 4.5,
    );
  }
}

enum _FoodTypeFilter { all, veg, nonVeg }

enum _MenuSortOption { popular, rating, priceLowToHigh, priceHighToLow }

class _MenuItem extends StatefulWidget {
  final FoodItem item;
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
  static const Color cardSurface = Color(0xFF1A1A1A);

  bool _isHovered = false;

  String _fallbackAssetForCategory(String category) {
    switch (category) {
      case 'Pizza':
        return 'assets/images/Pizza.jpeg';
      case 'Burgers':
        return 'assets/images/Burger.jpeg';
      case 'Snacks':
      case 'Hot Dogs':
      case 'Sandwiches':
      default:
        return 'assets/images/Nuggets.jpeg';
    }
  }

  String _optimizedImageUrl(String url) {
    // Unsplash originals are heavy. This keeps cards fast and avoids blank paint on web.
    if (url.contains('images.unsplash.com') && !url.contains('?')) {
      return '$url?auto=format&fit=crop&w=900&q=80';
    }
    return url;
  }

  ({String label, Color color}) _primaryBadge() {
    if (widget.item.rating >= 4.6) {
      return (label: 'Bestseller', color: const Color(0xFFFFD54F));
    }
    if (widget.item.name.toLowerCase().contains('spicy')) {
      return (label: 'Spicy', color: const Color(0xFFFF8A65));
    }
    if (widget.item.rating >= 4.4) {
      return (label: 'Trending', color: const Color(0xFFFFB74D));
    }
    return (label: 'New', color: const Color(0xFF81C784));
  }

  int _ratingCount() {
    final hash = widget.item.name.codeUnits.fold<int>(0, (a, b) => a + b);
    return 120 + (hash % 260);
  }

  bool get _isVeg => widget.item.type.toLowerCase() == 'veg';

  @override
  Widget build(BuildContext context) {
    final badge = _primaryBadge();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        decoration: BoxDecoration(
          color: cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered ? goldYellow : const Color(0xFF2A2A2A),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? goldYellow.withValues(alpha: 0.28)
                  : Colors.black.withValues(alpha: 0.18),
              blurRadius: _isHovered ? 18 : 10,
              spreadRadius: _isHovered ? 1 : 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge.label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isVeg
                      ? const Color(0xFF1F7A3D)
                      : const Color(0xFF9A1F1F),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _isVeg ? 'Veg' : 'Non-Veg',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: SizedBox(
                    height: 122,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 250),
                          scale: _isHovered ? 1.06 : 1.0,
                          child:
                              widget.item.imageUrl != null &&
                                  widget.item.imageUrl!.isNotEmpty
                              ? Image.network(
                                  _optimizedImageUrl(widget.item.imageUrl!),
                                  fit: BoxFit.cover,
                                  cacheHeight: kIsWeb ? null : 130,
                                  cacheWidth: kIsWeb ? null : 220,
                                  filterQuality: FilterQuality.low,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) {
                                      return child;
                                    }
                                    return Image.asset(
                                      _fallbackAssetForCategory(
                                        widget.item.category,
                                      ),
                                      fit: BoxFit.cover,
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    _fallbackAssetForCategory(
                                      widget.item.category,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(
                                  _fallbackAssetForCategory(widget.item.category),
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.48),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: goldYellow,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.item.rating.toStringAsFixed(1)} (${_ratingCount()})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFD4D4D4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.item.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Only',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [darkGold, goldYellow],
                                  ).createShader(bounds),
                                  child: Text(
                                    '\u20B9${widget.item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: _isHovered
                                    ? [
                                        BoxShadow(
                                          color: goldYellow.withValues(alpha: 0.35),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: FlyToCartButton(
                                item: widget.item,
                                cartIconKey: widget.cartIconKey,
                                isCompact: true,
                              ),
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
