import 'local_fav_storage_stub.dart'
    if (dart.library.html) 'local_fav_storage_web.dart' as impl;

class LocalFavStorage {
  Future<void> saveFavourites(String value) => impl.saveFavourites(value);
  Future<String?> readFavourites() => impl.readFavourites();
  Future<void> clearFavourites() => impl.clearFavourites();
}
