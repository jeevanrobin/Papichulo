import 'dart:html' as html;

const _favStorageKey = 'papichulo_favourites_v1';

Future<void> saveFavourites(String value) async {
  html.window.localStorage[_favStorageKey] = value;
}

Future<String?> readFavourites() async {
  return html.window.localStorage[_favStorageKey];
}

Future<void> clearFavourites() async {
  html.window.localStorage.remove(_favStorageKey);
}
