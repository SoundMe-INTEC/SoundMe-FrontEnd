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

class AccountNotVerifiedException implements Exception {
  const AccountNotVerifiedException();
}

class AuthService {
  final DioApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService({
    required DioApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;
  // ignore_for_file: prefer_initializing_formals

  String _extractErrorMessage(DioException e, String defaultMessage) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['message'] != null) {
        final msg = data['message'].toString();
        if (msg.contains('Invalid credentials')) {
          return 'Credenciales inválidas. Verifica tu identificación y contraseña.';
        }
        if (msg.contains('Invalid or expired OTP')) {
          return 'El código OTP es inválido o ha expirado. Por favor solicita uno nuevo.';
        }
        if (msg.contains('OTP verification required')) {
          return 'Se requiere verificación por código OTP.';
        }
        if (msg.contains('User is already verified')) {
          return 'El usuario ya ha sido verificado.';
        }
        return msg;
      }
      if (data['detail'] != null) {
        return data['detail'].toString();
      }
      for (final val in data.values) {
        if (val is List && val.isNotEmpty) {
          return val.first.toString();
        } else if (val is String) {
          return val;
        }
      }
    }
    if (e.response?.statusCode == 503) {
      return 'No se pudo enviar el código al correo. Intenta de nuevo más tarde.';
    }
    return defaultMessage;
  }

  /// Valida credenciales y solicita un OTP si la cuenta aún no está verificada.
  Future<bool> checkCredentials(String identification, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.check,
        data: {'identification': identification, 'password': password},
      );
      return response.data['requires_otp'] == true;
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e,
          'Credenciales inválidas. Verifica tu identificación y contraseña.',
        ),
      );
    }
  }

  /// Inicia sesión con el backend y guarda los tokens JWT localmente
  Future<bool> login(
    String identification,
    String password, {
    String? otp,
  }) async {
    try {
      final requestData = {
        'identification': identification,
        'password': password,
      };
      if (otp != null) requestData['otp'] = otp;
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: requestData,
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
      throw Exception(
        _extractErrorMessage(
          e,
          otp != null
              ? 'El código OTP es inválido o ha expirado.'
              : 'Credenciales inválidas. Verifica tu identificación y contraseña.',
        ),
      );
    }
  }

  /// Valida un código OTP de forma independiente (sin iniciar sesión)
  Future<bool> verifyOtp(String identification, String otp) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        data: {'identification': identification, 'otp': otp},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Error al verificar el código OTP.'),
      );
    }
  }

  /// Restablece la contraseña del usuario actual
  Future<bool> resetPassword(String identification, String newPassword) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.resetPassword,
        data: {'identification': identification, 'new_password': newPassword},
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
