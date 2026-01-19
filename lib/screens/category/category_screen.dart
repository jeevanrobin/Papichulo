import 'package:flutter/material.dart';
import '../../data/menu_data.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String filter = 'Veg';

  @override
  Widget build(BuildContext context) {
    final filteredItems = papichuloMenu
        .where((item) => item.category == widget.category && item.type == filter)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _filterButton('Veg'),
              const SizedBox(width: 12),
              _filterButton('Non-Veg'),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: papichuloMenu
                  .where((item) =>
                      item.category == widget.category &&
                      item.type == filter)
                  .map((item) => Card(
                        color: Colors.grey[900],
                        child: ListTile(
                          title: Text(
                            item.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            item.ingredients.join(', '),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String type) {
    final isActive = filter == type;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isActive ? const Color(0xFFFFC107) : Colors.grey,
        foregroundColor: Colors.black,
      ),
      onPressed: () {
        setState(() {
          filter = type;
        });
      },
      child: Text(type),
    );
  }
}
