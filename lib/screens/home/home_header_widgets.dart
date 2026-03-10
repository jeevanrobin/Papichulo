import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

/// Reusable header navigation item with optional badge counter.
class HomeNavItem extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final int badgeCount;
  static const Color goldYellow = Color(0xFFFFD700);

  const HomeNavItem({
    super.key,
    required this.text,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.03),
                    Colors.white.withOpacity(0.01),
                  ],
                ),
                border: Border.all(color: goldYellow.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: goldYellow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -7,
                right: -7,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black87),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Header "Order Now" call-to-action button.
class HomeHeaderCTA extends StatefulWidget {
  final VoidCallback onTap;

  const HomeHeaderCTA({super.key, required this.onTap});

  @override
  State<HomeHeaderCTA> createState() => _HomeHeaderCTAState();
}

class _HomeHeaderCTAState extends State<HomeHeaderCTA> {
  static const Color goldYellow = Color(0xFFFFD700);
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _hovered ? 1.03 : 1.0,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE168), Color(0xFFFFD700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: goldYellow.withOpacity(_hovered ? 0.46 : 0.32),
                  blurRadius: _hovered ? 28 : 20,
                  offset: Offset(0, _hovered ? 10 : 8),
                ),
              ],
            ),
            child: Text(
              'Order Now',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero-section primary call-to-action button.
class HomePrimaryCTA extends StatefulWidget {
  final VoidCallback onTap;

  const HomePrimaryCTA({super.key, required this.onTap});

  @override
  State<HomePrimaryCTA> createState() => _HomePrimaryCTAState();
}

class _HomePrimaryCTAState extends State<HomePrimaryCTA> {
  static const Color goldYellow = Color(0xFFFFD700);
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _hovered ? 1.03 : 1.0,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE168), Color(0xFFFFD700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: goldYellow.withOpacity(_hovered ? 0.52 : 0.35),
                  blurRadius: _hovered ? 32 : 24,
                  offset: Offset(0, _hovered ? 11 : 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Now',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
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

/// Location chip shown in the header bar.
class HomeLocationChip extends StatelessWidget {
  final Object? label;
  final bool isLoading;
  final VoidCallback onTap;
  static const Color goldYellow = Color(0xFFFFD700);

  const HomeLocationChip({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = (label?.toString() ?? '').trim();
    final displayLabel = resolvedLabel.isEmpty || resolvedLabel == 'null'
        ? 'Set location'
        : resolvedLabel;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: goldYellow.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: goldYellow),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  displayLabel,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: goldYellow.withOpacity(0.9),
                  ),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: goldYellow,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile popup-menu action enum.
enum ProfileMenuAction {
  login,
  signup,
  profile,
  orders,
  membership,
  favourites,
  logout,
}

/// A single entry in the profile popup menu.
class ProfileMenuEntry extends StatelessWidget {
  final String label;

  const ProfileMenuEntry({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF222222),
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }
}
