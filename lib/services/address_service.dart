import 'dart:convert';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/saved_address.dart';

// Conditional import for web localStorage
import 'local_address_storage_stub.dart'
    if (dart.library.html) 'local_address_storage_web.dart' as platform_storage;

class AddressService extends ChangeNotifier {
  AddressService._();
  static final AddressService instance = AddressService._();

  List<SavedAddress> _addresses = [];
  List<SavedAddress> get addresses => List.unmodifiable(_addresses);
  String? _selectedAddressId;
  String? get selectedAddressId => _selectedAddressId;
  SavedAddress? get selectedAddress {
    final id = _selectedAddressId;
    if (id == null || id.isEmpty) return null;
    return getById(id);
  }

  bool _loaded = false;

  Future<void> loadAddresses() async {
    if (_loaded) return;
    try {
      final raw = platform_storage.readAddresses();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          // Backward compatibility with older payload shape.
          _addresses = decoded
              .map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (decoded is Map<String, dynamic>) {
          final list = decoded['addresses'];
          if (list is List) {
            _addresses = list
                .map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          _selectedAddressId = decoded['selectedAddressId']?.toString();
        }
      }
    } catch (e) {
      debugPrint('[AddressService] Error loading addresses: $e');
    }
    _normalizeSelectedAddress();
    _loaded = true;
    notifyListeners();
  }

  void _persist() {
    try {
      final json = jsonEncode({
        'addresses': _addresses.map((a) => a.toJson()).toList(),
        'selectedAddressId': _selectedAddressId,
      });
      platform_storage.writeAddresses(json);
    } catch (e) {
      debugPrint('[AddressService] Error persisting addresses: $e');
    }
  }

  void addAddress(SavedAddress address) {
    _addresses.add(address);
    _selectedAddressId ??= address.id;
    _persist();
    notifyListeners();
  }

  void updateAddress(SavedAddress updated) {
    final idx = _addresses.indexWhere((a) => a.id == updated.id);
    if (idx >= 0) {
      _addresses[idx] = updated;
      _persist();
      notifyListeners();
    }
  }

  void deleteAddress(String id) {
    _addresses.removeWhere((a) => a.id == id);
    if (_selectedAddressId == id) {
      _selectedAddressId = _addresses.isEmpty ? null : _addresses.first.id;
    }
    _persist();
    notifyListeners();
  }

  void setSelectedAddress(String? id) {
    if (id == null || id.isEmpty) {
      _selectedAddressId = null;
      _persist();
      notifyListeners();
      return;
    }
    if (_addresses.any((a) => a.id == id)) {
      _selectedAddressId = id;
      _persist();
      notifyListeners();
    }
  }

  SavedAddress? getById(String id) {
    try {
      return _addresses.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void _normalizeSelectedAddress() {
    if (_addresses.isEmpty) {
      _selectedAddressId = null;
      return;
    }
    if (_selectedAddressId == null ||
        !_addresses.any((a) => a.id == _selectedAddressId)) {
      _selectedAddressId = _addresses.first.id;
    }
  }
}
