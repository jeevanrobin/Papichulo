import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../models/food_item.dart';

class FlyToCartButton extends StatefulWidget {
  final FoodItem item;
  final bool isCompact;
  final GlobalKey cartIconKey;

  const FlyToCartButton({
    super.key,
    required this.item,
    required this.cartIconKey,
    this.isCompact = false,
  });

  @override
  State<FlyToCartButton> createState() => _FlyToCartButtonState();
}

class _FlyToCartButtonState extends State<FlyToCartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late GlobalKey _buttonKey;

  @override
  void initState() {
    super.initState();
    _buttonKey = GlobalKey();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onTap(CartService cartService, int quantity) {
    _bounceController.forward(from: 0.0);
    if (quantity == 0) {
      cartService.addItem(widget.item);
      _animateFlyToCart();
    }
  }

  void _animateFlyToCart() {
    try {
      final buttonBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
      final cartBox = widget.cartIconKey.currentContext?.findRenderObject() as RenderBox?;
      
      if (buttonBox != null && cartBox != null) {
        final buttonPos = buttonBox.localToGlobal(Offset.zero);
        final cartPos = cartBox.localToGlobal(Offset.zero);
        
        _showFlyingItem(buttonPos, cartPos);
      }
    } catch (e) {
      // Silently fail on web or if keys not available
    }
  }

  void _showFlyingItem(Offset from, Offset to) {
    final overlay = Overlay.of(context);
    final animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animController, curve: Curves.easeInBack),
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final dx = from.dx + (to.dx - from.dx) * animation.value;
          final dy = from.dy + (to.dy - from.dy) * animation.value;
          final scale = 1.0 - (animation.value * 0.7);

          return Positioned(
            left: dx,
            top: dy,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: 1.0 - animation.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shopping_cart, color: Colors.black, size: 20),
                ),
              ),
            ),
          );
        },
      ),
    );

    overlay.insert(entry);
    animController.forward().then((_) {
      entry.remove();
      animController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cartService, _) {
        int quantity = 0;
        for (var ci in cartService.items) {
          if (ci.foodItem.name == widget.item.name) {
            quantity = ci.quantity;
            break;
          }
        }

        return ScaleTransition(
          scale: _bounceAnimation,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: quantity == 0
                ? _buildAddButton(cartService, quantity)
                : _buildQuantityCounter(cartService, quantity),
          ),
        );
      },
    );
  }

  Widget _buildAddButton(CartService cartService, int quantity) {
    return Material(
      key: const ValueKey('add_button'),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(cartService, quantity),
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFFFFD700).withOpacity(0.3),
        highlightColor: const Color(0xFFFFD700).withOpacity(0.15),
        child: Container(
          key: _buttonKey,
          padding: widget.isCompact
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            'Add',
            style: TextStyle(
              color: Colors.black,
              fontSize: widget.isCompact ? 11 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityCounter(CartService cartService, int quantity) {
    return Container(
      key: const ValueKey('quantity_counter'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _bounceController.forward(from: 0.0);
                if (quantity == 1) {
                  cartService.removeItem(widget.item);
                } else {
                  cartService.updateQuantity(widget.item, quantity - 1);
                }
              },
              borderRadius: BorderRadius.circular(4),
              splashColor: const Color(0xFFFFD700).withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  quantity == 1 ? Icons.delete_outline : Icons.remove,
                  color: const Color(0xFFFFD700),
                  size: 18,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _bounceController.forward(from: 0.0);
                cartService.updateQuantity(widget.item, quantity + 1);
              },
              borderRadius: BorderRadius.circular(4),
              splashColor: const Color(0xFFFFD700).withOpacity(0.2),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.add,
                  color: Color(0xFFFFD700),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
