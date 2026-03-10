import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:papichulo/services/api_client.dart';
import 'package:papichulo/services/api_config.dart';

void main() {
  group('ApiClient', () {
    test('request returns first successful response across fallback URLs', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        final urlString = request.url.toString();

        if (urlString.startsWith(ApiConfig.baseUrl)) {
          return http.Response('{"error":"down"}', 500);
        }

        if (urlString.startsWith(ApiConfig.localEmulatorBaseUrl)) {
          throw Exception('Connection Refused');
        }

        if (urlString.startsWith(ApiConfig.localLoopbackBaseUrl)) {
          return http.Response('{"success": true}', 200);
        }

        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final response = await apiClient.get('/test');
      
      expect(response.statusCode, 200);
      expect(response.body, '{"success": true}');
      expect(requestCount, 3); // baseUrl -> emulator -> loopback
    });

    test('request throws combined exception if all fallbacks fail', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network Error');
      });

      final apiClient = ApiClient(client: mockClient);
      
      expect(
        () => apiClient.get('/test'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Unable to reach backend'),
        )),
      );
    });

    test('extracts detailed API error message from JSON for 4xx/5xx responses', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": {"message": "Invalid token"}}', 401);
      });

      final apiClient = ApiClient(client: mockClient);
      
      expect(
        () => apiClient.get('/test'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid token'),
        )),
      );
    });
  });
}
