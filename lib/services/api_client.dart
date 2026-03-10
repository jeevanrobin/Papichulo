import 'dart:convert';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Shared HTTP client with multi-base-URL fallback.
///
/// Consolidates the duplicated `_getWithFallback`, `_postWithFallback`, etc.
/// logic from [AuthService] and [OrderApiService] into a single reusable class.
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  List<String> get _baseUrls => ApiConfig.candidateBaseUrls();

  /// Perform an HTTP request with automatic fallback across candidate base
  /// URLs. Returns the first successful (2xx) response.
  Future<http.Response> request(
    String method,
    String path, {
    Object? payload,
    Map<String, String>? headers,
  }) async {
    Exception? httpError;
    Exception? lastNetworkError;
    var hadNetworkError = false;
    var hadHttpResponse = false;

    for (final baseUrl in _baseUrls) {
      try {
        final uri = Uri.parse('$baseUrl$path');
        final mergedHeaders = <String, String>{
          if (payload != null) 'Content-Type': 'application/json',
          ...?headers,
        };
        final encodedBody = payload != null ? jsonEncode(payload) : null;

        final http.Response response;
        switch (method.toUpperCase()) {
          case 'GET':
            response = await _client.get(uri, headers: mergedHeaders);
          case 'POST':
            response = await _client.post(uri,
                headers: mergedHeaders, body: encodedBody);
          case 'PUT':
            response = await _client.put(uri,
                headers: mergedHeaders, body: encodedBody);
          case 'PATCH':
            response = await _client.patch(uri,
                headers: mergedHeaders, body: encodedBody);
          case 'DELETE':
            response = await _client.delete(uri, headers: mergedHeaders);
          default:
            throw ArgumentError('Unsupported HTTP method: $method');
        }

        hadHttpResponse = true;
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        httpError ??= Exception(_extractError(response, baseUrl, path));
      } catch (error) {
        if (error is Exception &&
            error.toString().contains('Unsupported HTTP method')) {
          rethrow;
        }
        hadNetworkError = true;
        lastNetworkError = Exception(error.toString());
      }
    }

    if (hadHttpResponse && httpError != null) {
      throw httpError;
    }
    if (hadNetworkError && !hadHttpResponse) {
      throw Exception(
        'Unable to reach backend. Start backend and verify API URL. '
        'Tried: ${_baseUrls.join(', ')}',
      );
    }
    throw lastNetworkError ?? Exception('Request failed ($path)');
  }

  // Convenience methods -------------------------------------------------

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
  }) =>
      request('GET', path, headers: headers);

  Future<http.Response> post(
    String path,
    Object payload, {
    Map<String, String>? headers,
  }) =>
      request('POST', path, payload: payload, headers: headers);

  Future<http.Response> put(
    String path,
    Object payload, {
    Map<String, String>? headers,
  }) =>
      request('PUT', path, payload: payload, headers: headers);

  Future<http.Response> patch(
    String path,
    Object payload, {
    Map<String, String>? headers,
  }) =>
      request('PATCH', path, payload: payload, headers: headers);

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) =>
      request('DELETE', path, headers: headers);

  // Error extraction ----------------------------------------------------

  String _extractError(http.Response response, String baseUrl, String path) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map &&
          decoded['error'] is Map &&
          (decoded['error'] as Map)['message'] != null) {
        final message = (decoded['error'] as Map)['message'].toString();
        return '$message [$baseUrl$path]';
      }
    } catch (_) {}
    return 'Request failed [$baseUrl$path] (${response.statusCode})';
  }
}
