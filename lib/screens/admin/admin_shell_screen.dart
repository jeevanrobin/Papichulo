import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/order_api_service.dart';
import 'orders_admin_screen.dart';

enum AdminSection { dashboard, orders, menu, settings }

class AdminShellScreen extends StatefulWidget {
  final AdminSection initialSection;

  const AdminShellScreen({
    super.key,
    this.initialSection = AdminSection.dashboard,
  });

  const AdminShellScreen.orders({super.key})
    : initialSection = AdminSection.orders;

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  static const Color goldYellow = Color(0xFFFFD700);
  static const Color darkGrey = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF222222);

  late AdminSection _section;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor: darkGrey,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: goldYellow,
          title: const Text('Admin'),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: goldYellow.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: goldYellow, size: 36),
                const SizedBox(height: 10),
                const Text(
                  'Admin access required',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please login with an admin account to access this page.',
                  style: TextStyle(color: Colors.grey[300]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: darkGrey,
      body: SafeArea(
        child: Row(
          children: [
            _AdminSidebar(
              selected: _section,
              onSelect: (value) => setState(() => _section = value),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(auth),
                  Expanded(child: _buildSection()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AuthService auth) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: goldYellow.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Text(
            _titleForSection(_section),
            style: const TextStyle(
              color: goldYellow,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0x33FFD700),
              border: Border.all(color: goldYellow.withValues(alpha: 0.25)),
            ),
            child: Text(
              '${auth.user?.name ?? 'Admin'}  (admin)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleForSection(AdminSection section) {
    switch (section) {
      case AdminSection.dashboard:
        return 'Dashboard';
      case AdminSection.orders:
        return 'Orders';
      case AdminSection.menu:
        return 'Menu';
      case AdminSection.settings:
        return 'Settings';
    }
  }

  Widget _buildSection() {
    switch (_section) {
      case AdminSection.dashboard:
        return const _AdminDashboardTab();
      case AdminSection.orders:
        return const OrdersAdminScreen.embedded();
      case AdminSection.menu:
        return const _AdminMenuCrudTab();
      case AdminSection.settings:
        return const _AdminSettingsTab();
    }
  }
}

class _AdminSidebar extends StatelessWidget {
  final AdminSection selected;
  final ValueChanged<AdminSection> onSelect;

  const _AdminSidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          right: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          const Text(
            'PAPICHULO',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            active: selected == AdminSection.dashboard,
            onTap: () => onSelect(AdminSection.dashboard),
          ),
          _SidebarItem(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            active: selected == AdminSection.orders,
            onTap: () => onSelect(AdminSection.orders),
          ),
          _SidebarItem(
            icon: Icons.restaurant_menu_outlined,
            label: 'Menu',
            active: selected == AdminSection.menu,
            onTap: () => onSelect(AdminSection.menu),
          ),
          _SidebarItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            active: selected == AdminSection.settings,
            onTap: () => onSelect(AdminSection.settings),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: active ? const Color(0x33FFD700) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: active ? gold : Colors.grey[300], size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? gold : Colors.grey[300],
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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

class _AdminDashboardTab extends StatefulWidget {
  const _AdminDashboardTab();

  @override
  State<_AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<_AdminDashboardTab> {
  final OrderApiService _api = OrderApiService();
  late Future<_AdminMetrics> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdminMetrics> _load() async {
    final orders = await _api.fetchOrders();
    final menu = await _api.fetchAdminMenu();
    final now = DateTime.now();
    final todayOrders = orders.where((o) {
      final d = o.createdAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();

    final activeOrders = orders.where((o) {
      return o.status == 'new' ||
          o.status == 'accepted' ||
          o.status == 'preparing';
    }).length;

    final todayRevenue = todayOrders.fold<double>(
      0,
      (sum, o) => sum + o.totalAmount,
    );
    final menuCount = menu.length;
    final availableCount = menu.where((m) => m['available'] == true).length;
    return _AdminMetrics(
      totalOrders: orders.length,
      activeOrders: activeOrders,
      todayOrders: todayOrders.length,
      todayRevenue: todayRevenue,
      menuCount: menuCount,
      availableCount: availableCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminMetrics>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _ReloadPane(
            onReload: () {
              setState(() {
                _future = _load();
              });
            },
          );
        }
        final metrics = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    title: 'Total Orders',
                    value: '${metrics.totalOrders}',
                  ),
                  _MetricCard(
                    title: 'Active Orders',
                    value: '${metrics.activeOrders}',
                  ),
                  _MetricCard(
                    title: 'Today Orders',
                    value: '${metrics.todayOrders}',
                  ),
                  _MetricCard(
                    title: 'Today Revenue',
                    value: 'Rs ${metrics.todayRevenue.toStringAsFixed(2)}',
                  ),
                  _MetricCard(
                    title: 'Menu Items',
                    value: '${metrics.menuCount}',
                  ),
                  _MetricCard(
                    title: 'Available Items',
                    value: '${metrics.availableCount}',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[300], fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuCrudTab extends StatefulWidget {
  const _AdminMenuCrudTab();

  @override
  State<_AdminMenuCrudTab> createState() => _AdminMenuCrudTabState();
}

class _AdminMenuCrudTabState extends State<_AdminMenuCrudTab> {
  final OrderApiService _api = OrderApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchAdminMenu();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _api.fetchAdminMenu();
    });
  }

  Future<void> _toggleAvailability(
    Map<String, dynamic> item,
    bool value,
  ) async {
    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;
    try {
      await _api.updateAdminMenuItem(id: id, payload: {'available': value});
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update availability: $error')),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;
    try {
      await _api.deleteAdminMenuItem(id);
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete item: $error')));
    }
  }

  Future<void> _showItemEditor({Map<String, dynamic>? item}) async {
    final isEdit = item != null;
    final nameController = TextEditingController(
      text: (item?['name'] ?? '').toString(),
    );
    final categoryController = TextEditingController(
      text: (item?['category'] ?? '').toString(),
    );
    final ingredientsController = TextEditingController(
      text: ((item?['ingredients'] as List?) ?? const []).join(', '),
    );
    final imageController = TextEditingController(
      text: (item?['imageUrl'] ?? '').toString(),
    );
    final priceController = TextEditingController(
      text: (item?['price'] ?? '').toString(),
    );
    final ratingController = TextEditingController(
      text: (item?['rating'] ?? 4.5).toString(),
    );
    String type = (item?['type'] ?? 'Veg').toString();
    bool available = (item?['available'] ?? true) == true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1F1F1F),
              title: Text(
                isEdit ? 'Edit Menu Item' : 'Add Menu Item',
                style: const TextStyle(color: Color(0xFFFFD700)),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _input(nameController, 'Name'),
                      const SizedBox(height: 8),
                      _input(categoryController, 'Category'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: type,
                        items: const [
                          DropdownMenuItem(value: 'Veg', child: Text('Veg')),
                          DropdownMenuItem(
                            value: 'Non-Veg',
                            child: Text('Non-Veg'),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => type = value ?? 'Veg'),
                        decoration: _inputDecoration('Type'),
                      ),
                      const SizedBox(height: 8),
                      _input(
                        ingredientsController,
                        'Ingredients (comma separated)',
                      ),
                      const SizedBox(height: 8),
                      _input(imageController, 'Image URL'),
                      const SizedBox(height: 8),
                      _input(
                        priceController,
                        'Price',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      _input(
                        ratingController,
                        'Rating (0-5)',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: available,
                        onChanged: (value) =>
                            setDialogState(() => available = value),
                        title: const Text(
                          'Available',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final price = double.tryParse(priceController.text.trim());
                    final rating =
                        double.tryParse(ratingController.text.trim()) ?? 4.5;
                    final ingredients = ingredientsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    if (nameController.text.trim().isEmpty ||
                        categoryController.text.trim().isEmpty ||
                        price == null ||
                        ingredients.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                        ),
                      );
                      return;
                    }

                    try {
                      if (isEdit) {
                        await _api.updateAdminMenuItem(
                          id: (item['id'] as num).toInt(),
                          payload: {
                            'name': nameController.text.trim(),
                            'category': categoryController.text.trim(),
                            'type': type,
                            'ingredients': ingredients,
                            'imageUrl': imageController.text.trim(),
                            'price': price,
                            'rating': rating,
                            'available': available,
                          },
                        );
                      } else {
                        await _api.createAdminMenuItem(
                          name: nameController.text.trim(),
                          category: categoryController.text.trim(),
                          type: type,
                          ingredients: ingredients,
                          imageUrl: imageController.text.trim(),
                          price: price,
                          rating: rating,
                          available: available,
                        );
                      }
                      if (!context.mounted) return;
                      Navigator.pop(dialogContext);
                      await _reload();
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Save failed: $error')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(isEdit ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFFD700)),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ReloadPane(onReload: _reload);
        }
        final menuItems = snapshot.data ?? const <Map<String, dynamic>>[];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Menu Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showItemEditor(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: menuItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    final title = (item['name'] ?? '').toString();
                    final category = (item['category'] ?? '').toString();
                    final type = (item['type'] ?? '').toString();
                    final price = (item['price'] as num?)?.toDouble() ?? 0;
                    final available = item['available'] == true;
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(
                            0xFFFFD700,
                          ).withValues(alpha: 0.12),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$category  |  $type  |  Rs ${price.toStringAsFixed(0)}',
                                  style: TextStyle(color: Colors.grey[300]),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: available,
                            onChanged: (value) =>
                                _toggleAvailability(item, value),
                            activeColor: const Color(0xFFFFD700),
                          ),
                          IconButton(
                            onPressed: () => _showItemEditor(item: item),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.amber,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _delete(item),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminSettingsTab extends StatelessWidget {
  const _AdminSettingsTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Settings',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Logged in as: ${auth.user?.email ?? '-'}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Role-based access is enabled. Non-admin users are blocked from this panel.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReloadPane extends StatelessWidget {
  final VoidCallback onReload;

  const _ReloadPane({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onReload,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
        ),
        icon: const Icon(Icons.refresh),
        label: const Text('Reload'),
      ),
    );
  }
}

class _AdminMetrics {
  final int totalOrders;
  final int activeOrders;
  final int todayOrders;
  final double todayRevenue;
  final int menuCount;
  final int availableCount;

  const _AdminMetrics({
    required this.totalOrders,
    required this.activeOrders,
    required this.todayOrders,
    required this.todayRevenue,
    required this.menuCount,
    required this.availableCount,
  });
}
