// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Dio [Interceptor] that handles JWT authentication automatically.
///
/// **Request phase** – attaches `Authorization: Bearer <access>` to every
/// outgoing request (unless the request already carries its own header).
///
/// **Error phase** – on a 401 response:
///   1. Blocks all concurrent in-flight requests behind a [Completer].
///   2. Attempts a token refresh via `POST /token/refresh` using a *separate*
///      [Dio] instance (to avoid interceptor recursion).
///   3. On success, retries the original request with the new token.
///   4. On failure, clears stored tokens and propagates the error.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshDio,
    this.refreshPath = '/token/refresh',
  })  : _tokenStorage = tokenStorage,
        _refreshDio = refreshDio;

  final TokenStorage _tokenStorage;

  /// A *plain* [Dio] instance (no interceptors) used exclusively for the
  /// refresh call so we don't trigger this interceptor recursively.
  final Dio _refreshDio;

  /// The API path used to refresh the JWT.
  final String refreshPath;

  // ---------------------------------------------------------------------------
  // Concurrency guard — prevents thundering-herd token refreshes.
  // ---------------------------------------------------------------------------
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  // ---------------------------------------------------------------------------
  // onRequest — inject Bearer token
  // ---------------------------------------------------------------------------
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip if the caller already set an Authorization header.
    if (options.headers.containsKey('Authorization')) {
      return handler.next(options);
    }

    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ---------------------------------------------------------------------------
  // onError — handle 401 with queue-blocking refresh
  // ---------------------------------------------------------------------------
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only intercept 401 Unauthorized.
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final options = err.requestOptions;

    // If another call is already refreshing, wait for it.
    if (_isRefreshing) {
      final newToken = await _refreshCompleter?.future;
      if (newToken != null) {
        return handler.resolve(await _retry(options, newToken));
      }
      return handler.next(err);
    }

    // We are the first 401 — perform the refresh.
    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final newToken = await _performRefresh();

      _refreshCompleter!.complete(newToken);

      if (newToken != null) {
        return handler.resolve(await _retry(options, newToken));
      }

      // Refresh failed — clear tokens, propagate error.
      await _tokenStorage.clearTokens();
      handler.next(err);
    } catch (_) {
      _refreshCompleter!.complete(null);
      await _tokenStorage.clearTokens();
      handler.next(err);
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Calls the refresh endpoint and persists the new tokens.
  /// Returns the new access token, or `null` on failure.
  Future<String?> _performRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;

    final response = await _refreshDio.post<Map<String, dynamic>>(
      refreshPath,
      data: {'refresh': refreshToken},
    );

    final data = response.data;
    if (response.statusCode == 200 && data != null && data['access'] != null) {
      final newAccess = data['access'] as String;
      final newRefresh = (data['refresh'] as String?) ?? refreshToken;
      await _tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return newAccess;
    }
    return null;
  }

  /// Retries the original request with a fresh access token.
  Future<Response<dynamic>> _retry(RequestOptions options, String token) {
    options.headers['Authorization'] = 'Bearer $token';
    return _refreshDio.fetch(options);
  }
}
