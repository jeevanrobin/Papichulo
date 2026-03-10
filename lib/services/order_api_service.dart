import 'dart:convert';
import 'dart:convert';
import '../models/cart_item.dart';
import '../models/delivery_config.dart';
import '../models/order_record.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'auth_service.dart';

class OrderApiService {
  final ApiClient _api;

  OrderApiService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  Map<String, String> _authHeaders() {
    final token = AuthService.instance.authToken;
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  Map<String, String> _adminHeaders() {
    if (ApiConfig.adminKey.isEmpty) return const {};
    return {'x-admin-key': ApiConfig.adminKey};
  }

  Map<String, String> _allHeaders() => {
        ..._authHeaders(),
        ..._adminHeaders(),
      };

  Future<List<Map<String, dynamic>>> fetchMenu() async {
    final response = await _api.get('/menu', headers: _allHeaders());
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    throw Exception('Invalid menu response format');
  }

  Future<List<Map<String, dynamic>>> fetchAdminMenu() async {
    final response = await _api.get('/admin/menu', headers: _allHeaders());
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
    final response = await _api.post(
      '/admin/menu',
      {
        'name': name,
        'category': category,
        'type': type,
        'ingredients': ingredients,
        'imageUrl': imageUrl,
        'price': price,
        'rating': rating,
        'available': available,
      },
      headers: _allHeaders(),
    );
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
    final response =
        await _api.put('/admin/menu/$id', payload, headers: _allHeaders());
    final decoded = jsonDecode(response.body);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw Exception('Invalid update menu response format');
  }

  Future<void> deleteAdminMenuItem(int id) async {
    await _api.delete('/admin/menu/$id', headers: _allHeaders());
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

    final response =
        await _api.post('/orders', payload, headers: _allHeaders());
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return OrderRecord.fromJson(decoded);
    }
    throw Exception('Invalid order response format');
  }

  Future<List<OrderRecord>> fetchOrders() async {
    final response = await _api.get('/orders', headers: _allHeaders());
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map((e) => OrderRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Invalid orders response format');
  }

  Future<List<OrderRecord>> fetchMyOrders() async {
    final response = await _api.get('/my/orders', headers: _allHeaders());
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map((e) => OrderRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Invalid my orders response format');
  }

  Future<DeliveryConfig> fetchDeliveryConfig() async {
    final response =
        await _api.get('/delivery-config', headers: _allHeaders());
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
    final response = await _api.put(
      '/delivery-config',
      {
        'storeLatitude': storeLatitude,
        'storeLongitude': storeLongitude,
        'radiusKm': radiusKm,
      },
      headers: _allHeaders(),
    );
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return DeliveryConfig.fromJson(decoded);
    }
    throw Exception('Invalid delivery config response format');
  }

  Future<GeocodeResult> geocodeAddress(String address) async {
    final encoded = Uri.encodeQueryComponent(address);
    final response =
        await _api.get('/geocode?address=$encoded', headers: _allHeaders());
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
    final response = await _api.get(
      '/reverse-geocode?lat=$latitude&lng=$longitude',
      headers: _allHeaders(),
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
    await _api.patch(
      '/orders/$orderId/status',
      {'status': status},
      headers: _allHeaders(),
    );
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
