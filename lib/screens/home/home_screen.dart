import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/menu_data.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/fly_to_cart_button.dart';
import '../../widgets/animated_cart_icon.dart';
import '../../services/address_service.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_api_service.dart';
import '../../services/order_alert_service.dart';
import '../cart/cart_drawer.dart';
import '../auth/auth_sidebar.dart';
import '../../providers/cart_provider.dart';
import 'home_footer.dart';
import 'home_header_widgets.dart';
import 'location_picker_sheet.dart';
import '../../models/saved_address.dart';

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
  final AddressService _addressService = AddressService.instance;
  late final VoidCallback _addressListener;
  final OrderApiService _orderApi = OrderApiService();
  String _headerLocationLabel = 'Detecting location...';
  bool _isHeaderLocationLoading = false;
  static const String _guestDisplayName = 'Guest';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTop = false;
  String _searchQuery = '';
  bool _isSearchFocused = false;

  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Pizza',
    'Burgers',
    'Sandwiches',
    'Hot Dogs',
    'Snacks',
    'Specials',
  ];
  final Map<String, IconData> _categoryIcons = const {
    'All': Icons.dinner_dining_outlined,
    'Pizza': Icons.local_pizza_outlined,
    'Burgers': Icons.lunch_dining_outlined,
    'Sandwiches': Icons.breakfast_dining_outlined,
    'Hot Dogs': Icons.restaurant_menu_outlined,
    'Snacks': Icons.local_cafe_outlined,
    'Specials': Icons.auto_awesome_outlined,
  };

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
    _addressListener = _handleAddressChange;
    _addressService.addListener(_addressListener);
    _initHeaderLocation();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showScrollTop) setState(() => _showScrollTop = show);
    });
  }

  void _startAnimations() async {
    _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _heroController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _cardController.forward();
  }

  Future<void> _initHeaderLocation() async {
    await _addressService.loadAddresses();
    if (!mounted) return;
    final saved = _addressService.selectedAddress;
    if (saved != null) {
      setState(() => _headerLocationLabel = _formatSavedLabel(saved));
      return;
    }
    _detectHeaderLocation();
  }

  void _handleAddressChange() {
    if (!mounted) return;
    final saved = _addressService.selectedAddress;
    setState(() {
      _headerLocationLabel =
          saved != null ? _formatSavedLabel(saved) : 'Set location';
    });
  }

  String _formatSavedLabel(SavedAddress address) {
    final prefix = address.label.isNotEmpty ? '${address.label} - ' : '';
    return '$prefix${address.address}';
  }

  Future<void> _detectHeaderLocation() async {
    if (_isHeaderLocationLoading) return;
    if (_addressService.selectedAddress != null) {
      setState(() {
        _headerLocationLabel =
            _formatSavedLabel(_addressService.selectedAddress!);
        _isHeaderLocationLoading = false;
      });
      return;
    }
    setState(() => _isHeaderLocationLoading = true);

    var nextLabel = _headerLocationLabel;
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        throw Exception('Location services disabled');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      nextLabel = await _orderApi.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      if (_headerLocationLabel == 'Detecting location...') {
        nextLabel = 'Set location';
      }
    }

    if (!mounted) return;
    setState(() {
      _isHeaderLocationLoading = false;
      _headerLocationLabel = nextLabel.trim().isEmpty
          ? 'Set location'
          : nextLabel;
    });
  }

  Future<void> _openLocationPicker() async {
    final result = await showModalBottomSheet<LocationPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationPickerSheet(),
    );
    if (!mounted || result == null) return;
    final saved = result.savedAddressId != null
        ? _addressService.getById(result.savedAddressId!)
        : null;
    setState(() {
      _headerLocationLabel =
          saved != null ? _formatSavedLabel(saved) : result.label;
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _heroController.dispose();
    _cardController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _addressService.removeListener(_addressListener);
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
              child: Column(
                children: [
                  _buildPromoStrip(),
                  _buildAnimatedHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildAnimatedHeroSection(),
                          _buildCategoryNav(),
                          _buildAnimatedFeaturedItems(),
                          const HomeFooter(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              if (!cartProvider.isCartOpen) return const SizedBox();
              final drawerWidth = _getCartWidth(context);
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
          // Scroll-to-top FAB
          Positioned(
            bottom: 24,
            right: 24,
            child: AnimatedOpacity(
              opacity: _showScrollTop ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showScrollTop,
                child: GestureDetector(
                  onTap: () => _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF5C842), Color(0xFFC8900A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF5C842).withOpacity(0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.black,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1500), Color(0xFF2A2000), Color(0xFF1A1500)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(bottom: BorderSide(color: Color(0x2AF5C842))),
      ),
      child: Text(
        'FREE DELIVERY on your first order | Use code PAPIFIRST',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: goldYellow,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerSlide,
      builder: (context, child) {
        final showHeaderLocation = MediaQuery.of(context).size.width >= 1060;
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
                  Row(
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
                      if (showHeaderLocation) ...[
                        const SizedBox(width: 20),
                        HomeLocationChip(
                          label: _headerLocationLabel,
                          isLoading: _isHeaderLocationLoading,
                          onTap: _openLocationPicker,
                        ),
                      ],
                    ],
                  ),
                  Consumer<AuthService>(
                    builder: (context, auth, _) {
                      return Row(
                        children: [
                          if (!auth.isAuthenticated) ...[
                            _buildAnimatedNavItem(
                              'Menu',
                              () => context.push('/menu'),
                            ),
                            const SizedBox(width: 20),
                            _buildAnimatedNavItem(
                              'Login',
                              () => _showAuthDialog(),
                            ),
                            const SizedBox(width: 20),
                            _buildThemeToggle(),
                            const SizedBox(width: 12),
                            _buildAnimatedCartIcon(),
                          ] else if (auth.isAdmin) ...[
                            _buildAnimatedNavItem(
                              'Dashboard',
                              () => context.go('/admin/dashboard'),
                            ),
                            const SizedBox(width: 20),
                            _buildAnimatedNavItem(
                              'Orders',
                              _openAdminOrders,
                              badgeCountListenable: OrderAlertService
                                  .instance
                                  .pendingNewOrderCount,
                            ),
                            const SizedBox(width: 20),
                            _buildAnimatedNavItem(
                              'Menu Management',
                              () => context.go('/admin/menu'),
                            ),
                            const SizedBox(width: 20),
                            _buildAnimatedNavItem('Logout', () {
                              _handleProfileMenuSelection(
                                ProfileMenuAction.logout,
                              );
                            }),
                            const SizedBox(width: 20),
                            _buildThemeToggle(),
                            const SizedBox(width: 12),
                            _buildAnimatedCartIcon(),
                            const SizedBox(width: 20),
                            _buildHeaderCTA(),
                          ] else ...[
                            _buildAnimatedNavItem(
                              'Menu',
                              () => context.push('/menu'),
                            ),
                            const SizedBox(width: 20),
                            _buildAnimatedNavItem(
                              'My Orders',
                              () => context.push('/orders'),
                            ),
                            const SizedBox(width: 20),
                            _buildUserProfileMenu(),
                            const SizedBox(width: 20),
                            _buildThemeToggle(),
                            const SizedBox(width: 12),
                            _buildAnimatedCartIcon(),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedNavItem(
    String text,
    VoidCallback onTap, {
    ValueListenable<int>? badgeCountListenable,
  }) {
    if (badgeCountListenable == null) {
      return HomeNavItem(text: text, onTap: onTap);
    }
    return ValueListenableBuilder<int>(
      valueListenable: badgeCountListenable,
      builder: (context, pendingCount, _) {
        return HomeNavItem(
          text: text,
          onTap: onTap,
          badgeCount: pendingCount,
        );
      },
    );
  }

  Widget _buildAnimatedCartIcon() {
    return AnimatedCartIcon(
      key: _cartIconKey,
      onCartTap: () => context.read<CartProvider>().openCart(),
    );
  }

  Widget _buildThemeToggle() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return GestureDetector(
          onTap: () => themeProvider.toggle(),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              themeProvider.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              key: ValueKey(themeProvider.isDark),
              color: goldYellow,
              size: 22,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCTA() {
    return HomeHeaderCTA(onTap: () => context.push('/menu'));
  }

  void _openAdminOrders() {
    final auth = context.read<AuthService>();
    final canOpen = auth.isAdmin;
    if (canOpen) {
      context.go('/admin/orders');
      return;
    }
    _showAuthDialog(adminRequired: true);
  }

  Future<void> _handleProfileMenuSelection(ProfileMenuAction action) async {
    final auth = context.read<AuthService>();
    switch (action) {
      case ProfileMenuAction.login:
        _showAuthDialog();
        break;
      case ProfileMenuAction.signup:
        _showAuthDialog(startWithSignup: true);
        break;
      case ProfileMenuAction.profile:
        if (!auth.isAuthenticated) {
          _showAuthDialog();
          return;
        }
        context.push('/profile');
        break;
      case ProfileMenuAction.orders:
        if (!auth.isAuthenticated) {
          _showAuthDialog();
          return;
        }
        context.push('/orders');
        break;
      case ProfileMenuAction.membership:
        _showUserInfoDialog(
          title: 'Papichulo One',
          message:
              'Membership benefits (free delivery and member deals) will be available in the next release.',
        );
        break;
      case ProfileMenuAction.favourites:
        _showUserInfoDialog(
          title: 'Favourites',
          message:
              'Save your favourite items for one-tap reorder. This section will be enabled soon.',
        );
        break;
      case ProfileMenuAction.logout:
        context.read<CartProvider>().cartService.clearCart();
        await auth.logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have been logged out.'),
            backgroundColor: Colors.black87,
          ),
        );
        break;
    }
  }

  Future<void> _showAuthDialog({
    bool startWithSignup = false,
    bool adminRequired = false,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => const AuthSidebar(),
    );
    if (adminRequired && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login with OTP to access admin routes.'),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  void _showUserInfoDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: goldYellow,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(color: Colors.grey[200], height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close', style: TextStyle(color: goldYellow)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserProfileMenu() {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final userName = auth.user?.name.trim().isNotEmpty == true
            ? auth.user!.name
            : _guestDisplayName;
        return PopupMenuButton<ProfileMenuAction>(
          tooltip: 'User profile',
          onSelected: _handleProfileMenuSelection,
          offset: const Offset(0, 48),
          elevation: 16,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) {
            if (!auth.isAuthenticated) {
              return const [
                PopupMenuItem(
                  value: ProfileMenuAction.login,
                  child: ProfileMenuEntry(label: 'Login'),
                ),
                PopupMenuItem(
                  value: ProfileMenuAction.signup,
                  child: ProfileMenuEntry(label: 'Create Account'),
                ),
              ];
            }
            return const [
              PopupMenuItem(
                value: ProfileMenuAction.profile,
                child: ProfileMenuEntry(label: 'Profile'),
              ),
              PopupMenuItem(
                value: ProfileMenuAction.orders,
                child: ProfileMenuEntry(label: 'Orders'),
              ),
              PopupMenuItem(
                value: ProfileMenuAction.membership,
                child: ProfileMenuEntry(label: 'Papichulo One'),
              ),
              PopupMenuItem(
                value: ProfileMenuAction.favourites,
                child: ProfileMenuEntry(label: 'Favourites'),
              ),
              PopupMenuItem(
                value: ProfileMenuAction.logout,
                child: ProfileMenuEntry(label: 'Logout'),
              ),
            ];
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: goldYellow.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: Color(0xFFFF7A00),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$userName ...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFFF7A00),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF7A00)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedHeroSection() {
    return AnimatedBuilder(
      animation: _heroFade,
      builder: (context, child) {
        final isDesktop = MediaQuery.of(context).size.width > 980;
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
                    vertical: MediaQuery.of(context).size.width > 768 ? 62 : 34,
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
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 6, child: _buildHeroContent()),
                            const SizedBox(width: 32),
                            Expanded(flex: 5, child: _buildHeroMediaPanel()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroContent(),
                            const SizedBox(height: 20),
                            _buildHeroMediaPanel(compact: true),
                          ],
                        ),
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
        const SizedBox(height: 20),
        _buildHeroSearchBar(),
        const SizedBox(height: 20),
        _buildPrimaryCTA(),
        const SizedBox(height: 14),
        _buildHeroStatsRow(),
      ],
    );
  }

  Widget _buildHeroSearchBar() {
    return Focus(
      onFocusChange: (hasFocus) {
        if (_isSearchFocused == hasFocus) return;
        setState(() => _isSearchFocused = hasFocus);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          color: _isSearchFocused
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isSearchFocused
                ? goldYellow.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.13),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.white),
                cursorColor: goldYellow,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search pizzas, burgers, snacks...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (_searchQuery.trim().isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                splashRadius: 16,
                tooltip: 'Clear search',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStatsRow() {
    const stats = <Map<String, String>>[
      {'value': '500+', 'label': 'Happy Orders'},
      {'value': '4.8', 'label': 'Avg Rating'},
      {'value': '30m', 'label': 'Avg Delivery'},
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 10,
      children: stats
          .map((stat) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat['value']!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: goldYellow,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  stat['label']!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildHeroMediaPanel({bool compact = false}) {
    final filtered = _getFilteredHomeItems();
    final spotlight = filtered.isNotEmpty
        ? filtered.first
        : (List.of(
            papichuloMenu,
          )..sort((a, b) => b.rating.compareTo(a.rating))).first;

    final imageUrl = spotlight.imageUrl;
    return Container(
      height: compact ? 220 : 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: goldYellow.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
                          color: Color(0xFF121212),
                          child: Center(
                            child: Icon(
                              Icons.fastfood,
                              color: Colors.grey,
                              size: 48,
                            ),
                          ),
                        ),
                  )
                : const ColoredBox(
                    color: Color(0xFF121212),
                    child: Center(
                      child: Icon(Icons.fastfood, color: Colors.grey, size: 48),
                    ),
                  ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.48),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: goldYellow.withValues(alpha: 0.35)),
              ),
              child: Text(
                'TODAY SPECIAL',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: goldYellow,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: goldYellow.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    spotlight.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '20% off on selected picks',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: goldYellow),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _getFilteredHomeItems() {
    final query = _searchQuery.trim().toLowerCase();
    return papichuloMenu.where((item) {
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;

      final searchable =
          '${item.name} ${item.category} ${item.ingredients.join(' ')}'
              .toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  Widget _buildPrimaryCTA() {
    return HomePrimaryCTA(onTap: () => context.push('/menu'));
  }

  String _selectedCategoryLabelForSubtitle() {
    if (_selectedCategory == 'All') return 'all categories';
    return _selectedCategory.toUpperCase();
  }

  String? _badgeForItem(dynamic item) {
    if (item.rating >= 4.7) return 'Bestseller';
    if (item.name.toLowerCase().contains('spicy')) return 'Spicy';
    if (item.rating >= 4.5) return 'New';
    return null;
  }

  Widget _buildFoodBadge(String badge) {
    Color color = goldYellow;
    if (badge == 'Spicy') color = const Color(0xFFEF4444);
    if (badge == 'New') color = const Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        badge,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCategoryNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: _categories.map((category) {
              final isActive = _selectedCategory == category;
              final icon = _categoryIcons[category] ?? Icons.fastfood_outlined;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [Color(0xFFFFE168), Color(0xFFFFD700)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isActive ? null : Colors.transparent,
                        border: Border.all(
                          color: isActive
                              ? goldYellow
                              : Colors.white.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isActive
                                ? Colors.black
                                : Colors.white.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            category,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isActive
                                      ? Colors.black
                                      : Colors.white.withValues(alpha: 0.9),
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                          ),
                        ],
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
    final filteredItems = _getFilteredHomeItems();
    final visibleItems = filteredItems.take(6).toList();
    final hasSearch = _searchQuery.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          Text(
            hasSearch
                ? 'Results for "${_searchQuery.trim()}"'
                : 'Popular Right Now',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Top picks from ${_selectedCategoryLabelForSubtitle()} | ${filteredItems.length} items',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.62),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (visibleItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                hasSearch
                    ? 'No items found for "${_searchQuery.trim()}"'
                    : 'No items in this category',
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
                    children: List.generate(visibleItems.length, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildPremiumFoodCard(
                            visibleItems[index],
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
                  children: List.generate(visibleItems.length, (index) {
                    return SizedBox(
                      width: constraints.maxWidth > 760
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth,
                      child: _buildPremiumFoodCard(visibleItems[index], index),
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
    final badge = _badgeForItem(item);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredCards[index] = true),
      onExit: (_) => setState(() => _hoveredCards[index] = false),
      child: GestureDetector(
        onTap: () => context.push('/menu'),
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
                    child: Stack(
                      children: [
                        Positioned.fill(
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
                                    errorBuilder:
                                        (context, error, stackTrace) =>
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
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (badge != null)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: _buildFoodBadge(badge),
                          ),
                      ],
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
                                      // Veg / Non-veg dot
                                      Builder(builder: (ctx) {
                                        final isVeg = (item.type as String).toLowerCase().contains('veg') && !(item.type as String).toLowerCase().contains('non');
                                        return Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isVeg ? const Color(0xFF34C759) : const Color(0xFFEF4444),
                                          ),
                                        );
                                      }),
                                      const SizedBox(width: 6),
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
}
