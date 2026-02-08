import 'package:flutter/material.dart';

class PremiumAddButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isCompact;

  const PremiumAddButton({
    super.key,
    required this.onPressed,
    this.isCompact = false,
  });

  @override
  State<PremiumAddButton> createState() => _PremiumAddButtonState();
}

class _PremiumAddButtonState extends State<PremiumAddButton>
    with SingleTickerProviderStateMixin {
  static const Color goldYellow = Color(0xFFFFD700);

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _showAdded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    _controller.forward().then((_) {
      _controller.reverse();
    });

    widget.onPressed();

    setState(() => _showAdded = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showAdded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handlePress,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                children: [
                  if (_glowAnimation.value > 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: goldYellow.withOpacity(0.6 * _glowAnimation.value),
                              blurRadius: 16 * _glowAnimation.value,
                              spreadRadius: 4 * _glowAnimation.value,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    padding: widget.isCompact
                        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                        : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: goldYellow,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: goldYellow.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      _showAdded ? 'Added ✓' : 'Add',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: widget.isCompact ? 11 : 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
