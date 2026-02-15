import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/order_api_service.dart';

class MenuAdminScreen extends StatefulWidget {
  const MenuAdminScreen({super.key});

  @override
  State<MenuAdminScreen> createState() => _MenuAdminScreenState();
}

class _MenuAdminScreenState extends State<MenuAdminScreen> {
  final OrderApiService _api = OrderApiService();
  late Future<List<Map<String, dynamic>>> _future;
  static const List<String> _categories = <String>[
    'Pizza',
    'Burgers',
    'Sandwiches',
    'Hot Dogs',
    'Snacks',
    'Specials',
  ];

  @override
  void initState() {
    super.initState();
    _future = _api.fetchAdminMenu();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _api.fetchAdminMenu();
    });
  }

  Future<void> _toggleAvailability(
    Map<String, dynamic> item,
    bool value,
  ) async {
    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;
    try {
      await _api.updateAdminMenuItem(id: id, payload: {'available': value});
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update availability: $error')),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;
    try {
      await _api.deleteAdminMenuItem(id);
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete item: $error')));
    }
  }

  Future<void> _showItemEditor({Map<String, dynamic>? item}) async {
    final isEdit = item != null;
    final nameController = TextEditingController(
      text: (item?['name'] ?? '').toString(),
    );
    final ingredientsController = TextEditingController(
      text: ((item?['ingredients'] as List?) ?? const []).join(', '),
    );
    final priceController = TextEditingController(
      text: (item?['price'] ?? '').toString(),
    );
    final ratingController = TextEditingController(
      text: (item?['rating'] ?? 4.5).toString(),
    );
    String category = (item?['category'] ?? _categories.first).toString();
    if (!_categories.contains(category)) {
      category = _categories.first;
    }
    String type = (item?['type'] ?? 'Veg').toString();
    bool available = (item?['available'] ?? true) == true;
    String imageData = (item?['imageUrl'] ?? '').toString();
    String imageFileName = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                withData: true,
                allowMultiple: false,
              );
              if (result == null || result.files.isEmpty) return;
              final file = result.files.single;
              final bytes = file.bytes;
              if (bytes == null || bytes.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Could not read image file')),
                );
                return;
              }
              final ext = (file.extension ?? '').toLowerCase();
              final mime = switch (ext) {
                'jpg' || 'jpeg' => 'image/jpeg',
                'png' => 'image/png',
                'webp' => 'image/webp',
                'gif' => 'image/gif',
                _ => 'image/png',
              };
              final encoded = base64Encode(bytes);
              setDialogState(() {
                imageData = 'data:$mime;base64,$encoded';
                imageFileName = file.name;
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1F1F1F),
              title: Text(
                isEdit ? 'Edit Menu Item' : 'Add Menu Item',
                style: const TextStyle(color: Color(0xFFFFD700)),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _input(nameController, 'Name'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        items: _categories
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) => setDialogState(
                          () => category = value ?? _categories.first,
                        ),
                        decoration: _inputDecoration('Category'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        items: const [
                          DropdownMenuItem(value: 'Veg', child: Text('Veg')),
                          DropdownMenuItem(
                            value: 'Non-Veg',
                            child: Text('Non-Veg'),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => type = value ?? 'Veg'),
                        decoration: _inputDecoration('Type'),
                      ),
                      const SizedBox(height: 8),
                      _input(
                        ingredientsController,
                        'Ingredients (comma separated)',
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: pickImage,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Image'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFD700),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                      if (imageFileName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            imageFileName,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (imageData.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageData,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: double.infinity,
                                  height: 120,
                                  color: Colors.black26,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Image preview unavailable',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _input(
                        priceController,
                        'Price',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      _input(
                        ratingController,
                        'Rating (0-5)',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: available,
                        onChanged: (value) =>
                            setDialogState(() => available = value),
                        activeThumbColor: const Color(0xFFFFD700),
                        title: const Text(
                          'Available',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final price = double.tryParse(priceController.text.trim());
                    final rating =
                        double.tryParse(ratingController.text.trim()) ?? 4.5;
                    final ingredients = ingredientsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    if (nameController.text.trim().isEmpty ||
                        price == null ||
                        ingredients.isEmpty ||
                        imageData.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill all required fields and upload image',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      if (isEdit) {
                        await _api.updateAdminMenuItem(
                          id: (item['id'] as num).toInt(),
                          payload: {
                            'name': nameController.text.trim(),
                            'category': category,
                            'type': type,
                            'ingredients': ingredients,
                            'imageUrl': imageData,
                            'price': price,
                            'rating': rating,
                            'available': available,
                          },
                        );
                      } else {
                        await _api.createAdminMenuItem(
                          name: nameController.text.trim(),
                          category: category,
                          type: type,
                          ingredients: ingredients,
                          imageUrl: imageData,
                          price: price,
                          rating: rating,
                          available: available,
                        );
                      }

                      if (!context.mounted) return;
                      Navigator.pop(dialogContext);
                      await _reload();
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Save failed: $error')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(isEdit ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFFD700)),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: ElevatedButton.icon(
              onPressed: _reload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
          );
        }

        final menuItems = snapshot.data ?? const <Map<String, dynamic>>[];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Menu Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showItemEditor(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: menuItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    final title = (item['name'] ?? '').toString();
                    final category = (item['category'] ?? '').toString();
                    final type = (item['type'] ?? '').toString();
                    final price = (item['price'] as num?)?.toDouble() ?? 0;
                    final available = item['available'] == true;
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(
                            0xFFFFD700,
                          ).withValues(alpha: 0.12),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$category | $type | Rs ${price.toStringAsFixed(0)}',
                                  style: TextStyle(color: Colors.grey[300]),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: available,
                            onChanged: (value) =>
                                _toggleAvailability(item, value),
                            activeThumbColor: const Color(0xFFFFD700),
                          ),
                          IconButton(
                            onPressed: () => _showItemEditor(item: item),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.amber,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _delete(item),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
