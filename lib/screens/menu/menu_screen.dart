import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/menu_data.dart';
import '../../models/food_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/order_api_service.dart';
import '../../widgets/animated_cart_icon.dart';
import '../cart/cart_drawer.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  static const Color goldYellow = Color(0xFFF5C842);
  static const Color darkGold = Color(0xFFC8900A);
  static const Color black = Color(0xFF111111);
  static const Color cardSurface = Color(0xFF1C1C1C);

  static const List<String> _ambientFoodEmojis = <String>[
    '\u{1F355}',
    '\u{1F354}',
    '\u{1F32D}',
    '\u{1F35F}',
    '\u{1F96A}',
    '\u{1F357}',
  ];

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _titleGlowController;
  late AnimationController _skeletonShimmerController;
  late GlobalKey _cartIconKey;
  late final List<_AmbientParticleSpec> _ambientParticles;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final OrderApiService _orderApi = OrderApiService();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  _FoodTypeFilter _selectedTypeFilter = _FoodTypeFilter.all;
  _MenuSortOption _selectedSortOption = _MenuSortOption.popular;

  List<FoodItem> _menuItems = List<FoodItem>.from(papichuloMenu);
  bool _isMenuLoading = true;
  String? _menuLoadError;
  int _cardAnimationEpoch = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService().track('page_view', params: {'screen': 'menu'});

    _cartIconKey = GlobalKey();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _titleGlowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _skeletonShimmerController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    )..repeat();
    _ambientParticles = _buildAmbientParticles();

    _slideController.forward();
    _loadMenuFromApi();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _slideController.dispose();
    _titleGlowController.dispose();
    _skeletonShimmerController.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  List<_AmbientParticleSpec> _buildAmbientParticles() {
    final random = math.Random(2026);
    return List<_AmbientParticleSpec>.generate(12, (_) {
      return _AmbientParticleSpec(
        emoji: _ambientFoodEmojis[random.nextInt(_ambientFoodEmojis.length)],
        leftFactor: random.nextDouble(),
        duration: Duration(seconds: 12 + random.nextInt(9)),
        opacity: 0.04 + random.nextDouble() * 0.04,
        fontSize: 16 + random.nextDouble() * 12,
        initialProgress: random.nextDouble(),
      );
    });
  }

  List<String> get _categories {
    final values = <String>{'All'};
    for (final item in _menuItems) {
      values.add(item.category);
    }
    return values.toList();
  }

  String _categoryEmoji(String category) {
    switch (category) {
      case 'Pizza':
        return '\u{1F355}';
      case 'Burgers':
        return '\u{1F354}';
      case 'Sandwiches':
        return '\u{1F96A}';
      case 'Hot Dogs':
        return '\u{1F32D}';
      case 'Snacks':
        return '\u{1F35F}';
      default:
        return '\u{1F37D}\u{FE0F}';
    }
  }

  List<FoodItem> get _filteredItems {
    Iterable<FoodItem> items = _menuItems;
    if (_selectedCategory != 'All') {
      items = items.where((item) => item.category == _selectedCategory);
    }
    if (_selectedTypeFilter == _FoodTypeFilter.veg) {
      items = items.where((item) {
        final type = item.type.toLowerCase();
        return type.contains('veg') && !type.contains('non');
      });
    } else if (_selectedTypeFilter == _FoodTypeFilter.nonVeg) {
      items = items.where((item) => item.type.toLowerCase().contains('non'));
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

  void _selectCategory(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _cardAnimationEpoch++;
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedTypeFilter = _FoodTypeFilter.all;
      _selectedSortOption = _MenuSortOption.popular;
      _cardAnimationEpoch++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _titleGlowController,
          builder: (context, _) {
            final glow = Curves.easeInOut.transform(_titleGlowController.value);
            final shadowBlur = 20 + (20 * glow);
            final shadowAlpha = 0.3 + (0.4 * glow);
            return ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [goldYellow, darkGold],
              ).createShader(bounds),
              child: Text(
                'PAPICHULO MENU',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  shadows: [
                    Shadow(
                      color: goldYellow.withValues(alpha: shadowAlpha),
                      blurRadius: shadowBlur,
                    ),
                  ],
                ),
              ),
            );
          },
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
      backgroundColor: black,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: _AmbientParticleBackdrop(particles: _ambientParticles),
            ),
          ),
          SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_menuLoadError != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x332F2010),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0x55F5C842),
                              ),
                            ),
                            child: Text(
                              _menuLoadError!,
                              style: const TextStyle(
                                color: Color(0xFFE7C995),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        _buildFilterPanel(filteredItems.length),
                        const SizedBox(height: 10),
                        _buildResultsHeader(filteredItems.length),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _isMenuLoading
                          ? _buildSkeletonGrid()
                          : filteredItems.isEmpty
                          ? _MenuEmptyState(
                              key: ValueKey('empty-${_filterSignature()}'),
                              onClearFilters: _clearFilters,
                            )
                          : GridView.builder(
                              key: ValueKey(
                                'menu-grid-${_filterSignature()}-$_cardAnimationEpoch',
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 240,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 0.62,
                                  ),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, itemIndex) {
                                final item = filteredItems[itemIndex];
                                return _MenuItem(
                                  key: ValueKey(
                                    '${_filterSignature()}-${item.name}',
                                  ),
                                  item: item,
                                  index: itemIndex,
                                  cartProvider: context.read<CartProvider>(),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                final itemCount = cartProvider.cartService.itemCount;
                if (itemCount <= 0 || cartProvider.isCartOpen) {
                  return const SizedBox.shrink();
                }
                return _FloatingCartBar(
                  itemCount: itemCount,
                  totalAmount: cartProvider.cartService.totalAmount,
                  onTap: cartProvider.openCart,
                );
              },
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

  Widget _buildFilterPanel(int itemCount) {
    final isFocused = _searchFocusNode.hasFocus;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33F5C842)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFocused
                    ? const Color(0x66F5C842)
                    : const Color(0x33F5C842),
                width: isFocused ? 1.1 : 1,
              ),
              boxShadow: [
                if (isFocused)
                  const BoxShadow(
                    color: Color(0x14F5C842),
                    spreadRadius: 3,
                    blurRadius: 0,
                  ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search pizzas, burgers, snacks...',
                hintStyle: const TextStyle(color: Color(0x80FFFFFF)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isFocused ? goldYellow : const Color(0xB3F5C842),
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear, color: Color(0xB0FFFFFF)),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Showing $itemCount items',
            style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _buildUnifiedFilterRow(),
        ],
      ),
    );
  }

  Widget _buildUnifiedFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryPill(
                label: category,
                emoji: _categoryEmoji(category),
                isSelected: _selectedCategory == category,
                onTap: () => _selectCategory(category),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              height: 20,
              child: VerticalDivider(color: Color(0x44FFFFFF)),
            ),
          ),
          _buildTypeChip('All', _FoodTypeFilter.all),
          const SizedBox(width: 8),
          _buildTypeChip('Veg', _FoodTypeFilter.veg),
          const SizedBox(width: 8),
          _buildTypeChip('Non-Veg', _FoodTypeFilter.nonVeg),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x40F5C842)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_MenuSortOption>(
                value: _selectedSortOption,
                dropdownColor: const Color(0xFF1C1C1C),
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: goldYellow,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedSortOption = value);
                },
                items: const [
                  DropdownMenuItem(
                    value: _MenuSortOption.popular,
                    child: Text('Popularity'),
                  ),
                  DropdownMenuItem(
                    value: _MenuSortOption.priceLowToHigh,
                    child: Text('Price: Low to High'),
                  ),
                  DropdownMenuItem(
                    value: _MenuSortOption.priceHighToLow,
                    child: Text('Price: High to Low'),
                  ),
                  DropdownMenuItem(
                    value: _MenuSortOption.rating,
                    child: Text('Rating'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, _FoodTypeFilter type) {
    final isSelected = _selectedTypeFilter == type;
    final Color activeColor = switch (type) {
      _FoodTypeFilter.veg => const Color(0xFF34C759),
      _FoodTypeFilter.nonVeg => const Color(0xFFEF4444),
      _FoodTypeFilter.all => goldYellow,
    };

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTypeFilter = type),
      selectedColor: activeColor.withValues(alpha: 0.22),
      backgroundColor: const Color(0xFF111111),
      side: BorderSide(
        color: isSelected ? activeColor : const Color(0x40FFFFFF),
      ),
      checkmarkColor: activeColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (type != _FoodTypeFilter.all) ...[
            Icon(Icons.circle, size: 10, color: activeColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(int itemCount) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
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
        Text(
          _selectedCategory == 'All'
              ? 'Explore Menu'
              : 'Explore ${_selectedCategory.toUpperCase()}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Text(
          '$itemCount items',
          style: const TextStyle(
            color: Color(0xB3FFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonGrid() {
    return AnimatedBuilder(
      animation: _skeletonShimmerController,
      builder: (context, _) {
        final shimmerValue = _skeletonShimmerController.value;
        return GridView.builder(
          key: const ValueKey('menu-loading-grid'),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.62,
          ),
          itemCount: 12,
          itemBuilder: (context, index) => _SkeletonCard(
            shimmerValue: shimmerValue,
            phase: (index % 6) * 0.09,
          ),
        );
      },
    );
  }

  String _filterSignature() {
    return '$_searchQuery|$_selectedCategory|$_selectedTypeFilter|$_selectedSortOption';
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
        throw Exception(
          'Backend reachable, but no menu items found. Seed menu data (npm run prisma:seed).',
        );
      }

      if (!mounted) return;
      setState(() {
        _menuItems = liveItems;
        _isMenuLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      setState(() {
        _isMenuLoading = false;
        _menuLoadError = message.contains('no menu items found')
            ? 'Using local fallback. Backend has no menu data. Run: npm run prisma:seed'
            : 'Using local menu fallback (backend not reachable).';
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

class _AmbientParticleSpec {
  final String emoji;
  final double leftFactor;
  final Duration duration;
  final double opacity;
  final double fontSize;
  final double initialProgress;

  const _AmbientParticleSpec({
    required this.emoji,
    required this.leftFactor,
    required this.duration,
    required this.opacity,
    required this.fontSize,
    required this.initialProgress,
  });
}

class _AmbientParticleBackdrop extends StatelessWidget {
  final List<_AmbientParticleSpec> particles;

  const _AmbientParticleBackdrop({required this.particles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        return Stack(
          children: particles
              .map(
                (spec) => _AmbientParticle(
                  spec: spec,
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _AmbientParticle extends StatefulWidget {
  final _AmbientParticleSpec spec;
  final double maxWidth;
  final double maxHeight;

  const _AmbientParticle({
    required this.spec,
    required this.maxWidth,
    required this.maxHeight,
  });

  @override
  State<_AmbientParticle> createState() => _AmbientParticleState();
}

class _AmbientParticleState extends State<_AmbientParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: widget.spec.duration, vsync: this)
          ..value = widget.spec.initialProgress
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final travelDistance = widget.maxHeight + (widget.spec.fontSize * 2);
        final left =
            widget.spec.leftFactor * (widget.maxWidth - widget.spec.fontSize);

        return Positioned(
          left: left,
          bottom: -widget.spec.fontSize,
          child: Transform.translate(
            offset: Offset(0, -_controller.value * travelDistance),
            child: Opacity(
              opacity: widget.spec.opacity,
              child: Text(
                widget.spec.emoji,
                style: TextStyle(fontSize: widget.spec.fontSize),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryPill extends StatefulWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          scale: isSelected ? 1.04 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFFF5C842), Color(0xFFC8900A)],
                    )
                  : null,
              color: isSelected ? null : const Color(0xFF111111),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : const Color(0x40FFFFFF),
              ),
              boxShadow: [
                if (isSelected)
                  const BoxShadow(
                    color: Color(0x55F5C842),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: _isHovered ? (10 / 360) : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _SkeletonCard extends StatelessWidget {
  final double shimmerValue;
  final double phase;

  const _SkeletonCard({required this.shimmerValue, required this.phase});

  @override
  Widget build(BuildContext context) {
    final sweep = (shimmerValue + phase) % 1.0;
    final beginX = -1.25 + (sweep * 2.5);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(beginX - 0.8, 0),
            end: Alignment(beginX + 0.8, 0),
            colors: const [
              Color(0xFF1A1A1A),
              Color(0xFF252525),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF202020),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF202020),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 10,
                width: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    height: 20,
                    width: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 30,
                    width: 74,
                    decoration: BoxDecoration(
                      color: const Color(0xFF232323),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuEmptyState extends StatefulWidget {
  final VoidCallback onClearFilters;

  const _MenuEmptyState({super.key, required this.onClearFilters});

  @override
  State<_MenuEmptyState> createState() => _MenuEmptyStateState();
}

class _MenuEmptyStateState extends State<_MenuEmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _wobbleController;
  late final AnimationController _fadeController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _wobbleController,
              builder: (context, _) {
                final angleDeg = -5 + (10 * _wobbleController.value);
                return Transform.rotate(
                  angle: angleDeg * math.pi / 180,
                  child: const Text(
                    '\u{1F37D}\u{FE0F}',
                    style: TextStyle(fontSize: 50),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeController,
                curve: Curves.easeOut,
              ),
              child: const Text(
                'Nothing found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeController,
                curve: Curves.easeOut,
              ),
              child: Text(
                'Try another category, clear search, or switch Veg/Non-Veg.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: _isHovered ? 1.04 : 1,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onClearFilters,
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF5C842), Color(0xFFC8900A)],
                        ),
                      ),
                      child: const Text(
                        'Clear Filters',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingCartBar extends StatefulWidget {
  final int itemCount;
  final double totalAmount;
  final VoidCallback onTap;

  const _FloatingCartBar({
    required this.itemCount,
    required this.totalAmount,
    required this.onTap,
  });

  @override
  State<_FloatingCartBar> createState() => _FloatingCartBarState();
}

class _FloatingCartBarState extends State<_FloatingCartBar>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<Offset> _entryOffset;
  late final AnimationController _arrowController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _entryOffset = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
        );
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SlideTransition(
        position: _entryOffset,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: _isHovered ? 1.03 : 1.0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5C842), Color(0xFFE5AD1A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _isHovered
                            ? const Color(0x99F5C842)
                            : const Color(0x66F5C842),
                        blurRadius: _isHovered ? 26 : 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.itemCount} items  |  \u20B9${widget.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _arrowController,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(_arrowController.value * 4, 0),
                          child: child,
                        ),
                        child: const Text(
                          '\u2192',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  final FoodItem item;
  final int index;
  final CartProvider cartProvider;

  const _MenuItem({
    super.key,
    required this.item,
    required this.index,
    required this.cartProvider,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> with TickerProviderStateMixin {
  static const Color goldYellow = Color(0xFFF5C842);
  static const Color cardSurface = Color(0xFF1C1C1C);

  bool _isHovered = false;
  bool _isAddHovered = false;
  bool _showBurst = false;
  int _quantity = 0;

  Timer? _entryDelayTimer;
  late final AnimationController _entryController;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  late final AnimationController _badgePulseController;
  late final Animation<double> _badgeRingScale;
  late final Animation<double> _badgeRingFade;

  late final AnimationController _quantityPopController;
  late final Animation<double> _quantityScale;

  late final AnimationController _burstController;

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
    if (url.contains('images.unsplash.com') && !url.contains('?')) {
      return '$url?auto=format&fit=crop&w=900&q=80';
    }
    return url;
  }

  bool get _isVeg {
    final type = widget.item.type.toLowerCase();
    return type.contains('veg') && !type.contains('non');
  }

  bool get _isPopular => widget.item.rating >= 4.6;

  int _currentQuantity() {
    for (final cartItem in widget.cartProvider.cartService.items) {
      if (cartItem.foodItem.name == widget.item.name) {
        return cartItem.quantity;
      }
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _quantity = _currentQuantity();
    widget.cartProvider.cartService.addListener(_onCartChanged);

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _entryFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
        );
    final delay = Duration(milliseconds: math.min(widget.index * 40, 400));
    _entryDelayTimer = Timer(delay, () {
      if (!mounted) return;
      _entryController.forward();
    });

    _badgePulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _badgeRingScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _badgePulseController, curve: Curves.easeOut),
    );
    _badgeRingFade = Tween<double>(begin: 1.0, end: 0).animate(
      CurvedAnimation(parent: _badgePulseController, curve: Curves.easeOut),
    );
    if (_isPopular) {
      _badgePulseController.repeat();
    }

    _quantityPopController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: 1,
    );
    _quantityScale = Tween<double>(begin: 1.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _quantityPopController,
        curve: Curves.easeOutBack,
      ),
    );

    _burstController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addStatusListener(_onBurstStatusChanged);
  }

  @override
  void didUpdateWidget(covariant _MenuItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cartProvider.cartService != widget.cartProvider.cartService) {
      oldWidget.cartProvider.cartService.removeListener(_onCartChanged);
      widget.cartProvider.cartService.addListener(_onCartChanged);
      _quantity = _currentQuantity();
    }
  }

  @override
  void dispose() {
    _entryDelayTimer?.cancel();
    widget.cartProvider.cartService.removeListener(_onCartChanged);
    _entryController.dispose();
    _badgePulseController.dispose();
    _quantityPopController.dispose();
    _burstController.removeStatusListener(_onBurstStatusChanged);
    _burstController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    final next = _currentQuantity();
    if (next == _quantity || !mounted) return;
    setState(() => _quantity = next);
    if (next > 0) {
      _quantityPopController.forward(from: 0);
    }
  }

  void _onBurstStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _showBurst = false);
  }

  void _increment() {
    widget.cartProvider.cartService.addItem(widget.item);
  }

  void _decrement() {
    widget.cartProvider.cartService.updateQuantity(widget.item, _quantity - 1);
  }

  void _onAddTap() {
    final firstAdd = _quantity <= 0;
    _increment();
    if (!firstAdd) return;
    setState(() => _showBurst = true);
    _burstController.forward(from: 0);
  }

  Widget _buildCartControl() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.elasticOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            final scale = Tween<double>(begin: 0.82, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
          child: _quantity <= 0 ? _buildAddButton() : _buildQuantityStepper(),
        ),
        if (_showBurst)
          IgnorePointer(
            child: SizedBox(
              width: 120,
              height: 56,
              child: _BurstParticles(progress: _burstController),
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    return MouseRegion(
      key: const ValueKey('add-control'),
      onEnter: (_) => setState(() => _isAddHovered = true),
      onExit: (_) => setState(() => _isAddHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: _onAddTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [Color(0xFFF5C842), Color(0xFFC8900A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _isAddHovered
                      ? const Color(0x88F5C842)
                      : const Color(0x33F5C842),
                  blurRadius: _isAddHovered ? 24 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Text(
              'Add',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityStepper() {
    return Container(
      key: const ValueKey('qty-control'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x55F5C842)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperActionButton(icon: Icons.remove, onPressed: _decrement),
          SizedBox(
            width: 26,
            child: Center(
              child: ScaleTransition(
                scale: _quantityScale,
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          _StepperActionButton(icon: Icons.add, onPressed: _increment),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return AnimatedScale(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      scale: _isHovered ? 1.1 : 1.0,
      child: widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty
          ? Image.network(
              _optimizedImageUrl(widget.item.imageUrl!),
              fit: BoxFit.cover,
              cacheHeight: kIsWeb ? null : 220,
              cacheWidth: kIsWeb ? null : 360,
              filterQuality: FilterQuality.low,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Image.asset(
                  _fallbackAssetForCategory(widget.item.category),
                  fit: BoxFit.cover,
                );
              },
              errorBuilder: (context, error, stackTrace) => Image.asset(
                _fallbackAssetForCategory(widget.item.category),
                fit: BoxFit.cover,
              ),
            )
          : Image.asset(
              _fallbackAssetForCategory(widget.item.category),
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildPopularBadge() {
    return Positioned(
      top: 10,
      left: 10,
      child: SizedBox(
        width: 98,
        height: 28,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            FadeTransition(
              opacity: _badgeRingFade,
              child: ScaleTransition(
                scale: _badgeRingScale,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x99F5C842)),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF5A430F),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x99F5C842)),
              ),
              child: const Text(
                '\u{1F525} Popular',
                style: TextStyle(
                  color: goldYellow,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Space Mono',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoverScale = _isHovered ? 1.02 : 1.0;
    final hoverDy = _isHovered ? -6.0 : 0.0;
    final hoverTransform = Matrix4.diagonal3Values(hoverScale, hoverScale, 1)
      ..setTranslationRaw(0, hoverDy, 0);

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() {
            _isHovered = false;
            _isAddHovered = false;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            transform: hoverTransform,
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? const Color(0x66F5C842)
                    : const Color(0xFF2A2A2A),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isHovered ? 0.6 : 0.28,
                  ),
                  blurRadius: _isHovered ? 50 : 14,
                  offset: Offset(0, _isHovered ? 20 : 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: _buildImage(),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_isPopular) _buildPopularBadge(),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _VegNonVegIndicator(isVeg: _isVeg),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
                              widget.item.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFD4D4D4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnimatedScale(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              scale: _isHovered ? 1.05 : 1.0,
                              child: Text(
                                '\u20B9${widget.item.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: goldYellow,
                                ),
                              ),
                            ),
                            _buildCartControl(),
                          ],
                        ),
                      ],
                    ),
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

class _BurstParticles extends StatelessWidget {
  final Animation<double> progress;

  const _BurstParticles({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = Curves.easeOut.transform(progress.value);
        final alpha = 1 - progress.value;
        return Stack(
          alignment: Alignment.center,
          children: List<Widget>.generate(8, (index) {
            final angle = (math.pi * 2 / 8) * index;
            final distance = 34 * t;
            return Transform.translate(
              offset: Offset(
                math.cos(angle) * distance,
                math.sin(angle) * distance,
              ),
              child: Opacity(
                opacity: alpha,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index.isEven
                        ? const Color(0xFFF5C842)
                        : Colors.white,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _VegNonVegIndicator extends StatelessWidget {
  final bool isVeg;

  const _VegNonVegIndicator({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _StepperActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _StepperActionButton({required this.icon, required this.onPressed});

  @override
  State<_StepperActionButton> createState() => _StepperActionButtonState();
}

class _StepperActionButtonState extends State<_StepperActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onPressed,
        onHighlightChanged: (value) => setState(() => _isPressed = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _isPressed ? const Color(0x26F5C842) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, color: const Color(0xFFF5C842), size: 15),
        ),
      ),
    );
  }
}
