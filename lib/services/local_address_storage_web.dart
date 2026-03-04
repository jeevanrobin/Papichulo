// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const _key = 'papichulo_saved_addresses';

String? readAddresses() {
  return html.window.localStorage[_key];
}

void writeAddresses(String json) {
  html.window.localStorage[_key] = json;
}
