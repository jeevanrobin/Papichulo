import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  static const Color goldYellow = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF1A1A1A);
  static const String contactPhone = '7829999976';

  Future<void> _openPhoneDialer() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: contactPhone);
    await launchUrl(phoneUri);
  }

  Future<void> _openEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto', path: 'info@papichulo.com');
    await launchUrl(emailUri);
  }

  Future<void> _openLocation() async {
    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=Hyderabad%2C%20India',
    );
    await launchUrl(mapUri);
  }

  Future<void> _showAboutUsDialog(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'About Us',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final double screenWidth = MediaQuery.of(dialogContext).size.width;
        final double dialogWidth = screenWidth > 900
            ? screenWidth * 0.5
            : screenWidth - 48;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: dialogWidth,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: goldYellow.withOpacity(0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldYellow.withOpacity(0.2),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant_menu, color: goldYellow, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'About Papichulo',
                        style: Theme.of(dialogContext).textTheme.titleLarge
                            ?.copyWith(
                              color: goldYellow,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'We are Papichulo, focused on serving fresh, tasty food with premium quality and quick service. '
                    'Our team is committed to giving you a better food experience with every order.',
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[300], height: 1.6),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: goldYellow,
                        foregroundColor: black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFaqDialog(BuildContext context) async {
    await _showAnimatedInfoDialog(
      context,
      title: 'FAQ',
      content:
          'We deliver fresh food quickly, with menu quality and customer support as top priorities.',
    );
  }

  Future<void> _showTermsDialog(BuildContext context) async {
    await _showAnimatedInfoDialog(
      context,
      title: 'Terms & Conditions',
      content:
          'Orders are prepared after confirmation. Delivery time may vary by location and traffic conditions.',
    );
  }

  Future<void> _showAnimatedInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: title,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final double screenWidth = MediaQuery.of(dialogContext).size.width;
        final double dialogWidth = screenWidth > 900
            ? screenWidth * 0.5
            : screenWidth - 48;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: dialogWidth,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: goldYellow.withOpacity(0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldYellow.withOpacity(0.2),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(dialogContext).textTheme.titleLarge
                        ?.copyWith(
                          color: goldYellow,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[300], height: 1.6),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: goldYellow,
                        foregroundColor: black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        final double screenWidth = MediaQuery.of(dialogContext).size.width;
        final double dialogWidth = screenWidth > 900
            ? screenWidth * 0.5
            : screenWidth - 48;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: dialogWidth,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF111111), Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: goldYellow.withOpacity(0.5),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(dialogContext).textTheme.titleLarge
                        ?.copyWith(
                          color: goldYellow,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[300], height: 1.6),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: goldYellow,
                        foregroundColor: black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterLink(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[400],
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: goldYellow, size: 20),
      ),
    );
  }

  Widget _buildPaymentMethodChip(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: goldYellow.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: goldYellow),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headingStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: goldYellow,
      fontWeight: FontWeight.bold,
    );

    final footerSections = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact', style: headingStyle),
          const SizedBox(height: 18),
          _buildFooterLink(
            context,
            label: contactPhone,
            onTap: _openPhoneDialer,
          ),
          _buildFooterLink(
            context,
            label: 'info@papichulo.com',
            onTap: _openEmail,
          ),
          _buildFooterLink(
            context,
            label: 'Hyderabad, India',
            onTap: _openLocation,
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Links', style: headingStyle),
          const SizedBox(height: 18),
          _buildFooterLink(
            context,
            label: 'About Us',
            onTap: () => _showAboutUsDialog(context),
          ),
          _buildFooterLink(
            context,
            label: 'FAQ',
            onTap: () => _showFaqDialog(context),
          ),
          _buildFooterLink(
            context,
            label: 'Terms & Conditions',
            onTap: () => _showTermsDialog(context),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Follow Us', style: headingStyle),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildFooterIcon(
                icon: Icons.facebook,
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Facebook',
                  content: 'Our Facebook page will be available soon.',
                ),
              ),
              const SizedBox(width: 12),
              _buildFooterIcon(
                icon: Icons.camera_alt,
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Instagram',
                  content: 'Our Instagram handle will be available soon.',
                ),
              ),
              const SizedBox(width: 12),
              _buildFooterIcon(
                icon: Icons.language,
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Website',
                  content:
                      'You are already on our website. More updates coming soon.',
                ),
              ),
            ],
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Methods', style: headingStyle),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildPaymentMethodChip(
                context,
                label: 'Visa',
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Payment - Visa',
                  content:
                      'Visa card payments are accepted for all online orders.',
                ),
              ),
              const SizedBox(width: 8),
              _buildPaymentMethodChip(
                context,
                label: 'MC',
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Payment - MasterCard',
                  content:
                      'MasterCard payments are accepted for all online orders.',
                ),
              ),
            ],
          ),
        ],
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [black, darkGrey],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 980) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: footerSections
                          .map((section) => Expanded(child: section))
                          .toList(growable: false),
                    );
                  }
                  return Wrap(
                    spacing: 38,
                    runSpacing: 24,
                    children: footerSections
                        .map(
                          (section) => SizedBox(
                            width: constraints.maxWidth > 560
                                ? (constraints.maxWidth - 38) / 2
                                : constraints.maxWidth,
                            child: section,
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
              const SizedBox(height: 34),
              Divider(color: goldYellow.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(
                '(c) 2024 Papichulo. All rights reserved.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
