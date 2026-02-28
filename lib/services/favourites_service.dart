import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'local_fav_storage.dart';

/// Manages a set of favourite food item names, persisted to local storage.
class FavouritesService extends ChangeNotifier {
  FavouritesService._();
  static final FavouritesService instance = FavouritesService._();

  final LocalFavStorage _storage = LocalFavStorage();
  final Set<String> _favourites = <String>{};
  bool _loaded = false;

  Set<String> get favourites => Set<String>.unmodifiable(_favourites);
  bool isFavourite(String name) => _favourites.contains(name);

  Future<void> load() async {
    if (_loaded) return;
    final raw = await _storage.readFavourites();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        _favourites.addAll(list);
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String name) async {
    if (_favourites.contains(name)) {
      _favourites.remove(name);
    } else {
      _favourites.add(name);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    await _storage.saveFavourites(jsonEncode(_favourites.toList()));
  }
}
