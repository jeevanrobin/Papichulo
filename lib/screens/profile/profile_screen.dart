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
      builder: (_) => _EditProfileDialog(user: user),
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
              _AvatarBadge(name: user.name),
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
                    return _OrderCard(
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
                  children: addresses.map((addr) {
                    return _AddressCard(
                      address: addr,
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

class _EditProfileDialog extends StatefulWidget {
  final AuthUser user;

  const _EditProfileDialog({required this.user});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  static const Color _gold = Color(0xFFF5C842);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthService>().updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String? _validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Name is required.';
    if (name.length < 2) return 'Name must be at least 2 characters.';
    if (name.length > 80) return 'Name must be at most 80 characters.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return null;
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    if (email.length > 120) return 'Email must be at most 120 characters.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1D1D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x33F5C842)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: widget.user.phone ?? '',
                  readOnly: true,
                  style: TextStyle(color: Colors.grey[400]),
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final String name;

  const _AvatarBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5C842), Color(0xFFC8900A)],
        ),
      ),
      child: Text(
        initials.isEmpty ? 'U' : initials,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderRecord order;
  final VoidCallback onReorder;
  final VoidCallback onHelp;

  const _OrderCard({
    required this.order,
    required this.onReorder,
    required this.onHelp,
  });

  static const Color _gold = Color(0xFFF5C842);
  static const Color _border = Color(0x1AFFFFFF);

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final dateText = _formatDate(context, order.createdAt.toLocal());
    final itemText = _itemsSummary(order.items);
    final location = _locationSummary(order.address);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: const Icon(Icons.lunch_dining, color: _gold, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Papichulo Kitchen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ORDER #${order.id} | $dateText',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _border),
          const SizedBox(height: 12),
          Text(
            '$itemText | Total Paid: Rs ${order.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey[300], fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: onReorder,
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: const Text('REORDER'),
              ),
              OutlinedButton(
                onPressed: onHelp,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Color(0x33FFFFFF)),
                ),
                child: const Text('HELP'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'new':
        return 'New';
      case 'accepted':
        return 'Accepted';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'new' => Colors.orangeAccent,
      'accepted' => Colors.lightBlueAccent,
      'preparing' => Colors.deepPurpleAccent,
      'out_for_delivery' => Colors.amber,
      'delivered' => Colors.green,
      'cancelled' => Colors.redAccent,
      _ => Colors.grey,
    };
  }

  static String _itemsSummary(List<OrderLineItem> items) {
    if (items.isEmpty) return 'Order items';
    final first = items
        .take(2)
        .map((item) {
          final quantity = item.quantity > 0 ? item.quantity : 1;
          return '${item.name} x $quantity';
        })
        .join(', ');
    if (items.length <= 2) return first;
    return '$first +${items.length - 2} more';
  }

  static String _locationSummary(String address) {
    final clean = address.trim();
    if (clean.isEmpty) return 'Delivery location';
    final parts = clean.split(',');
    return parts.first.trim().isNotEmpty ? parts.first.trim() : clean;
  }

  static String _formatDate(BuildContext context, DateTime dateTime) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(dateTime);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
    );
    return '$date, $time';
  }
}

class _AddressCard extends StatelessWidget {
  static const Color _gold = Color(0xFFF5C842);
  static const Color _border = Color(0x1AFFFFFF);

  final SavedAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  IconData get _labelIcon {
    switch (address.label.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon + label + actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_labelIcon, color: _gold, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  address.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined,
                    color: _gold.withValues(alpha: 0.7), size: 18),
                tooltip: 'Edit',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 18),
                tooltip: 'Delete',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Address text
          Text(
            address.fullAddress,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
