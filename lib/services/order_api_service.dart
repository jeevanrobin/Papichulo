import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cart_item.dart';
import '../models/order_record.dart';
import 'api_config.dart';

class OrderApiService {
  final http.Client _client;

  OrderApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> fetchMenu() async {
    final response = await _client.get(Uri.parse('${ApiConfig.baseUrl}/menu'));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      throw Exception('Invalid menu response format');
    }
    throw Exception('Failed to fetch menu (${response.statusCode})');
  }

  Future<OrderRecord> createOrder({
    required String customerName,
    required String phone,
    required String address,
    required String paymentMethod,
    required List<CartItem> items,
    required double totalAmount,
  }) async {
    final payload = {
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'paymentMethod': paymentMethod,
      'items': items
          .map(
            (item) => {
              'name': item.foodItem.name,
              'price': item.foodItem.price,
              'quantity': item.quantity,
            },
          )
          .toList(),
      'totalAmount': totalAmount,
    };

    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return OrderRecord.fromJson(decoded);
      }
      throw Exception('Invalid order response format');
    }
    throw Exception('Failed to create order (${response.statusCode})');
  }

  Future<List<OrderRecord>> fetchOrders() async {
    final response = await _client.get(Uri.parse('${ApiConfig.baseUrl}/orders'));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((e) => OrderRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Invalid orders response format');
    }
    throw Exception('Failed to fetch orders (${response.statusCode})');
  }
}
