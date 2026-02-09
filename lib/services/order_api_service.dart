import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cart_item.dart';
import '../models/order_record.dart';
import 'api_config.dart';

class OrderApiService {
  final http.Client _client;

  OrderApiService({http.Client? client}) : _client = client ?? http.Client();

  List<String> get _baseUrls {
    final primary = ApiConfig.baseUrl;
    final urls = <String>[primary];
    if (primary.contains('localhost:3001')) {
      urls.add(primary.replaceFirst('localhost:3001', 'localhost:3011'));
    }
    return urls;
  }

  Future<http.Response> _getWithFallback(String path) async {
    Exception? lastError;
    for (final baseUrl in _baseUrls) {
      try {
        final response = await _client.get(Uri.parse('$baseUrl$path'));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        lastError = Exception('Request failed ($path) [${response.statusCode}] on $baseUrl');
      } catch (error) {
        lastError = Exception(error.toString());
      }
    }
    throw lastError ?? Exception('Request failed ($path)');
  }

  Future<http.Response> _postWithFallback(String path, Object payload) async {
    Exception? lastError;
    for (final baseUrl in _baseUrls) {
      try {
        final response = await _client.post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        lastError = Exception('Request failed ($path) [${response.statusCode}] on $baseUrl');
      } catch (error) {
        lastError = Exception(error.toString());
      }
    }
    throw lastError ?? Exception('Request failed ($path)');
  }

  Future<List<Map<String, dynamic>>> fetchMenu() async {
    final response = await _getWithFallback('/menu');
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    throw Exception('Invalid menu response format');
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

    final response = await _postWithFallback('/orders', payload);
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return OrderRecord.fromJson(decoded);
    }
    throw Exception('Invalid order response format');
  }

  Future<List<OrderRecord>> fetchOrders() async {
    final response = await _getWithFallback('/orders');
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.map((e) => OrderRecord.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Invalid orders response format');
  }
}
