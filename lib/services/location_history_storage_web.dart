// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const _key = 'papichulo_location_history';

String? readHistory() => html.window.localStorage[_key];

void writeHistory(String json) {
  html.window.localStorage[_key] = json;
}
