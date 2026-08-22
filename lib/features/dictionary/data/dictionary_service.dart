import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/core/network/api_endpoints.dart';
import 'package:soundme_frontend/core/providers/app_providers.dart';
import 'package:soundme_frontend/integration/network/api_client.dart';

final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  return DictionaryService(
    apiClient: ref.read(apiServiceProvider),
  );
});

final allSignsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.read(dictionaryServiceProvider);
  return await service.getAllSigns();
});

class DictionaryService {
  final DioApiClient _apiClient;

  DictionaryService({
    required DioApiClient apiClient,
  }) : _apiClient = apiClient;
  // ignore_for_file: prefer_initializing_formals

  /// Obtiene el listado de todas las palabras activas
  Future<List<dynamic>> getAllWords() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getAllWords);
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Error al obtener todas las palabras.');
    }
  }

  /// Busca una palabra específica por su nombre
  Future<Map<String, dynamic>> getWord(String wordName) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.getWord,
        queryParameters: {'word_name': wordName},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Palabra no encontrada.');
      }
      throw Exception('Error al buscar la palabra.');
    }
  }

  /// Obtiene el catálogo de señas activas
  Future<List<dynamic>> getAllSigns() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getAllSigns);
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Error al obtener el catálogo de señas.');
    }
  }

  /// Busca una seña específica por su nombre
  Future<Map<String, dynamic>> getSign(String signName) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.getSign,
        queryParameters: {'sign_name': signName},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Seña no encontrada.');
      }
      throw Exception('Error al buscar la seña.');
    }
  }

  /// Crea una nueva seña en el diccionario
  Future<bool> createSign({
    required String signName,
    required String description,
    required String difficultyLevel,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.createSign,
        data: {
          'sign_name': signName,
          'description': description,
          'difficulty_level': difficultyLevel,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Datos inválidos al crear la seña.');
      }
      throw Exception('Error al crear seña.');
    }
  }
}
