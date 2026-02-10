import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/menu_data.dart';
import '../../models/cart_item.dart';
import '../../models/delivery_config.dart';
import '../../services/analytics_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_api_service.dart';

class CartDrawer extends StatefulWidget {
  final CartService cartService;
  final VoidCallback? onClose;

  const CartDrawer({required this.cartService, this.onClose, super.key});

  @override
  State<CartDrawer> createState() => _CartDrawerState();
}

class _CartDrawerState extends State<CartDrawer> with TickerProviderStateMixin {
  static const Color goldYellow = Color(0xFFF5C518);
  static const Color darkBg = Color(0xFF121212);
  static const Color darkGrey = Color(0xFF1E1E1E);
  late AnimationController _pulseController;
  final OrderApiService _orderApi = OrderApiService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _closeCart() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.cartService,
      builder: (context, child) {
        return Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: widget.cartService.items.isEmpty
                    ? _buildEmptyState()
                    : _buildCartItems(),
              ),
            ),
            _buildCheckoutSection(),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: darkBg,
        boxShadow: [
          BoxShadow(
            color: goldYellow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Your Cart',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          GestureDetector(
            onTap: _closeCart,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: goldYellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: goldYellow, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: darkGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: goldYellow.withOpacity(0.1), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                  CurvedAnimation(
                    parent: _pulseController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [goldYellow, goldYellow.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: goldYellow.withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    size: 48,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Your cart is empty',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Add some delicious items to get started.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Popular Items',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildPopularItems(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: List.generate(
          widget.cartService.items.length,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index == widget.cartService.items.length - 1 ? 20 : 12,
            ),
            child: _buildCartItem(widget.cartService.items[index]),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPopularItems() {
    final popular = papichuloMenu
        .where((item) => item.rating >= 4.5)
        .take(3)
        .toList();
    return popular
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: darkBg,
                  ),
                  child: item.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            cacheHeight: 48,
                            cacheWidth: 48,
                            filterQuality: FilterQuality.low,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.fastfood,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.fastfood,
                          color: Colors.grey,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Rs ${item.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: goldYellow,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.cartService.addItem(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: goldYellow,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: goldYellow.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      'Add',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildCartItem(CartItem cartItem) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: goldYellow.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: darkBg,
                ),
                child: cartItem.foodItem.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          cartItem.foodItem.imageUrl!,
                          fit: BoxFit.cover,
                          cacheHeight: 64,
                          cacheWidth: 64,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.fastfood,
                            color: Colors.grey,
                            size: 28,
                          ),
                        ),
                      )
                    : const Icon(Icons.fastfood, color: Colors.grey, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cartItem.foodItem.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rs ${cartItem.foodItem.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: goldYellow,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: darkBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: goldYellow.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => cartItem.quantity == 1
                          ? widget.cartService.removeItem(cartItem.foodItem)
                          : widget.cartService.updateQuantity(
                              cartItem.foodItem,
                              cartItem.quantity - 1,
                            ),
                      child: Icon(
                        cartItem.quantity == 1
                            ? Icons.delete_outline
                            : Icons.remove,
                        color: goldYellow,
                        size: 18,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${cartItem.quantity}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: goldYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.cartService.updateQuantity(
                        cartItem.foodItem,
                        cartItem.quantity + 1,
                      ),
                      child: const Icon(Icons.add, color: goldYellow, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              Text(
                'Rs ${cartItem.totalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: goldYellow,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() {
    final isEmpty = widget.cartService.items.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: darkBg,
        border: Border(top: BorderSide(color: goldYellow.withOpacity(0.15))),
      ),
      child: Column(
        children: [
          if (!isEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Rs ${widget.cartService.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: goldYellow,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    fontSize: 22,
                  ),
                ),
                GestureDetector(
                  onTap: _showCheckoutDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: goldYellow,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: goldYellow.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Checkout',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                fontSize: 14,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _closeCart,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: goldYellow,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: goldYellow.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Browse Menu',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCheckoutDialog() async {
    DeliveryConfig deliveryConfig;
    try {
      deliveryConfig = await _orderApi.fetchDeliveryConfig();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load delivery settings: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    var paymentMethod = 'COD';
    var isFetchingLocation = false;
    var locationStatus =
        'Delivery radius: ${deliveryConfig.radiusKm.toStringAsFixed(1)} km';
    double? selectedLat;
    double? selectedLng;
    double? deliveryDistanceKm;
    var withinDeliveryBoundary = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: darkGrey,
              title: Text(
                'Checkout',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: goldYellow,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCheckoutInput(
                        controller: nameController,
                        label: 'Name',
                        icon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Enter a valid name'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _buildCheckoutInput(
                        controller: phoneController,
                        label: 'Phone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          final value = (v ?? '').trim();
                          final digits = value.replaceAll(RegExp(r'\D'), '');
                          return digits.length < 10
                              ? 'Enter a valid phone number'
                              : null;
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildCheckoutInput(
                        controller: addressController,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (v) => (v == null || v.trim().length < 8)
                            ? 'Enter full delivery address'
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              locationStatus.isEmpty
                                  ? 'Use location or validate typed address.'
                                  : locationStatus,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color:
                                        locationStatus.startsWith(
                                          'Location detected',
                                        )
                                        ? Colors.greenAccent.shade200
                                        : Colors.grey[400],
                                  ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: isFetchingLocation
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isFetchingLocation = true;
                                      locationStatus =
                                          'Requesting location permission...';
                                    });
                                    try {
                                      final result =
                                          await _resolveCurrentLocationLabel();
                                      selectedLat = result.latitude;
                                      selectedLng = result.longitude;
                                      deliveryDistanceKm = _calculateDistanceKm(
                                        storeLatitude:
                                            deliveryConfig.storeLatitude,
                                        storeLongitude:
                                            deliveryConfig.storeLongitude,
                                        latitude: result.latitude,
                                        longitude: result.longitude,
                                      );
                                      withinDeliveryBoundary =
                                          deliveryDistanceKm! <=
                                          deliveryConfig.radiusKm;
                                      addressController.text = result.label;
                                      setDialogState(() {
                                        isFetchingLocation = false;
                                        locationStatus = withinDeliveryBoundary
                                            ? 'Location detected. Delivery available in your area.'
                                            : 'Location detected, but this address is outside delivery zone.';
                                      });
                                    } catch (error) {
                                      setDialogState(() {
                                        isFetchingLocation = false;
                                        locationStatus = _friendlyLocationError(
                                          error,
                                        );
                                      });
                                    }
                                  },
                            icon: isFetchingLocation
                                ? SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: goldYellow,
                                    ),
                                  )
                                : Icon(
                                    Icons.my_location,
                                    size: 16,
                                    color: goldYellow,
                                  ),
                            label: Text(
                              isFetchingLocation
                                  ? 'Detecting...'
                                  : 'Use location',
                              style: TextStyle(color: goldYellow),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: isFetchingLocation
                                ? null
                                : () async {
                                    final typedAddress = addressController.text
                                        .trim();
                                    if (typedAddress.length < 8) {
                                      setDialogState(() {
                                        locationStatus =
                                            'Enter full address, then validate.';
                                      });
                                      return;
                                    }
                                    setDialogState(() {
                                      isFetchingLocation = true;
                                      locationStatus =
                                          'Validating typed address...';
                                    });
                                    try {
                                      final geocoded = await _orderApi
                                          .geocodeAddress(typedAddress);
                                      selectedLat = geocoded.latitude;
                                      selectedLng = geocoded.longitude;
                                      deliveryDistanceKm = _calculateDistanceKm(
                                        storeLatitude:
                                            deliveryConfig.storeLatitude,
                                        storeLongitude:
                                            deliveryConfig.storeLongitude,
                                        latitude: geocoded.latitude,
                                        longitude: geocoded.longitude,
                                      );
                                      withinDeliveryBoundary =
                                          deliveryDistanceKm! <=
                                          deliveryConfig.radiusKm;
                                      setDialogState(() {
                                        isFetchingLocation = false;
                                        locationStatus = withinDeliveryBoundary
                                            ? 'Address validated. Delivery available.'
                                            : 'Address validated, but outside delivery zone.';
                                      });
                                    } catch (error) {
                                      setDialogState(() {
                                        isFetchingLocation = false;
                                        locationStatus = _friendlyLocationError(
                                          error,
                                        );
                                      });
                                    }
                                  },
                            icon: Icon(
                              Icons.verified_outlined,
                              size: 16,
                              color: goldYellow,
                            ),
                            label: Text(
                              'Validate address',
                              style: TextStyle(color: goldYellow),
                            ),
                          ),
                        ],
                      ),
                      if (deliveryDistanceKm != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: withinDeliveryBoundary
                                ? Colors.green.withOpacity(0.12)
                                : Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: withinDeliveryBoundary
                                  ? Colors.greenAccent.withOpacity(0.45)
                                  : Colors.redAccent.withOpacity(0.45),
                            ),
                          ),
                          child: Text(
                            withinDeliveryBoundary
                                ? 'Delivery available (${deliveryDistanceKm!.toStringAsFixed(1)} km from store)'
                                : 'Outside delivery zone (${deliveryDistanceKm!.toStringAsFixed(1)} km, max ${deliveryConfig.radiusKm.toStringAsFixed(1)} km)',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: withinDeliveryBoundary
                                      ? Colors.greenAccent.shade100
                                      : Colors.redAccent.shade100,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: goldYellow.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: darkBg,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                value: 'COD',
                                groupValue: paymentMethod,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: goldYellow,
                                title: Text(
                                  'COD',
                                  style: TextStyle(
                                    color: Colors.grey[200],
                                    fontSize: 13,
                                  ),
                                ),
                                onChanged: (v) => setDialogState(
                                  () => paymentMethod = v ?? 'COD',
                                ),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                value: 'MOCK_ONLINE',
                                groupValue: paymentMethod,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: goldYellow,
                                title: Text(
                                  'Mock Payment',
                                  style: TextStyle(
                                    color: Colors.grey[200],
                                    fontSize: 13,
                                  ),
                                ),
                                onChanged: (v) => setDialogState(
                                  () => paymentMethod = v ?? 'MOCK_ONLINE',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Colors.grey[300],
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            'Rs ${widget.cartService.totalAmount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: goldYellow,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (selectedLat == null || selectedLng == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Use location or validate typed address first.',
                          ),
                          backgroundColor: Colors.orangeAccent,
                        ),
                      );
                      return;
                    }
                    if (!withinDeliveryBoundary) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Sorry, delivery is available only within ${deliveryConfig.radiusKm.toStringAsFixed(1)} km.',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    final paymentLabel = paymentMethod == 'COD'
                        ? 'Cash on Delivery'
                        : 'Mock Online Payment';
                    try {
                      final order = await _orderApi.createOrder(
                        customerName: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        address: addressController.text.trim(),
                        latitude: selectedLat!,
                        longitude: selectedLng!,
                        paymentMethod: paymentLabel,
                        items: widget.cartService.items,
                        totalAmount: widget.cartService.totalAmount,
                      );

                      if (!context.mounted) return;
                      AnalyticsService().track(
                        'order_placed',
                        params: {
                          'order_id': order.id,
                          'payment_method': paymentLabel,
                          'item_count': widget.cartService.itemCount,
                          'total_amount': widget.cartService.totalAmount,
                        },
                      );
                      Navigator.pop(dialogContext);
                      await _showOrderSuccessDialog(
                        orderId: order.id.isEmpty
                            ? _generateOrderId()
                            : order.id,
                        customerName: nameController.text.trim(),
                        paymentMethodLabel: paymentLabel,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      if (paymentMethod == 'MOCK_ONLINE') {
                        final localOrderId = _generateOrderId();
                        AnalyticsService().track(
                          'order_placed_local_fallback',
                          params: {
                            'order_id': localOrderId,
                            'payment_method': paymentLabel,
                            'item_count': widget.cartService.itemCount,
                            'total_amount': widget.cartService.totalAmount,
                          },
                        );
                        Navigator.pop(dialogContext);
                        await _showOrderSuccessDialog(
                          orderId: localOrderId,
                          customerName: nameController.text.trim(),
                          paymentMethodLabel: '$paymentLabel (Local)',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Backend unavailable. Order saved locally as mock order.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_friendlyOrderError(e)),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: goldYellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Place Order',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_LocationResult> _resolveCurrentLocationLabel() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw Exception(
        'Location services are disabled. Turn on GPS/location and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it from browser/system settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return _LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      label:
          'Lat ${position.latitude.toStringAsFixed(5)}, Lng ${position.longitude.toStringAsFixed(5)}',
    );
  }

  double _calculateDistanceKm({
    required double storeLatitude,
    required double storeLongitude,
    required double latitude,
    required double longitude,
  }) {
    final meters = Geolocator.distanceBetween(
      storeLatitude,
      storeLongitude,
      latitude,
      longitude,
    );
    return meters / 1000.0;
  }

  String _friendlyLocationError(Object error) {
    final raw = error.toString();
    if (raw.contains('permission') || raw.contains('denied')) {
      return 'Location permission denied. Please allow access and retry.';
    }
    if (raw.contains('services are disabled')) {
      return 'Location services are off. Enable location and retry.';
    }
    return 'Unable to detect location right now. Please enter address manually.';
  }

  Widget _buildCheckoutInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: goldYellow.withOpacity(0.9), size: 18),
        filled: true,
        fillColor: darkBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: goldYellow.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: goldYellow, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  String _generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(7);
    final randomPart = (1000 + Random().nextInt(9000)).toString();
    return 'PC$timestamp$randomPart';
  }

  Future<void> _showOrderSuccessDialog({
    required String orderId,
    required String customerName,
    required String paymentMethodLabel,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: darkGrey,
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: goldYellow, size: 26),
            const SizedBox(width: 8),
            Text(
              'Order Placed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: goldYellow,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thanks, $customerName!',
              style: TextStyle(
                color: Colors.grey[200],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: $orderId',
              style: const TextStyle(
                color: goldYellow,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Payment: $paymentMethodLabel',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 6),
            Text(
              'Total: Rs ${widget.cartService.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[100],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              widget.cartService.clearCart();
              Navigator.pop(context);
              _closeCart();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: goldYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Done',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyOrderError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('failed to fetch') || message.contains('network')) {
      return 'Unable to reach server. Please check connection and try again.';
    }
    if (message.contains('400')) {
      return 'Invalid order details. Please review your checkout form.';
    }
    return 'Could not place order right now. Please try again.';
  }
}

class _LocationResult {
  final double latitude;
  final double longitude;
  final String label;

  const _LocationResult({
    required this.latitude,
    required this.longitude,
    required this.label,
  });
}
