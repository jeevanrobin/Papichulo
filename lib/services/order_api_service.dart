import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cart_item.dart';
import '../models/delivery_config.dart';
import '../models/order_record.dart';
import 'api_config.dart';
import 'auth_service.dart';

class OrderApiService {
  final http.Client _client;

  OrderApiService({http.Client? client}) : _client = client ?? http.Client();

  List<String> get _baseUrls {
    final primary = ApiConfig.baseUrl;
    final candidates = <String>[primary];

    void addIfMissing(String value) {
      if (!candidates.contains(value)) {
        candidates.add(value);
      }
    }

    if (primary.contains('localhost:3001')) {
      addIfMissing(primary.replaceFirst('localhost:3001', 'localhost:3011'));
    } else if (primary.contains('localhost:3011')) {
      addIfMissing(primary.replaceFirst('localhost:3011', 'localhost:3001'));
    }

    if (primary.contains('127.0.0.1:3001')) {
      addIfMissing(primary.replaceFirst('127.0.0.1:3001', '127.0.0.1:3011'));
    } else if (primary.contains('127.0.0.1:3011')) {
      addIfMissing(primary.replaceFirst('127.0.0.1:3011', '127.0.0.1:3001'));
    }

    for (final url in List<String>.from(candidates)) {
      if (url.contains('localhost')) {
        addIfMissing(url.replaceFirst('localhost', '127.0.0.1'));
      } else if (url.contains('127.0.0.1')) {
        addIfMissing(url.replaceFirst('127.0.0.1', 'localhost'));
      }
    }

    return candidates;
  }

  Future<http.Response> _getWithFallback(String path) async {
    Exception? lastError;
    for (final baseUrl in _baseUrls) {
      try {
        final response = await _client.get(
          Uri.parse('$baseUrl$path'),
          headers: {..._authHeaders(), ..._adminHeaders()},
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
          headers: {
            'Content-Type': 'application/json',
            ..._authHeaders(),
            ..._adminHeaders(),
          },
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
          headers: {
            'Content-Type': 'application/json',
            ..._authHeaders(),
            ..._adminHeaders(),
          },
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
          headers: {
            'Content-Type': 'application/json',
            ..._authHeaders(),
            ..._adminHeaders(),
          },
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

  Map<String, String> _authHeaders() {
    final token = AuthService.instance.authToken;
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
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

  Future<List<Map<String, dynamic>>> fetchAdminMenu() async {
    final response = await _getWithFallback('/admin/menu');
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    throw Exception('Invalid admin menu response format');
  }

  Future<Map<String, dynamic>> createAdminMenuItem({
    required String name,
    required String category,
    required String type,
    required List<String> ingredients,
    required String imageUrl,
    required double price,
    required double rating,
    required bool available,
  }) async {
    final response = await _postWithFallback('/admin/menu', {
      'name': name,
      'category': category,
      'type': type,
      'ingredients': ingredients,
      'imageUrl': imageUrl,
      'price': price,
      'rating': rating,
      'available': available,
    });
    final decoded = jsonDecode(response.body);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw Exception('Invalid create menu response format');
  }

  Future<Map<String, dynamic>> updateAdminMenuItem({
    required int id,
    Map<String, dynamic> payload = const {},
  }) async {
    final response = await _putWithFallback('/admin/menu/$id', payload);
    final decoded = jsonDecode(response.body);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw Exception('Invalid update menu response format');
  }

  Future<void> deleteAdminMenuItem(int id) async {
    Exception? lastError;
    for (final baseUrl in _baseUrls) {
      try {
        final response = await _client.delete(
          Uri.parse('$baseUrl/admin/menu/$id'),
          headers: {..._authHeaders(), ..._adminHeaders()},
        );
        if (response.statusCode == 204 ||
            (response.statusCode >= 200 && response.statusCode < 300)) {
          return;
        }
        lastError = Exception(
          _responseError('/admin/menu/$id', response, baseUrl),
        );
      } catch (error) {
        lastError = Exception(error.toString());
      }
    }
    throw lastError ?? Exception('Request failed (/admin/menu/$id)');
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

  Future<List<OrderRecord>> fetchMyOrders() async {
    final response = await _getWithFallback('/my/orders');
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map((e) => OrderRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Invalid my orders response format');
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
