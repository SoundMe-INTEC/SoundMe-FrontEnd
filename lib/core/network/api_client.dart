import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_endpoints.dart';

class ApiClient {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Constantes de almacenamiento
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _storage.read(key: _accessTokenKey);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Método genérico para peticiones GET
  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);

    final response = await _client.get(url, headers: headers);
    return _handleResponse(response, () => get(endpoint, requiresAuth: requiresAuth));
  }

  /// Método genérico para peticiones POST
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final headers = await _getHeaders(requiresAuth: requiresAuth);

    final response = await _client.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, () => post(endpoint, body: body, requiresAuth: requiresAuth));
  }

  /// Maneja las respuestas HTTP e intercepta los errores de autenticación (401)
  Future<dynamic> _handleResponse(http.Response response, Future<dynamic> Function() retryRequest) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Token expirado, intentar refrescar
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Reintentar la petición original si se pudo refrescar
        return await retryRequest();
      } else {
        throw Exception('No autorizado. Por favor inicie sesión nuevamente.');
      }
    } else {
      // Manejar otros errores
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Error desconocido del servidor');
      } catch (e) {
        throw Exception('Error en el servidor: ${response.statusCode}');
      }
    }
  }

  /// Intenta refrescar el token de acceso usando el token de refresco
  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;

    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.tokenRefresh}');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: _accessTokenKey, value: data['access']);
        // El backend SimpleJWT puede estar configurado para rotar también el refresh token
        if (data.containsKey('refresh')) {
           await _storage.write(key: _refreshTokenKey, value: data['refresh']);
        }
        return true;
      }
      // Si falla el refresco (ej: expiró el token de refresco) borramos los tokens locales
      await logout();
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Guarda los tokens después de un login exitoso
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Borra los tokens locales (Logout)
  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
