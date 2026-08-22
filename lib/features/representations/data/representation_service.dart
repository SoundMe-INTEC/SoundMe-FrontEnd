import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/core/network/api_endpoints.dart';
import 'package:soundme_frontend/core/providers/app_providers.dart';
import 'package:soundme_frontend/integration/network/api_client.dart';

final representationServiceProvider = Provider<RepresentationService>((ref) {
  return RepresentationService(
    apiClient: ref.read(apiServiceProvider),
  );
});

class RepresentationService {
  final DioApiClient _apiClient;

  RepresentationService({
    required DioApiClient apiClient,
  }) : _apiClient = apiClient;
  // ignore_for_file: prefer_initializing_formals

  /// Obtiene todas las representaciones multimedia disponibles
  Future<List<dynamic>> getAllRepresentations() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getAllRepresentations);
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Error al obtener las representaciones.');
    }
  }

  /// Obtiene los detalles multimedia de una representación por ID de seña
  Future<Map<String, dynamic>> getRepresentation(String signId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.getRepresentation,
        queryParameters: {'sign_id': signId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Representación no encontrada.');
      }
      throw Exception('Error al buscar la representación.');
    }
  }

  /// Asocia un asset multimedia a una seña existente
  Future<bool> createRepresentation({
    required int signId,
    required String type,
    required String url,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.createRepresentation,
        data: {
          'sign_id': signId,
          'type': type,
          'url': url,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Datos inválidos al crear representación.');
      }
      throw Exception('Error al crear representación.');
    }
  }
}
