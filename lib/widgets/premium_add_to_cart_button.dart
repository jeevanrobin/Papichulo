import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../models/food_item.dart';

class PremiumAddToCartButton extends StatefulWidget {
  final FoodItem item;
  final bool isCompact;

  const PremiumAddToCartButton({
    super.key,
    required this.item,
    this.isCompact = false,
  });

  @override
  State<PremiumAddToCartButton> createState() => _PremiumAddToCartButtonState();
}

class _PremiumAddToCartButtonState extends State<PremiumAddToCartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
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
    }
  }

  void _updateQuantity(CartService cartService, int quantity, int delta) {
    _bounceController.forward(from: 0.0);
    if (delta < 0 && quantity == 1) {
      cartService.removeItem(widget.item);
    } else {
      cartService.updateQuantity(widget.item, quantity + delta);
    }
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
              onTap: () => _updateQuantity(cartService, quantity, -1),
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
              onTap: () => _updateQuantity(cartService, quantity, 1),
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
