import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

/// Representa una entrada del diccionario de Lengua de Señas Dominicana (LSRD).
///
/// Soporta tanto el formato moderno de Sprite Sheets (matrices WebP) generado
/// por el pipeline ETL como las imágenes individuales heredadas.
class MockSignEntry {
  final int id;
  final String palabra;
  final String descripcion;
  final String gesto;
  final String imagenAsset;
  final String seccion;
  final String infoAdicional;

  // Campos de Matriz WebP (Sprite Sheet)
  final String? archivoMatriz;
  final Rect? coordenadas;
  final String? gestoFacial;
  final String? categoria;

  /// Indica si la seña utiliza renderizado recortado de matriz WebP.
  bool get isMatrixSign => archivoMatriz != null && coordenadas != null;

  const MockSignEntry({
    required this.id,
    required this.palabra,
    required this.descripcion,
    required this.gesto,
    required this.imagenAsset,
    required this.seccion,
    required this.infoAdicional,
    this.archivoMatriz,
    this.coordenadas,
    this.gestoFacial,
    this.categoria,
  });

  factory MockSignEntry.fromJson(Map<String, dynamic> json, [int defaultId = 0]) {
    // 1. Extraer identificadores y palabras
    final id = json['id'] as int? ?? defaultId;
    final palabra = (json['palabra_clave'] ?? json['palabra'] ?? '').toString().trim();

    // 2. Extraer textos descriptivos
    final definicion = (json['definicion'] ?? json['descripcion'] ?? '').toString().trim();
    final descripcionMov = (json['descripcion_movimiento'] ?? json['gesto'] ?? json['descripcion'] ?? '').toString().trim();

    // 3. Extraer imagen individual (legacy)
    String imgAsset = json['imagen_asset'] as String? ?? '';
    if (imgAsset.isEmpty && json['imagePaths'] != null && (json['imagePaths'] as List).isNotEmpty) {
      imgAsset = (json['imagePaths'] as List).first.toString();
    }

    // 4. Extraer datos de la matriz WebP
    final archivoMatriz = json['archivo_matriz'] as String?;
    Rect? coordenadas;
    final coordsJson = json['coordenadas'] as Map<String, dynamic>?;
    if (coordsJson != null) {
      coordenadas = Rect.fromLTWH(
        (coordsJson['x'] as num).toDouble(),
        (coordsJson['y'] as num).toDouble(),
        (coordsJson['width'] as num).toDouble(),
        (coordsJson['height'] as num).toDouble(),
      );
    }

    // 5. Metadatos adicionales
    final gestoFacial = json['gesto_facial'] as String?;
    final categoria = json['categoria'] as String?;
    String seccion = json['seccion'] as String? ?? '';
    if (seccion.isEmpty && archivoMatriz != null) {
      seccion = _deducirSeccionDesdeMatriz(archivoMatriz);
    } else if (seccion.isEmpty && palabra.isNotEmpty) {
      seccion = palabra[0].toUpperCase();
    }

    final infoAdicional = json['info_adicional'] as String? ??
        json['categoria_gramatical'] as String? ??
        categoria ??
        '';

    return MockSignEntry(
      id: id,
      palabra: palabra,
      descripcion: definicion.isNotEmpty ? definicion : descripcionMov,
      gesto: descripcionMov,
      imagenAsset: imgAsset,
      seccion: seccion,
      infoAdicional: infoAdicional,
      archivoMatriz: archivoMatriz,
      coordenadas: coordenadas,
      gestoFacial: gestoFacial,
      categoria: categoria,
    );
  }

  static String _deducirSeccionDesdeMatriz(String filename) {
    // Ejemplos: matriz_a_01.webp -> A, matriz_locuciones_01.webp -> LOCUCIONES
    final clean = filename.replaceAll('matriz_', '').replaceAll('.webp', '');
    final parts = clean.split('_');
    if (parts.isNotEmpty) {
      return parts.first.toUpperCase();
    }
    return '';
  }
}

// ---------------------------------------------------------------------------
// Translation Result Helper
// ---------------------------------------------------------------------------

class TranslationResult {
  final List<MockSignEntry> matchedSigns;
  final List<String> notFoundWords;
  final List<String> spelledWords;

  const TranslationResult({
    required this.matchedSigns,
    required this.notFoundWords,
    this.spelledWords = const [],
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Servicio para la carga y consulta del Diccionario Oficial LSRD.
///
/// Carga las 2,427 señas del JSON de matrices con Sprite Sheets WebP ultraligeras,
/// ofreciendo búsqueda flexible por n-gramas, plurales, variantes de género y tildes.
class MockupDataService {
  List<MockSignEntry>? _cache;
  Map<String, MockSignEntry>? _normalizedIndex;
  Map<String, MockSignEntry>? _alphabetIndex;

  /// Carga y cachea todas las entradas del diccionario.
  Future<List<MockSignEntry>> getAll() async {
    if (_cache != null) return _cache!;

    String jsonStr;
    try {
      // Intentar cargar el diccionario maestro completo de matrices (2,427 señas)
      jsonStr = await rootBundle.loadString('assets/matrices/diccionario_matrices.json');
    } catch (_) {
      // Fallback al mockup básico si las matrices no estuvieran presentes
      jsonStr = await rootBundle.loadString('assets/mockup/mock_dictionary.json');
    }

    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    int index = 1;
    _cache = jsonList
        .map((e) => MockSignEntry.fromJson(e as Map<String, dynamic>, index++))
        .toList();

    _buildNormalizedIndex(_cache!);

    return _cache!;
  }

  void _buildNormalizedIndex(List<MockSignEntry> list) {
    final map = <String, MockSignEntry>{};
    final alphabet = <String, MockSignEntry>{};

    for (final entry in list) {
      final norm = _normalize(entry.palabra);
      map.putIfAbsent(norm, () => entry);

      // Si es una letra individual del abecedario (A-Z, Ñ), indexarla para dactilología
      final trimmed = entry.palabra.trim().toUpperCase();
      if (trimmed.length == 1 && RegExp(r'^[A-ZÑ]$').hasMatch(trimmed)) {
        alphabet.putIfAbsent(trimmed, () => entry);
      }

      // Si tiene variantes como "AMIGO, GA" o "ABUELO, LA" indexar también la forma base
      if (norm.contains(',')) {
        final base = norm.split(',').first.trim();
        map.putIfAbsent(base, () => entry);
      }
      if (norm.contains('/')) {
        final base = norm.split('/').first.trim();
        map.putIfAbsent(base, () => entry);
      }
    }
    _normalizedIndex = map;
    _alphabetIndex = alphabet;
  }

  /// Busca entradas por palabra (insensible a mayúsculas, tildes y búsqueda parcial).
  Future<List<MockSignEntry>> search(String query) async {
    final all = await getAll();
    if (query.trim().isEmpty) return all;

    final q = _normalize(query);
    return all.where((e) => _normalize(e.palabra).contains(q)).toList();
  }

  /// Retorna entradas pertenecientes a una sección (ej. 'A', 'B', 'LOCUCIONES').
  Future<List<MockSignEntry>> getBySection(String section) async {
    final all = await getAll();
    final s = section.toUpperCase().trim();
    return all.where((e) => e.seccion.toUpperCase() == s).toList();
  }

  /// Retorna señas de saludos y cortesía.
  Future<List<MockSignEntry>> getGreetings() async {
    final all = await getAll();
    const greetingWords = {
      'HOLA', 'BUENOS DÍAS', 'BUENAS TARDES', 'BUENAS NOCHES', 'ADIÓS',
      'GRACIAS', 'POR FAVOR', 'PERDÓN', 'DISCULPE', 'DE NADA',
      '¿CÓMO ESTÁS?', 'CÓMO ESTÁS', 'MUCHO GUSTO'
    };
    final normSet = greetingWords.map(_normalize).toSet();
    return all.where((e) => normSet.contains(_normalize(e.palabra))).toList();
  }

  /// Retorna frases comunes de uso cotidiano.
  Future<List<MockSignEntry>> getCommonPhrases() async {
    final all = await getAll();
    const commonWords = {
      'SÍ', 'NO', 'AGUA', 'COMER', 'CASA', 'FAMILIA', 'AMIGO, GA', 'AMIGO, AMIGA',
      'AMOR', 'ESCUELA', 'TRABAJO', 'DINERO', 'TIEMPO', 'NOMBRE', 'BIEN', 'MAL',
      'POR FAVOR', 'GRACIAS', 'AYUDA'
    };
    final normSet = commonWords.map(_normalize).toSet();
    return all.where((e) {
      final norm = _normalize(e.palabra);
      return normSet.contains(norm) || normSet.contains(norm.split(',').first.trim());
    }).toList();
  }

  /// Retorna señas relacionadas con emergencias y auxilio.
  Future<List<MockSignEntry>> getEmergencies() async {
    final all = await getAll();
    const emergencyWords = {
      'DOCTOR, RA', 'DOCTOR, DOCTORA', 'HOSPITAL', 'POLICÍA', 'PELIGRO',
      'AYUDA', 'AYUDAR', 'ENFERMO, MA', 'DOLOR', 'EMERGENCIA', 'MEDICINA',
      'ACCIDENTE', 'AMBULANCIA', 'FUEGO', 'CALMA'
    };
    final normSet = emergencyWords.map(_normalize).toSet();
    return all.where((e) {
      final norm = _normalize(e.palabra);
      return normSet.contains(norm) || normSet.contains(norm.split(',').first.trim());
    }).toList();
  }

  /// Normaliza una cadena eliminando signos de puntuación, tildes y diacríticos.
  String _normalize(String input) {
    var text = input.trim().toUpperCase();
    // Eliminar signos de interrogación y puntuación
    text = text.replaceAll(RegExp(r'[¿?¡!.,;:"()\-_\/\\]'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Reemplazar vocales con acento
    text = text.replaceAll(RegExp(r'[ÁÀÄÂ]'), 'A');
    text = text.replaceAll(RegExp(r'[ÉÈËÊ]'), 'E');
    text = text.replaceAll(RegExp(r'[ÍÌÏÎ]'), 'I');
    text = text.replaceAll(RegExp(r'[ÓÒÖÔ]'), 'O');
    text = text.replaceAll(RegExp(r'[ÚÙÜÛ]'), 'U');
    return text;
  }

  /// Búsqueda flexible de una sola palabra o término.
  Future<MockSignEntry?> findFlexible(String word) async {
    final all = await getAll();
    final w = _normalize(word);
    if (w.isEmpty) return null;

    // 1. Coincidencia exacta desde índice rápido
    if (_normalizedIndex != null && _normalizedIndex!.containsKey(w)) {
      return _normalizedIndex![w];
    }

    // 2. Coincidencia por inicio de palabra con coma (ej. "AMIGO" -> "AMIGO, GA")
    for (final entry in all) {
      final norm = _normalize(entry.palabra);
      if (norm == w) return entry;
      if (norm.startsWith('$w ') || norm.startsWith('$w,') || norm.startsWith('$w/')) {
        return entry;
      }
    }

    // 3. Fallback para plurales en español (ej. "AMIGOS" -> "AMIGO", "CASAS" -> "CASA")
    if (w.endsWith('ES') && w.length > 3) {
      final singular = w.substring(0, w.length - 2);
      final found = await findFlexible(singular);
      if (found != null) return found;
    }
    if (w.endsWith('S') && w.length > 2) {
      final singular = w.substring(0, w.length - 1);
      final found = await findFlexible(singular);
      if (found != null) return found;
    }

    return null;
  }

  /// Obtiene la seña de una letra específica del alfabeto dactilológico.
  MockSignEntry? getLetterSign(String char) {
    if (_alphabetIndex == null || char.isEmpty) return null;
    final normalizedChar = _normalize(char);
    if (normalizedChar.isEmpty) return null;
    return _alphabetIndex![normalizedChar] ?? _alphabetIndex![normalizedChar[0]];
  }

  /// Traduce una frase completa agrupando palabras compuestas (n-gramas de 3, 2 y 1 palabra).
  ///
  /// Si una palabra no existe en el diccionario, se convierte automáticamente en una
  /// sucesión de letras (deletreo dactilológico) utilizando el alfabeto oficial de señas.
  Future<TranslationResult> translatePhrase(String phrase) async {
    await getAll();
    final normalized = _normalize(phrase);
    if (normalized.isEmpty) {
      return const TranslationResult(matchedSigns: [], notFoundWords: []);
    }

    final tokens = normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final List<MockSignEntry> matched = [];
    final List<String> notFound = [];
    final List<String> spelled = [];

    int i = 0;
    while (i < tokens.length) {
      // 1. Probar trigrama (ej. "MUCHAS GRACIAS AMIGO" o "ZONA FRANCA SUR")
      if (i + 2 < tokens.length) {
        final triGram = '${tokens[i]} ${tokens[i + 1]} ${tokens[i + 2]}';
        final sign = await findFlexible(triGram);
        if (sign != null) {
          matched.add(sign);
          i += 3;
          continue;
        }
      }

      // 2. Probar bigrama (ej. "BUENOS DIAS", "COMO ESTAS", "POR FAVOR", "A TRAVES")
      if (i + 1 < tokens.length) {
        final biGram = '${tokens[i]} ${tokens[i + 1]}';
        final sign = await findFlexible(biGram);
        if (sign != null) {
          matched.add(sign);
          i += 2;
          continue;
        }
      }

      // 3. Probar palabra individual (unigrama)
      final singleWord = tokens[i];
      final sign = await findFlexible(singleWord);
      if (sign != null) {
        matched.add(sign);
      } else {
        // Fallback: Sucesión de letras (deletreo dactilológico de la palabra)
        final letterSigns = <MockSignEntry>[];
        bool allLettersFound = true;

        for (int charIdx = 0; charIdx < singleWord.length; charIdx++) {
          final ch = singleWord[charIdx];
          final letterSign = getLetterSign(ch);
          if (letterSign != null) {
            letterSigns.add(
              MockSignEntry(
                id: letterSign.id,
                palabra: '$ch ($singleWord)',
                descripcion: 'Deletreo de "$singleWord": Letra $ch',
                gesto: letterSign.gesto.isNotEmpty
                    ? letterSign.gesto
                    : 'Configuración manual de la letra $ch',
                imagenAsset: letterSign.imagenAsset,
                seccion: letterSign.seccion,
                infoAdicional: 'Deletreo',
                archivoMatriz: letterSign.archivoMatriz,
                coordenadas: letterSign.coordenadas,
                gestoFacial: letterSign.gestoFacial,
                categoria: 'Deletreo',
              ),
            );
          } else {
            allLettersFound = false;
          }
        }

        if (letterSigns.isNotEmpty) {
          matched.addAll(letterSigns);
          spelled.add(singleWord);
          if (!allLettersFound) {
            notFound.add(singleWord);
          }
        } else {
          notFound.add(singleWord);
        }
      }
      i++;
    }

    return TranslationResult(
      matchedSigns: matched,
      notFoundWords: notFound,
      spelledWords: spelled,
    );
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
