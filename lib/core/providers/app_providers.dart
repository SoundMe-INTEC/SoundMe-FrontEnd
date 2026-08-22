import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../integration/network/api_client.dart';
import '../../integration/network/auth_interceptor.dart';
import '../../integration/network/token_storage.dart';

// =============================================================================
// Token Storage
// =============================================================================

/// Provides the singleton [TokenStorage] backed by FlutterSecureStorage.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});

// =============================================================================
// Dio (plain — for refresh calls, no interceptors)
// =============================================================================

/// A bare [Dio] instance used **only** by [AuthInterceptor] for token refresh
/// calls. It shares the same base URL but carries no interceptors, preventing
/// recursive auth loops.
final refreshDioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api';
  return Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(milliseconds: 5000),
    receiveTimeout: const Duration(milliseconds: 3000),
    sendTimeout: const Duration(milliseconds: 5000),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));
});

// =============================================================================
// Auth Interceptor
// =============================================================================

/// Provides the [AuthInterceptor] wired to token storage + refresh Dio.
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(
    tokenStorage: ref.read(tokenStorageProvider),
    refreshDio: ref.read(refreshDioProvider),
  );
});

// =============================================================================
// API Service (main Dio-based client)
// =============================================================================

/// The primary API client used across the app.
///
/// Wires in the [AuthInterceptor] so every request carries a valid JWT.
final apiServiceProvider = Provider<DioApiClient>((ref) {
  return DioApiClient.create(
    interceptors: [ref.read(authInterceptorProvider)],
  );
});
