import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

/// Represents a single entry from the LSRD mockup dictionary.
class MockSignEntry {
  final int id;
  final String palabra;
  final String descripcion;
  final String gesto;
  final String imagenAsset;
  final String seccion;
  final String infoAdicional;

  const MockSignEntry({
    required this.id,
    required this.palabra,
    required this.descripcion,
    required this.gesto,
    required this.imagenAsset,
    required this.seccion,
    required this.infoAdicional,
  });

  factory MockSignEntry.fromJson(Map<String, dynamic> json) {
    String imgAsset = json['imagen_asset'] as String? ?? '';
    if (imgAsset.isEmpty && json['imagePaths'] != null && (json['imagePaths'] as List).isNotEmpty) {
      imgAsset = (json['imagePaths'] as List).first.toString();
    }
    return MockSignEntry(
      id: json['id'] as int? ?? 0,
      palabra: json['palabra'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      gesto: json['gesto'] as String? ?? '',
      imagenAsset: imgAsset,
      seccion: json['seccion'] as String? ?? '',
      infoAdicional: json['info_adicional'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Loads the mockup dictionary from bundled JSON assets.
///
/// This service provides offline data for testing UI flows without requiring
/// a running backend. The data comes from the ETL-extracted LSRD dictionary.
class MockupDataService {
  List<MockSignEntry>? _cache;

  /// Loads and caches all entries from the mockup JSON.
  Future<List<MockSignEntry>> getAll() async {
    if (_cache != null) return _cache!;

    final jsonStr =
        await rootBundle.loadString('assets/mockup/mock_dictionary.json');
    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    _cache = jsonList
        .map((e) => MockSignEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return _cache!;
  }



  /// Searches entries by word (case-insensitive, partial match, ignoring accents).
  Future<List<MockSignEntry>> search(String query) async {
    final all = await getAll();
    if (query.trim().isEmpty) return all;

    final q = _normalize(query);
    return all
        .where((e) => _normalize(e.palabra).contains(q))
        .toList();
  }

  /// Returns entries by section letter.
  Future<List<MockSignEntry>> getBySection(String section) async {
    final all = await getAll();
    return all
        .where((e) => e.seccion.toUpperCase() == section.toUpperCase())
        .toList();
  }

  /// Returns greeting-related entries.
  Future<List<MockSignEntry>> getGreetings() async {
    final all = await getAll();
    const greetingWords = {
      'HOLA', 'BUENOS DÍAS', 'BUENAS TARDES', 'BUENAS NOCHES', 'ADIÓS',
      'GRACIAS', 'POR FAVOR', 'PERDÓN',
    };
    return all
        .where((e) => greetingWords.contains(e.palabra.toUpperCase()))
        .toList();
  }

  /// Returns common phrase entries.
  Future<List<MockSignEntry>> getCommonPhrases() async {
    final all = await getAll();
    const commonWords = {
      'SÍ', 'NO', 'AGUA', 'COMER', 'CASA', 'FAMILIA', 'AMIGO, AMIGA',
      'AMOR', 'ESCUELA', 'TRABAJO', 'DINERO', 'TIEMPO', 'NOMBRE',
    };
    return all
        .where((e) => commonWords.contains(e.palabra.toUpperCase()))
        .toList();
  }

  /// Returns emergency-related entries.
  Future<List<MockSignEntry>> getEmergencies() async {
    final all = await getAll();
    const emergencyWords = {
      'DOCTOR, DOCTORA', 'HOSPITAL', 'POLICÍA', 'PELIGRO', 'AYUDA',
    };
    return all
        .where((e) => emergencyWords.contains(e.palabra.toUpperCase()))
        .toList();
  }

  /// Normalizes a string by converting it to uppercase and removing diacritics.
  String _normalize(String input) {
    var text = input.trim().toUpperCase();
    text = text.replaceAll(RegExp(r'[ÁÀÄÂ]'), 'A');
    text = text.replaceAll(RegExp(r'[ÉÈËÊ]'), 'E');
    text = text.replaceAll(RegExp(r'[ÍÌÏÎ]'), 'I');
    text = text.replaceAll(RegExp(r'[ÓÒÖÔ]'), 'O');
    text = text.replaceAll(RegExp(r'[ÚÙÜÛ]'), 'U');
    return text;
  }

  /// Finds the first entry that flexibly matches the given word (ignores accents and case).
  Future<MockSignEntry?> findFlexible(String word) async {
    final all = await getAll();
    final w = _normalize(word);
    
    // Attempt normalized match
    try {
      return all.firstWhere((e) => _normalize(e.palabra) == w);
    } catch (_) {
      // Allow plural fallback e.g., if user types "adioses" but word is "adios"
      // or "amigos" but word is "amigo"
      if (w.endsWith('S') && w.length > 1) {
        final singular = w.substring(0, w.length - 1);
        try {
          return all.firstWhere((e) => _normalize(e.palabra) == singular);
        } catch (_) {}
      }
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

final mockupDataServiceProvider = Provider<MockupDataService>((ref) {
  return MockupDataService();
});

final allMockSignsProvider = FutureProvider<List<MockSignEntry>>((ref) async {
  return ref.read(mockupDataServiceProvider).getAll();
});

final mockGreetingsProvider = FutureProvider<List<MockSignEntry>>((ref) async {
  return ref.read(mockupDataServiceProvider).getGreetings();
});

final mockCommonPhrasesProvider =
    FutureProvider<List<MockSignEntry>>((ref) async {
  return ref.read(mockupDataServiceProvider).getCommonPhrases();
});

final mockEmergenciesProvider =
    FutureProvider<List<MockSignEntry>>((ref) async {
  return ref.read(mockupDataServiceProvider).getEmergencies();
});
