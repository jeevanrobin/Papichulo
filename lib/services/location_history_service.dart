import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'location_history_storage_stub.dart'
    if (dart.library.html) 'location_history_storage_web.dart'
        as storage;

class LocationHistoryEntry {
  final String label;
  final double latitude;
  final double longitude;

  const LocationHistoryEntry({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory LocationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LocationHistoryEntry(
      label: (json['label'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LocationHistoryService extends ChangeNotifier {
  LocationHistoryService._();
  static final LocationHistoryService instance = LocationHistoryService._();

  final List<LocationHistoryEntry> _entries = [];
  bool _loaded = false;

  List<LocationHistoryEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = storage.readHistory();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _entries
            ..clear()
            ..addAll(decoded
                .whereType<Map>()
                .map((e) => LocationHistoryEntry.fromJson(
                    Map<String, dynamic>.from(e)))
                .where((e) =>
                    e.label.isNotEmpty &&
                    e.latitude != 0 &&
                    e.longitude != 0));
        }
      }
    } catch (e) {
      debugPrint('[LocationHistory] load error: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  void add(LocationHistoryEntry entry) {
    // Deduplicate by label and coordinates.
    _entries.removeWhere((e) =>
        e.label.toLowerCase() == entry.label.toLowerCase() &&
        (e.latitude - entry.latitude).abs() < 0.0001 &&
        (e.longitude - entry.longitude).abs() < 0.0001);
    _entries.insert(0, entry);
    if (_entries.length > 6) {
      _entries.removeRange(6, _entries.length);
    }
    _persist();
    notifyListeners();
  }

  void _persist() {
    try {
      final json = jsonEncode(_entries.map((e) => e.toJson()).toList());
      storage.writeHistory(json);
    } catch (e) {
      debugPrint('[LocationHistory] persist error: $e');
    }
  }
}
