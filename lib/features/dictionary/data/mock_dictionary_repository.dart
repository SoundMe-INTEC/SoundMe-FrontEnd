import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';

class MockDictionaryWord {
  final int id;
  final String palabra;
  final String descripcion;
  final String gesto;
  final List<String> imagePaths;
  final List<String> sinonimos;
  final MockSignEntry? signEntry;

  MockDictionaryWord({
    required this.id,
    required this.palabra,
    required this.descripcion,
    required this.gesto,
    required this.imagePaths,
    this.sinonimos = const [],
    this.signEntry,
  });

  /// Retorna el homónimo contextual asociado si esta palabra tiene múltiples acepciones.
  ContextualHomonym? get contextualHomonym {
    final norm = palabra.trim().toUpperCase();
    return MockDictionaryRepository.findHomonymForWord(norm);
  }

  /// Retorna las acepciones o sentidos si esta palabra forma parte de un homónimo.
  List<ContextualSense> get contextualSenses {
    final h = contextualHomonym;
    if (h == null) return const [];
    return h.acepciones;
  }

  /// Retorna la acepción específica a la que corresponde esta seña.
  ContextualSense? get matchedSense {
    final norm = palabra.trim().toUpperCase();
    final h = contextualHomonym;
    if (h == null) return null;
    for (final a in h.acepciones) {
      if (a.sign.toUpperCase() == norm) return a;
    }
    return null;
  }

  factory MockDictionaryWord.fromSignEntry(MockSignEntry entry) {
    return MockDictionaryWord(
      id: entry.id,
      palabra: entry.palabra,
      descripcion: entry.descripcion,
      gesto: entry.gesto,
      imagePaths: entry.imagenAsset.isEmpty ? const [] : [entry.imagenAsset],
      signEntry: entry,
    );
  }

  factory MockDictionaryWord.fromJson(Map<String, dynamic> json) {
    return MockDictionaryWord(
      id: json['id'] ?? 0,
      palabra: json['palabra'] ?? '',
      descripcion: json['descripcion'] ?? '',
      gesto: json['gesto'] ?? '',
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
      sinonimos: List<String>.from(json['sinonimos'] ?? []),
    );
  }
}

class MockDictionaryRepository {
  static List<MockDictionaryWord> mockWords = [];
  static List<ContextualHomonym> contextualHomonyms = [];

  /// Busca si una palabra o seña pertenece a un catálogo de homónimos.
  static ContextualHomonym? findHomonymForWord(String word) {
    final clean = word.trim().toUpperCase();
    for (final h in contextualHomonyms) {
      if (h.palabra.toUpperCase() == clean) return h;
      for (final a in h.acepciones) {
        if (a.sign.toUpperCase() == clean) return h;
      }
    }
    return null;
  }

  static Future<void> loadData() async {
    if (mockWords.isNotEmpty && contextualHomonyms.isNotEmpty) return;

    try {
      final service = MockupDataService();
      final signs = await service.getAll();
      mockWords = signs.map(MockDictionaryWord.fromSignEntry).toList();
      contextualHomonyms = await service.getHomonyms();
    } catch (e) {
      debugPrint('Error cargando el diccionario mockeado: $e');
      try {
        final response = await rootBundle.loadString(
          'assets/mockup/mock_dictionary.json',
        );
        final List<dynamic> data = json.decode(response);
        mockWords = data
            .map((item) => MockDictionaryWord.fromJson(item))
            .toList();
        contextualHomonyms = await MockupDataService().getHomonyms();
      } catch (fallbackError) {
        debugPrint('Error cargando el diccionario de respaldo: $fallbackError');
      }
    }
  }
}

