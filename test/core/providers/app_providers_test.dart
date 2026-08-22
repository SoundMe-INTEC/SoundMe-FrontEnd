import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soundme_frontend/core/providers/app_providers.dart';
import 'package:soundme_frontend/integration/network/api_client.dart';
import 'package:soundme_frontend/integration/network/auth_interceptor.dart';
import 'package:soundme_frontend/integration/network/token_storage.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
  });

  tearDown(() {
    DioApiClient.resetInstance();
  });

  group('app_providers', () {
    test('tokenStorageProvider resolves to a SecureTokenStorage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final storage = container.read(tokenStorageProvider);
      expect(storage, isA<TokenStorage>());
      expect(storage, isA<SecureTokenStorage>());
    });

    test('refreshDioProvider resolves to a Dio instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio = container.read(refreshDioProvider);
      expect(dio, isA<Dio>());
      expect(
        dio.options.connectTimeout,
        equals(const Duration(milliseconds: 5000)),
      );
    });

    test('authInterceptorProvider resolves to an AuthInterceptor', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final interceptor = container.read(authInterceptorProvider);
      expect(interceptor, isA<AuthInterceptor>());
    });

    test('apiServiceProvider resolves to a DioApiClient', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(apiServiceProvider);
      expect(client, isA<DioApiClient>());
    });

    test('apiServiceProvider includes AuthInterceptor in Dio interceptors', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(apiServiceProvider);
      final hasAuthInterceptor = client.dio.interceptors.any(
        (i) => i is AuthInterceptor,
      );
      expect(hasAuthInterceptor, isTrue);
    });

    test('same container returns consistent singleton for apiServiceProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(apiServiceProvider);
      final second = container.read(apiServiceProvider);
      expect(identical(first, second), isTrue);
    });
  });
}
