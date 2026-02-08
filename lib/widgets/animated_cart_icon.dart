import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class AnimatedCartIcon extends StatefulWidget {
  final VoidCallback onCartTap;
  final bool isCompact;

  const AnimatedCartIcon({
    required this.onCartTap,
    this.isCompact = false,
    super.key,
  });

  @override
  State<AnimatedCartIcon> createState() => _AnimatedCartIconState();
}

class _AnimatedCartIconState extends State<AnimatedCartIcon>
    with TickerProviderStateMixin {
  static const Color goldYellow = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFB8860B);

  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late AnimationController _openController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _openAnimation;

  int _lastItemCount = 0;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _openController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _openAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _openController, curve: Curves.easeOut),
    );

    _lastItemCount = context.read<CartProvider>().cartService.itemCount;
  }

  @override
  void didUpdateWidget(AnimatedCartIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentCount = context.read<CartProvider>().cartService.itemCount;
    if (currentCount > _lastItemCount) {
      _bounceController.forward(from: 0.0);
      _pulseController.forward(from: 0.0);
      _lastItemCount = currentCount;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pulseController.dispose();
    _openController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        if (cartProvider.isCartOpen && !_openController.isAnimating) {
          _openController.forward(from: 0.0);
        }

        return GestureDetector(
          onTap: widget.onCartTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ScaleTransition(
              scale: _openController.isAnimating ? _openAnimation : AlwaysStoppedAnimation(1.0),
              child: AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bounceAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: widget.isCompact ? 40 : 45,
                  height: widget.isCompact ? 40 : 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [goldYellow, darkGold]),
                    boxShadow: [
                      BoxShadow(
                        color: goldYellow.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.shopping_cart,
                          color: Colors.black,
                          size: widget.isCompact ? 20 : 22,
                        ),
                      ),
                      if (cartProvider.cartService.itemCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cartProvider.cartService.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
