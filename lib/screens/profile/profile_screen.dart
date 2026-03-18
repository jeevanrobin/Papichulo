import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/order_record.dart';
import '../../models/saved_address.dart';
import '../../providers/cart_provider.dart';
import '../../services/address_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_api_service.dart';
import '../auth/auth_sidebar.dart';
import '../home/set_delivery_location_dialog.dart';
import 'profile_address_card.dart';
import 'profile_edit_dialog.dart';
import 'profile_order_card.dart';

enum _ProfileTab { orders, favourites, payments, addresses, settings }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _gold = Color(0xFFF5C842);
  static const Color _bg = Color(0xFF111111);
  static const Color _card = Color(0xFF1C1C1C);
  static const Color _border = Color(0x1AFFFFFF);

  final OrderApiService _orderApi = OrderApiService();
  late Future<List<OrderRecord>> _ordersFuture;
  _ProfileTab _activeTab = _ProfileTab.orders;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<OrderRecord>> _loadOrders() async {
    final auth = AuthService.instance;
    if (!auth.isAuthenticated) return const <OrderRecord>[];
    return _orderApi.fetchMyOrders();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _loadOrders();
    });
    await _ordersFuture;
  }

  Future<void> _logout() async {
    context.read<CartProvider>().cartService.clearCart();
    await context.read<AuthService>().logout();
    if (!mounted) return;
    context.go('/');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have been logged out.'),
        backgroundColor: Colors.black87,
      ),
    );
  }

  Future<void> _openEditProfileDialog(AuthUser user) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => ProfileEditDialog(user: user),
    );
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111111), Color(0xFF090909)],
          ),
        ),
        child: SafeArea(
          child: Consumer<AuthService>(
            builder: (context, auth, _) {
              if (!auth.isAuthenticated || auth.user == null) {
                return _buildLoggedOutState();
              }

              final user = auth.user!;
              return Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeroCard(context, user),
                              const SizedBox(height: 24),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isDesktop = constraints.maxWidth >= 920;
                                  if (isDesktop) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 240,
                                          child: _buildSidebar(),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: _buildContentArea(context),
                                        ),
                                      ],
                                    );
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildCompactTabs(),
                                      const SizedBox(height: 16),
                                      _buildContentArea(context),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            tooltip: 'Back',
          ),
          const SizedBox(width: 6),
          const Text(
            'PAPICHULO',
            style: TextStyle(
              color: _gold,
              fontSize: 24,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => context.push('/orders'),
            child: const Text(
              'My Orders',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedOutState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, color: _gold, size: 44),
              const SizedBox(height: 10),
              const Text(
                'Login required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to view your profile, orders, and account details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    barrierColor: Colors.transparent,
                    builder: (_) => const AuthSidebar(),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, AuthUser user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1A0E), Color(0xFF151515)],
        ),
        border: Border.all(color: const Color(0x33F5C842)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileAvatarBadge(name: user.name),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.phone?.trim().isNotEmpty == true
                        ? user.phone!.trim()
                        : 'No phone added',
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                  if (user.email?.trim().isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        user.email!.trim(),
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1FF5C842),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0x40F5C842)),
                    ),
                    child: Text(
                      _memberSinceLabel(user.createdAt),
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          OutlinedButton(
            onPressed: () => _openEditProfileDialog(user),
            style: OutlinedButton.styleFrom(
              foregroundColor: _gold,
              side: const BorderSide(color: Color(0x40F5C842)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'EDIT PROFILE',
              style: TextStyle(letterSpacing: 0.6, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final tabs = _ProfileTab.values;
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < tabs.length; index++)
            _buildSidebarItem(
              tab: tabs[index],
              showBottomBorder: index < tabs.length - 1,
            ),
          const Divider(height: 1, color: _border),
          ListTile(
            onTap: _logout,
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required _ProfileTab tab,
    required bool showBottomBorder,
  }) {
    final isActive = _activeTab == tab;
    final color = isActive ? _gold : Colors.grey[400]!;
    return Container(
      decoration: BoxDecoration(
        color: isActive ? const Color(0x14F5C842) : Colors.transparent,
        border: showBottomBorder
            ? const Border(bottom: BorderSide(color: _border))
            : null,
      ),
      child: ListTile(
        onTap: () => setState(() => _activeTab = tab),
        leading: Icon(_tabIcon(tab), color: color),
        title: Text(
          _tabLabel(tab),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCompactTabs() {
    final tabs = _ProfileTab.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tab in tabs)
          ChoiceChip(
            label: Text(_tabLabel(tab)),
            selected: _activeTab == tab,
            labelStyle: TextStyle(
              color: _activeTab == tab ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: _gold,
            backgroundColor: _card,
            side: const BorderSide(color: _border),
            onSelected: (_) => setState(() => _activeTab = tab),
          ),
        ActionChip(
          label: const Text('Logout'),
          labelStyle: const TextStyle(color: Colors.redAccent),
          side: const BorderSide(color: _border),
          backgroundColor: _card,
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildContentArea(BuildContext context) {
    switch (_activeTab) {
      case _ProfileTab.orders:
        return _buildOrdersContent(context);
      case _ProfileTab.favourites:
        return _buildPlaceholder(
          icon: Icons.favorite_outline,
          title: 'Favourites',
          subtitle: 'Saved favourites will appear here.',
        );
      case _ProfileTab.payments:
        return _buildPlaceholder(
          icon: Icons.credit_card_outlined,
          title: 'Payments',
          subtitle: 'Saved payment methods will appear here.',
        );
      case _ProfileTab.addresses:
        return _buildAddressesContent();
      case _ProfileTab.settings:
        return _buildPlaceholder(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Profile settings are coming soon.',
        );
    }
  }

  Widget _buildOrdersContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: FutureBuilder<List<OrderRecord>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator(color: _gold)),
            );
          }

          if (snapshot.hasError) {
            return SizedBox(
              height: 260,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(height: 10),
                      const Text(
                        'Failed to load orders',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${snapshot.error}',
                        style: TextStyle(color: Colors.grey[400]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _refreshOrders,
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: _gold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final orders = snapshot.data ?? const <OrderRecord>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Past Orders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _refreshOrders,
                    icon: const Icon(Icons.refresh, color: _gold),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (orders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    'No orders yet. Your past orders will show up here.',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return ProfileOrderCard(
                      order: orders[index],
                      onReorder: () => _showComingSoon('Reorder'),
                      onHelp: () => _showComingSoon('Order help'),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressesContent() {
    return ListenableBuilder(
      listenable: AddressService.instance,
      builder: (context, _) {
        final addresses = AddressService.instance.addresses;
        final selectedAddressId = AddressService.instance.selectedAddressId;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Saved Addresses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _addNewAddress,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (addresses.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.location_off_outlined,
                          color: _gold.withValues(alpha: 0.5), size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'No saved addresses yet.',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a delivery address from the home screen or tap "Add New" above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: addresses.map<Widget>((addr) {
                    return ProfileAddressCard(
                      address: addr,
                      isSelected: addr.id == selectedAddressId,
                      onSelect: () => _selectAddress(addr),
                      onEdit: () => _editAddress(addr),
                      onDelete: () => _deleteAddress(addr),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _selectAddress(SavedAddress addr) {
    AddressService.instance.setSelectedAddress(addr.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delivery address updated.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _addNewAddress() {
    showDialog<DeliveryLocationResult>(
      context: context,
      builder: (_) => const SetDeliveryLocationDialog(
        latitude: 0,
        longitude: 0,
        resolvedAddress: 'Enter your delivery address',
      ),
    );
  }

  void _editAddress(SavedAddress addr) {
    showDialog<DeliveryLocationResult>(
      context: context,
      builder: (_) => SetDeliveryLocationDialog(
        latitude: addr.latitude,
        longitude: addr.longitude,
        resolvedAddress: addr.address,
        existingAddress: addr,
      ),
    );
  }

  void _deleteAddress(SavedAddress addr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Address',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${addr.label}" address?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      AddressService.instance.deleteAddress(addr.id);
    }
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: _gold, size: 44),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  String _tabLabel(_ProfileTab tab) {
    return switch (tab) {
      _ProfileTab.orders => 'Past Orders',
      _ProfileTab.favourites => 'Favourites',
      _ProfileTab.payments => 'Payments',
      _ProfileTab.addresses => 'Addresses',
      _ProfileTab.settings => 'Settings',
    };
  }

  IconData _tabIcon(_ProfileTab tab) {
    return switch (tab) {
      _ProfileTab.orders => Icons.inventory_2_outlined,
      _ProfileTab.favourites => Icons.favorite_outline,
      _ProfileTab.payments => Icons.credit_card_outlined,
      _ProfileTab.addresses => Icons.location_on_outlined,
      _ProfileTab.settings => Icons.settings_outlined,
    };
  }

  String _memberSinceLabel(DateTime? createdAt) {
    if (createdAt == null) return 'Member';
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[createdAt.month - 1];
    return 'Member since $month ${createdAt.year}';
  }

  void _showComingSoon(String label) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label coming soon.'),
        backgroundColor: Colors.black87,
      ),
    );
  }
}

