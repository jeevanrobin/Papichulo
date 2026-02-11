import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cart_item.dart';
import '../models/delivery_config.dart';
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
        final response = await _client.get(
          Uri.parse('$baseUrl$path'),
          headers: _adminHeaders(),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        lastError = Exception(_responseError(path, response, baseUrl));
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
          headers: {'Content-Type': 'application/json', ..._adminHeaders()},
          body: jsonEncode(payload),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        lastError = Exception(_responseError(path, response, baseUrl));
      } catch (error) {
        lastError = Exception(error.toString());
      }
    }
    throw lastError ?? Exception('Request failed ($path)');
  }

  Future<http.Response> _putWithFallback(String path, Object payload) async {
    Exception? lastError;
    for (final baseUrl in _baseUrls) {
      try {
        final response = await _client.put(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json', ..._adminHeaders()},
          body: jsonEncode(payload),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        lastError = Exception(_responseError(path, response, baseUrl));
      } catch (error) {
        lastError = Exception(error.toString());
      }
    }
    throw lastError ?? Exception('Request failed ($path)');
  }

  Future<http.Response> _patchWithFallback(String path, Object payload) async {
    Exception? lastError;
    for (final baseUrl in _baseUrls) {
      try {
        final response = await _client.patch(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json', ..._adminHeaders()},
          body: jsonEncode(payload),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        lastError = Exception(_responseError(path, response, baseUrl));
      } catch (error) {
        lastError = Exception(error.toString());
      }
    }
    throw lastError ?? Exception('Request failed ($path)');
  }

  Map<String, String> _adminHeaders() {
    if (ApiConfig.adminKey.isEmpty) return const {};
    return {'x-admin-key': ApiConfig.adminKey};
  }

  String _responseError(String path, http.Response response, String baseUrl) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded['error'] is Map &&
          (decoded['error'] as Map)['message'] != null) {
        final message = (decoded['error'] as Map)['message'].toString();
        return 'Request failed ($path) [${response.statusCode}] on $baseUrl: $message';
      }
    } catch (_) {}
    return 'Request failed ($path) [${response.statusCode}] on $baseUrl';
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
    required double latitude,
    required double longitude,
    required String paymentMethod,
    required List<CartItem> items,
    required double totalAmount,
  }) async {
    final payload = {
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
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
      return decoded
          .map((e) => OrderRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Invalid orders response format');
  }

  Future<DeliveryConfig> fetchDeliveryConfig() async {
    final response = await _getWithFallback('/delivery-config');
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return DeliveryConfig.fromJson(decoded);
    }
    throw Exception('Invalid delivery config response format');
  }

  Future<DeliveryConfig> updateDeliveryConfig({
    required double storeLatitude,
    required double storeLongitude,
    required double radiusKm,
  }) async {
    final response = await _putWithFallback('/delivery-config', {
      'storeLatitude': storeLatitude,
      'storeLongitude': storeLongitude,
      'radiusKm': radiusKm,
    });
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return DeliveryConfig.fromJson(decoded);
    }
    throw Exception('Invalid delivery config response format');
  }

  Future<GeocodeResult> geocodeAddress(String address) async {
    final encoded = Uri.encodeQueryComponent(address);
    final response = await _getWithFallback('/geocode?address=$encoded');
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return GeocodeResult(
        latitude: (decoded['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (decoded['longitude'] as num?)?.toDouble() ?? 0,
        label: (decoded['label'] ?? '').toString(),
      );
    }
    throw Exception('Invalid geocode response format');
  }

  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _getWithFallback(
      '/reverse-geocode?lat=$latitude&lng=$longitude',
    );
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return (decoded['label'] ?? '').toString();
    }
    throw Exception('Invalid reverse geocode response format');
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _patchWithFallback('/orders/$orderId/status', {'status': status});
  }
}

class GeocodeResult {
  final double latitude;
  final double longitude;
  final String label;

  const GeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.label,
  });
}
