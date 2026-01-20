import 'package:flutter/material.dart';
import '../../data/menu_data.dart';
import '../menu/menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color accentColor = Color(0xFFFF6B35);
  static const Color primaryColor = Color(0xFF66BB6A);
  static const Color darkText = Colors.black87;
  int specialMenuPage = 0;
  int regularFoodPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              _buildHeader(),

              // Hero Section
              _buildHeroSection(),

              // Featured Items Section
              _buildFeaturedItems(),

              // Why Choose Us Section
              _buildWhyChooseUs(),

              // Special Menu Section
              _buildSpecialMenu(),

              // Our Regular Food Section
              _buildRegularFood(),

              // Our Special Chef's Section
              _buildSpecialChefs(),

              // Footer Section
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          const Text(
            'PAPICHULO',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 1,
            ),
          ),

          // Navigation Menu
          Row(
            children: [
              _navItem('Home', onTap: () {}),
              _navItem('Menu', onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MenuScreen()),
                );
              }),
              _navItem('About Us', onTap: () {}),
              _navItem('Contact', onTap: () {}),
            ],
          ),

          // Icons and Sign Up Button
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                ),
                child: Icon(Icons.search, size: 20, color: Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                ),
                child: Icon(Icons.person, size: 20, color: Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navItem(String label, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Row(
        children: [
          // Left Content
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hungry Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: darkText, width: 2),
                    borderRadius: BorderRadius.circular(20),
                    color: accentColor.withOpacity(0.08),
                  ),
                  child: const Text(
                    'Hungry?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Headline
                const Text(
                  'JUST COME TO PAPICHULO & ORDER.',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                // Subtext
                const Text(
                  'Here You Will Find All The Best Quality And Pure Food. Order Now To Satisfy Your Hunger Pangs.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                // Buttons
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Order now.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: darkText, width: 2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Explore More',
                            style: TextStyle(
                              color: darkText,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20, color: darkText),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right - Decorative Circles
          Expanded(
            flex: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft glow background
                Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withOpacity(0.20),
                        accentColor.withOpacity(0.05),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                // Large outline
                Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(0.35), width: 3),
                    color: Colors.transparent,
                  ),
                ),
                // Medium Circle
                Positioned(
                  top: 100,
                  right: 100,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withOpacity(0.28), width: 3),
                      color: accentColor.withOpacity(0.06),
                    ),
                  ),
                ),
                // Small Circles
                Positioned(
                  top: 50,
                  right: 200,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withOpacity(0.25), width: 2),
                      color: accentColor.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100,
                  right: 50,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withOpacity(0.25), width: 2),
                      color: accentColor.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 50,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withOpacity(0.25), width: 2),
                      color: accentColor.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 100,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withOpacity(0.25), width: 2),
                      color: accentColor.withOpacity(0.08),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedItems() {
    final featuredItems = papichuloMenu.take(4).toList();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          Row(
            children: featuredItems.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildFeaturedCard(item),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(dynamic item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Placeholder
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.fastfood, size: 50));
                      },
                    ),
                  )
                : const Center(child: Icon(Icons.fastfood, size: 50)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is an excellent chicken burger that is very healthy.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseUs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          const Text(
            'WHY CHOOSE US?',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You will choose us because we provide the best quality food from us and we deliver fast.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _buildWhyChooseCard(
                  icon: Icons.health_and_safety_rounded,
                  title: 'Serve Healthy Food',
                  description: 'We serve all healthy food here. You can choose any food you like.',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildWhyChooseCard(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Best Quality',
                  description: 'We provide the best quality food from us and we deliver fast.',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildWhyChooseCard(
                  icon: Icons.local_shipping_rounded,
                  title: 'Fast Delivery',
                  description: 'We deliver your food quickly and safely to your doorstep.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(0.1),
            ),
            child: Icon(icon, size: 40, color: accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialMenu() {
    final specialItems = papichuloMenu.where((item) => item.category == 'Specials').take(3).toList();
    if (specialItems.isEmpty) {
      specialItems.addAll(papichuloMenu.take(3));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          const Text(
            'SPECIAL MENU',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Some of our special food menus are given here. these are what people you can order from here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: specialItems.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildSpecialMenuCard(item),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPaginationDot(0 == specialMenuPage),
              const SizedBox(width: 8),
              _buildPaginationDot(1 == specialMenuPage),
              const SizedBox(width: 8),
              _buildPaginationDot(2 == specialMenuPage),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialMenuCard(dynamic item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.fastfood, size: 50));
                      },
                    ),
                  )
                : const Center(child: Icon(Icons.fastfood, size: 50)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(150)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shopping_bag, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularFood() {
    final regularItems = papichuloMenu.take(6).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          const Text(
            'OUR REGULAR FOOD',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This is our daily food list. Here you will find all kinds of favorite food and order.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          // First Row
          Row(
            children: regularItems.take(3).map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildRegularFoodCard(item),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Second Row
          Row(
            children: regularItems.skip(3).take(3).map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildRegularFoodCard(item),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPaginationDot(0 == regularFoodPage),
              const SizedBox(width: 8),
              _buildPaginationDot(1 == regularFoodPage),
              const SizedBox(width: 8),
              _buildPaginationDot(2 == regularFoodPage),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegularFoodCard(dynamic item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.fastfood, size: 50));
                      },
                    ),
                  )
                : const Center(child: Icon(Icons.fastfood, size: 50)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(5, (index) => const Icon(Icons.star, size: 14, color: Colors.amber)),
                    const SizedBox(width: 4),
                    Text(
                      '(150)',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'This is a great green salad that is very healthy. You can eat it with any meal.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialChefs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          const Text(
            'OUR SPECIAL CHEF\'S',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Featured below are some of our special chefs who work to prepare your meals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, size: 80, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, size: 80, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[900],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Menu Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _footerLink('Home'),
              _footerLink('Why Choose'),
              _footerLink('Special Menu'),
              _footerLink('Regular Food'),
              _footerLink('Special Chef\'s'),
            ],
          ),

          // Help Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Help',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _footerLink('Privacy'),
              _footerLink('Terms & Condition'),
              _footerLink('Policy'),
            ],
          ),

          // Contact Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '+123-456 789',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'info@papichulo.com',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '1245, New York, USA',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),

          // Newsletter Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subscribe Our Newsletter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter Your Email',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Subscribe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPaginationDot(bool isActive) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? accentColor : Colors.grey[300],
      ),
    );
  }
}
