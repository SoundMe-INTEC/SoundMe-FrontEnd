import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/integration/network/auth_interceptor.dart';
import 'package:soundme_frontend/integration/network/token_storage.dart';

// =============================================================================
// In-memory TokenStorage for tests (no flutter_secure_storage dependency).
// =============================================================================
class FakeTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

// =============================================================================
// Tracking handler wrappers — intercept handler calls for assertions.
// =============================================================================

/// Tracks calls to [RequestInterceptorHandler].
class TrackingRequestHandler extends RequestInterceptorHandler {
  RequestOptions? nextOptions;
  Response<dynamic>? resolvedResponse;
  DioException? rejectedError;

  @override
  void next(RequestOptions requestOptions) {
    nextOptions = requestOptions;
  }

  @override
  void resolve(Response response, [bool callFollowingResponseInterceptor = false]) {
    resolvedResponse = response;
  }

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {
    rejectedError = error;
  }
}

/// Tracks calls to [ErrorInterceptorHandler].
class TrackingErrorHandler extends ErrorInterceptorHandler {
  DioException? nextError;
  Response<dynamic>? resolvedResponse;
  DioException? rejectedError;

  @override
  void next(DioException err) {
    nextError = err;
  }

  @override
  void resolve(Response response) {
    resolvedResponse = response;
  }

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {
    rejectedError = error;
  }
}

// =============================================================================
// Helpers
// =============================================================================

RequestOptions _makeOptions([String path = '/test']) =>
    RequestOptions(path: path, baseUrl: 'http://localhost:8000/api');

DioException _make401(RequestOptions options) => DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 401,
        data: {'detail': 'Token expired'},
      ),
      type: DioExceptionType.badResponse,
    );

DioException _make500(RequestOptions options) => DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 500,
        data: {'detail': 'Internal server error'},
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  late FakeTokenStorage tokenStorage;
  late Dio refreshDio;
  late AuthInterceptor interceptor;

  setUp(() {
    tokenStorage = FakeTokenStorage()
      ..accessToken = 'initial_access'
      ..refreshToken = 'initial_refresh';

    refreshDio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8000/api',
    ));

    interceptor = AuthInterceptor(
      tokenStorage: tokenStorage,
      refreshDio: refreshDio,
    );
  });

  group('onRequest', () {
    test('attaches Bearer token to request headers', () async {
      final options = _makeOptions();
      final handler = TrackingRequestHandler();

      interceptor.onRequest(options, handler);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(options.headers['Authorization'], equals('Bearer initial_access'));
      expect(handler.nextOptions, isNotNull);
    });

    test('skips injection when Authorization header already exists', () async {
      final options = _makeOptions();
      options.headers['Authorization'] = 'Bearer custom_token';
      final handler = TrackingRequestHandler();

      interceptor.onRequest(options, handler);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(options.headers['Authorization'], equals('Bearer custom_token'));
      expect(handler.nextOptions, isNotNull);
    });

    test('does not attach header when no token stored', () async {
      tokenStorage.accessToken = null;
      final options = _makeOptions();
      final handler = TrackingRequestHandler();

      interceptor.onRequest(options, handler);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(options.headers.containsKey('Authorization'), isFalse);
      expect(handler.nextOptions, isNotNull);
    });
  });

  group('onError', () {
    test('non-401 errors are forwarded via handler.next', () async {
      final options = _makeOptions();
      final error = _make500(options);
      final handler = TrackingErrorHandler();

      interceptor.onError(error, handler);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(handler.nextError, isNotNull);
      expect(handler.nextError!.response?.statusCode, equals(500));
      // Tokens remain intact — no refresh attempted.
      expect(tokenStorage.accessToken, equals('initial_access'));
      expect(tokenStorage.refreshToken, equals('initial_refresh'));
    });

    test('401 clears tokens when refresh token is missing', () async {
      tokenStorage.refreshToken = null;
      final options = _makeOptions();
      final error = _make401(options);
      final handler = TrackingErrorHandler();

      interceptor.onError(error, handler);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Tokens should be cleared because refresh is not possible.
      expect(tokenStorage.accessToken, isNull);
      // The error should be forwarded.
      expect(handler.nextError, isNotNull);
    });
  });

  group('TokenStorage contract', () {
    test('save and retrieve works', () async {
      final storage = FakeTokenStorage();
      await storage.saveTokens(accessToken: 'a1', refreshToken: 'r1');

      expect(await storage.getAccessToken(), equals('a1'));
      expect(await storage.getRefreshToken(), equals('r1'));
    });

    test('clearTokens works', () async {
      final storage = FakeTokenStorage()
        ..accessToken = 'a'
        ..refreshToken = 'r';

      await storage.clearTokens();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });
  });
}
