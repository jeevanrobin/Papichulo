import 'package:flutter/material.dart';
import '../../data/menu_data.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFF6B35);
    const categories = ['Pizza', 'Burgers', 'Sandwiches', 'Hot Dogs', 'Snacks', 'Specials'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Papichulo Menu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categories.map((category) {
                final items = papichuloMenu.where((item) => item.category == category).toList();
                if (items.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                  child: Container(
                                    height: 70,
                                    color: Colors.grey[200],
                                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            item.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Center(
                                              child: Icon(Icons.fastfood, size: 24),
                                            ),
                                          )
                                        : const Center(child: Icon(Icons.fastfood, size: 24)),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.category,
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '\$${item.price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: accentColor,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Buy Now',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
