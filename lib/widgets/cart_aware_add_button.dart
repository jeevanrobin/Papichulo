import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../models/food_item.dart';

class CartAwareAddButton extends StatelessWidget {
  final FoodItem item;
  final bool isCompact;

  const CartAwareAddButton({
    super.key,
    required this.item,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cartService, _) {
        int quantity = 0;
        for (var ci in cartService.items) {
          if (ci.foodItem.name == item.name) {
            quantity = ci.quantity;
            break;
          }
        }

        if (quantity == 0) {
          return _buildAddButton(context, cartService);
        } else {
          return _buildQuantityControls(context, cartService, quantity);
        }
      },
    );
  }

  Widget _buildAddButton(BuildContext context, CartService cartService) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => cartService.addItem(item),
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFFFFD700).withOpacity(0.3),
        highlightColor: const Color(0xFFFFD700).withOpacity(0.15),
        child: Container(
          padding: isCompact
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
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(BuildContext context, CartService cartService, int quantity) {
    return Container(
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
              onTap: () => quantity == 1
                  ? cartService.removeItem(item)
                  : cartService.updateQuantity(item, quantity - 1),
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
              onTap: () => cartService.updateQuantity(item, quantity + 1),
              borderRadius: BorderRadius.circular(4),
              splashColor: const Color(0xFFFFD700).withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.add,
                  color: const Color(0xFFFFD700),
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
