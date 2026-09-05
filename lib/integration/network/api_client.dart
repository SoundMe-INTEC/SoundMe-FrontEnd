import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Singleton HTTP client built on [Dio] with SLA-compliant timeouts.
///
/// Configuration is injected from `.env`:
///   - `API_BASE_URL` — base URL for all REST calls.
///
/// Timeouts enforce the ≤ 3 s total latency SLA:
///   - connectTimeout : 5 000 ms
///   - receiveTimeout : 3 000 ms
///   - sendTimeout    : 5 000 ms
class DioApiClient {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  static DioApiClient? _instance;

  /// Returns (and lazily creates) the singleton [DioApiClient].
  ///
  /// [interceptors] are appended **once** during creation.  Passing them on
  /// subsequent calls is a no-op — the already-configured instance is returned.
  factory DioApiClient({List<Interceptor>? interceptors}) {
    _instance ??= DioApiClient._internal(interceptors: interceptors);
    return _instance!;
  }

  /// Resets the singleton.  **Only use in tests.**
  @visibleForTesting
  static void resetInstance() => _instance = null;

  /// Creates a **non-singleton** instance.
  ///
  /// Intended for DI containers (e.g. Riverpod) that manage object lifecycle
  /// externally and don't need the singleton guarantee.
  static DioApiClient create({List<Interceptor>? interceptors}) {
    return DioApiClient._internal(interceptors: interceptors);
  }

  // ---------------------------------------------------------------------------
  // Internal constructor
  // ---------------------------------------------------------------------------
  DioApiClient._internal({List<Interceptor>? interceptors}) {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: 5000),
        receiveTimeout: const Duration(milliseconds: 3000),
        sendTimeout: const Duration(milliseconds: 5000),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Append caller-supplied interceptors (e.g. AuthInterceptor).
    if (interceptors != null) {
      _dio.interceptors.addAll(interceptors);
    }

    // Debug-only request/response logger.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }
  }

  late final Dio _dio;

  /// Exposes the raw [Dio] instance for advanced use-cases (e.g. downloads).
  Dio get dio => _dio;

  // ---------------------------------------------------------------------------
  // Convenience HTTP verbs
  // ---------------------------------------------------------------------------

  /// Performs a GET request to [path] with optional [queryParameters].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  /// Performs a POST request to [path] with optional [data] body.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return _dio.post<T>(path, data: data, options: options);
  }

  /// Performs a PUT request to [path] with optional [data] body.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return _dio.put<T>(path, data: data, options: options);
  }

  /// Performs a DELETE request to [path].
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return _dio.delete<T>(path, data: data, options: options);
  }
}
