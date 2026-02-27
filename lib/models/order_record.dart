class OrderLineItem {
  final String name;
  final double price;
  final int quantity;

  const OrderLineItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class OrderRecord {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final String paymentMethod;
  final String status;
  final double totalAmount;
  final int itemCount;
  final List<OrderLineItem> items;
  final DateTime createdAt;

  OrderRecord({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.paymentMethod,
    required this.status,
    required this.totalAmount,
    required this.itemCount,
    required this.items,
    required this.createdAt,
  });

  factory OrderRecord.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?) ?? const [];
    final items = itemsJson
        .whereType<Map>()
        .map(
          (entry) => OrderLineItem.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();
    final itemCountFromQuantity = items.fold<int>(
      0,
      (sum, item) => sum + (item.quantity > 0 ? item.quantity : 0),
    );

    return OrderRecord(
      id: (json['id'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      status: (json['status'] ?? 'new').toString(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      itemCount: itemCountFromQuantity > 0
          ? itemCountFromQuantity
          : items.length,
      items: items,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
