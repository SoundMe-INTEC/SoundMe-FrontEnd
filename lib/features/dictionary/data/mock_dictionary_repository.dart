import 'dart:convert';
import 'package:flutter/services.dart';

class MockDictionaryWord {
  final int id;
  final String palabra;
  final String descripcion;
  final String gesto;
  final List<String> imagePaths;

  MockDictionaryWord({
    required this.id,
    required this.palabra,
    required this.descripcion,
    required this.gesto,
    required this.imagePaths,
  });

  factory MockDictionaryWord.fromJson(Map<String, dynamic> json) {
    return MockDictionaryWord(
      id: json['id'] ?? 0,
      palabra: json['palabra'] ?? '',
      descripcion: json['descripcion'] ?? '',
      gesto: json['gesto'] ?? '',
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
    );
  }
}

class MockDictionaryRepository {
  static List<MockDictionaryWord> mockWords = [];

  static Future<void> loadData() async {
    if (mockWords.isNotEmpty) return;

    try {
      final String response = await rootBundle.loadString('assets/mockup/mock_dictionary.json');
      final List<dynamic> data = json.decode(response);
      
      mockWords = data.map((item) => MockDictionaryWord.fromJson(item)).toList();
    } catch (e) {
      print('Error cargando el diccionario mockeado: $e');
    }
  }
}
