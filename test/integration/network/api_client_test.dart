import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/integration/network/api_client.dart';

void main() {
  setUpAll(() async {
    // Load .env from the project root for tests.
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
  });

  tearDown(() {
    // Reset singleton between tests so each test gets a clean instance.
    DioApiClient.resetInstance();
  });

  group('DioApiClient', () {
    test('factory returns the same singleton instance', () {
      final a = DioApiClient();
      final b = DioApiClient();
      expect(identical(a, b), isTrue);
    });

    test('connect timeout is 5000ms', () {
      final client = DioApiClient();
      expect(
        client.dio.options.connectTimeout,
        equals(const Duration(milliseconds: 5000)),
      );
    });

    test('receive timeout is 3000ms', () {
      final client = DioApiClient();
      expect(
        client.dio.options.receiveTimeout,
        equals(const Duration(milliseconds: 3000)),
      );
    });

    test('send timeout is 5000ms', () {
      final client = DioApiClient();
      expect(
        client.dio.options.sendTimeout,
        equals(const Duration(milliseconds: 5000)),
      );
    });

    test('base URL is loaded from dotenv', () {
      final client = DioApiClient();
      final expected = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api';
      expect(client.dio.options.baseUrl, equals(expected));
    });

    test('default headers include Content-Type and Accept as JSON', () {
      final client = DioApiClient();
      expect(
        client.dio.options.headers['Content-Type'],
        equals('application/json'),
      );
      expect(
        client.dio.options.headers['Accept'],
        equals('application/json'),
      );
    });

    test('interceptors are appended on creation', () {
      final custom = InterceptorsWrapper();
      final client = DioApiClient(interceptors: [custom]);
      expect(client.dio.interceptors, contains(custom));
    });

    test('resetInstance allows creating a new instance', () {
      final first = DioApiClient();
      DioApiClient.resetInstance();
      final second = DioApiClient();
      expect(identical(first, second), isFalse);
    });
  });
}
