import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/core/network/api_endpoints.dart';
import 'package:soundme_frontend/core/providers/app_providers.dart';
import 'package:soundme_frontend/integration/network/api_client.dart';
import 'package:soundme_frontend/integration/network/token_storage.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    apiClient: ref.read(apiServiceProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

class AuthService {
  final DioApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService({
    required DioApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;
        // ignore_for_file: prefer_initializing_formals

  /// Inicia sesión con el backend y guarda los tokens JWT localmente
  Future<bool> login(String identification, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'identification': identification,
          'password': password,
        },
      );

      final data = response.data;
      if (data != null && data['access'] != null && data['refresh'] != null) {
        await _tokenStorage.saveTokens(
          accessToken: data['access'],
          refreshToken: data['refresh'],
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        throw Exception('Credenciales inválidas. Verifica tu identificación y contraseña.');
      }
      throw Exception('Ocurrió un error inesperado al iniciar sesión.');
    }
  }

  /// Verifica el código OTP en el backend
  Future<bool> verifyOtp(String identification, String otp) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        data: {
          'identification': identification,
          'otp': otp,
        },
      );
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Código OTP inválido.');
      }
      throw Exception('Ocurrió un error al verificar el OTP.');
    }
  }

  /// Crea una nueva cuenta de usuario
  Future<bool> signup({
    required String identification,
    required String identificationType,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.signup,
        data: {
          'identification': identification,
          'identification_type': identificationType,
          'email': email,
          'password': password,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Datos inválidos o el usuario ya existe.');
      }
      throw Exception('Error al registrar usuario.');
    }
  }

  /// Restablece la contraseña del usuario actual
  Future<bool> resetPassword(String identification, String newPassword) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.resetPassword,
        data: {
          'identification': identification,
          'new_password': newPassword,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Datos inválidos para resetear contraseña.');
      }
      throw Exception('Error al restablecer contraseña.');
    }
  }

  /// Obtiene la información del perfil del usuario logueado
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.profile);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al obtener perfil.');
    }
  }

  /// Lista todos los usuarios activos
  Future<List<dynamic>> searchUsers() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.searchUsers);
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Error al listar usuarios.');
    }
  }

  /// Realiza el cierre de sesión borrando los tokens locales
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }
}
