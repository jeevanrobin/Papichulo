class OrderRecord {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final String paymentMethod;
  final String status;
  final double totalAmount;
  final int itemCount;
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
    required this.createdAt,
  });

  factory OrderRecord.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?) ?? const [];
    return OrderRecord(
      id: (json['id'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      status: (json['status'] ?? 'new').toString(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      itemCount: items.length,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
