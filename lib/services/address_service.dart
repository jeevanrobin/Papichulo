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

  bool _loaded = false;

  Future<void> loadAddresses() async {
    if (_loaded) return;
    try {
      final raw = platform_storage.readAddresses();
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _addresses =
            list.map((e) => SavedAddress.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[AddressService] Error loading addresses: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  void _persist() {
    try {
      final json = jsonEncode(_addresses.map((a) => a.toJson()).toList());
      platform_storage.writeAddresses(json);
    } catch (e) {
      debugPrint('[AddressService] Error persisting addresses: $e');
    }
  }

  void addAddress(SavedAddress address) {
    _addresses.add(address);
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
    _persist();
    notifyListeners();
  }

  SavedAddress? getById(String id) {
    try {
      return _addresses.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
