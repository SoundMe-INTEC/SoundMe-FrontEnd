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

  // Campo Vectorial Nativo SVG
  final String? svgAsset;

  /// Indica si la seña cuenta con archivo vectorial SVG nativo.
  bool get isSvg => svgAsset != null && svgAsset!.isNotEmpty;

  /// Indica si la seña cuenta con coordenadas de matriz.
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
    this.svgAsset,
  });

  factory MockSignEntry.fromJson(Map<String, dynamic> json, [int defaultId = 0]) {
    // 1. Extraer identificadores y palabras
    final id = json['id'] as int? ?? defaultId;
    final palabra = (json['palabra_clave'] ?? json['palabra'] ?? '').toString().trim();

    // 2. Extraer textos descriptivos
    final definicion = (json['definicion'] ?? json['descripcion'] ?? '').toString().trim();
    final descripcionMov = (json['descripcion_movimiento'] ?? json['gesto'] ?? json['descripcion'] ?? '').toString().trim();

    // 3. Extraer imagen individual (legacy o fallback)
    String imgAsset = json['imagen_asset'] as String? ?? '';
    if (imgAsset.isEmpty && json['imagePaths'] != null && (json['imagePaths'] as List).isNotEmpty) {
      imgAsset = (json['imagePaths'] as List).first.toString();
    }

    // 4. Extraer vector SVG de alta calidad
    String? svgAsset = json['svg_asset'] as String?;
    if (svgAsset == null || svgAsset.isEmpty) {
      final svgIndividual = json['svg_individual'] as String?;
      if (svgIndividual != null && svgIndividual.isNotEmpty) {
        final fname = svgIndividual.split('/').last;
        svgAsset = 'assets/senias_svg/$fname';
      }
    }

    // 5. Extraer datos de la matriz WebP
    final archivoMatriz = json['archivo_matriz'] as String?;
    Rect? coordenadas;
    final coordsJson = json['coordenadas'] as Map<String, dynamic>?;
    if (coordsJson != null && coordsJson.isNotEmpty && coordsJson['width'] != null) {
      coordenadas = Rect.fromLTWH(
        (coordsJson['x'] as num).toDouble(),
        (coordsJson['y'] as num).toDouble(),
        (coordsJson['width'] as num).toDouble(),
        (coordsJson['height'] as num).toDouble(),
      );
    }

    // 6. Metadatos adicionales
    final gestoFacial = json['gesto_facial'] as String?;
    final categoria = json['categoria'] as String?;
    String seccion = json['seccion'] as String? ?? '';
    if (seccion.isEmpty && archivoMatriz != null && archivoMatriz.isNotEmpty) {
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
      svgAsset: svgAsset,
    );
  }

  static String _deducirSeccionDesdeMatriz(String filename) {
    // Ejemplos: matriz_a_01.webp -> A, matriz_locuciones_01.webp -> LOCUCIONES, matriz_nombres_historicos.webp -> NOMBRES_HISTORICOS
    final clean = filename.replaceAll('matriz_', '').replaceAll('.webp', '').replaceAll('.svg', '');
    final withoutDigits = clean.replaceAll(RegExp(r'_\d+$'), '');
    return withoutDigits.toUpperCase();
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
  final String? defaultDictionaryPath;
  List<MockSignEntry>? _cache;
  Map<String, MockSignEntry>? _normalizedIndex;
  Map<String, MockSignEntry>? _phoneticIndex;
  Map<String, MockSignEntry>? _alphabetIndex;

  MockupDataService({this.defaultDictionaryPath});

  /// Diccionario de sinónimos comunes del español mapeados a señas canónicas del diccionario LSRD.
  static const Map<String, String> _commonSynonyms = {
    'HALLAR': 'ENCONTRAR',
    'HAYAR': 'ENCONTRAR',
    'AUTO': 'CARRO',
    'AUTOMOVIL': 'CARRO',
    'VEHICULO': 'CARRO',
    'CAN': 'PERRO',
    'DOCENTE': 'MAESTRO',
    'PROFESOR': 'MAESTRO',
    'PROFESORA': 'MAESTRO',
    'CHICO': 'NIÑO',
    'CHICA': 'NIÑA',
    'NENE': 'NIÑO',
    'NENA': 'NIÑA',
    'PADRE': 'PAPÁ',
    'MADRE': 'MAMÁ',
    'BEBIDA': 'AGUA',
    'CHARLAR': 'HABLAR',
    'PLATICAR': 'HABLAR',
    'OBSEQUIO': 'REGALO',
    'REGALAR': 'REGALO',
    'EMPLEO': 'TRABAJO',
    'LABOR': 'TRABAJO',
    'MEDICO': 'DOCTOR',
    'MEDICA': 'DOCTORA',
    'VELOZ': 'RÁPIDO',
    'PRONTO': 'RÁPIDO',
    'FINALIZAR': 'TERMINAR',
    'CONCLUIR': 'TERMINAR',
    'INICIAR': 'EMPEZAR',
    'COMENZAR': 'EMPEZAR',
    'RETORNAR': 'REGRESAR',
    'VOLVER': 'REGRESAR',
  };

  /// Normaliza variaciones ortográficas y homófonas comunes en español (B/V, LL/Y, C/S/Z, H).
  static String _spanishPhonetic(String text) {
    var s = text.toUpperCase();
    // Eliminar H muda
    s = s.replaceAll('H', '');
    // B y V son homófonas en español
    s = s.replaceAll('V', 'B');
    // Yeísmo: LL e Y
    s = s.replaceAll('LL', 'Y');
    // Seseo: Z, CE, CI y S
    s = s.replaceAll('Z', 'S');
    s = s.replaceAll('CE', 'SE').replaceAll('CI', 'SI');
    // J y GE/GI
    s = s.replaceAll('GE', 'JE').replaceAll('GI', 'JI');
    // QU, K y C dura
    s = s.replaceAll('QU', 'K').replaceAll('C', 'K');
    return s;
  }

  /// Calcula la distancia de edición Levenshtein entre dos cadenas.
  static int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  /// Carga y cachea todas las entradas del diccionario.
  Future<List<MockSignEntry>> getAll() async {
    if (_cache != null) return _cache!;

    String jsonStr;
    if (defaultDictionaryPath != null) {
      jsonStr = await rootBundle.loadString(defaultDictionaryPath!);
    } else {
      try {
        // Prioridad 1: Diccionario Vectorial SVG Oficial (2,427 señas vectoriales)
        jsonStr = await rootBundle.loadString('assets/matrices/diccionario_matrices_svg.json');
      } catch (_) {
        try {
          // Fallback 1: Diccionario de Matrices WebP
          jsonStr = await rootBundle.loadString('assets/matrices/diccionario_matrices.json');
        } catch (_) {
          // Fallback 2: Mockup básico
          jsonStr = await rootBundle.loadString('assets/mockup/mock_dictionary.json');
        }
      }
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
    final phoneticMap = <String, MockSignEntry>{};
    final alphabet = <String, MockSignEntry>{};

    void addKey(String rawKey, MockSignEntry entry) {
      final k = _normalize(rawKey);
      if (k.isNotEmpty && !map.containsKey(k)) {
        map[k] = entry;
        final ph = _spanishPhonetic(k);
        if (ph.isNotEmpty && !phoneticMap.containsKey(ph)) {
          phoneticMap[ph] = entry;
        }
      }
    }

    for (final entry in list) {
      final raw = entry.palabra.trim();
      final norm = _normalize(raw);
      addKey(norm, entry);

      // Si es una letra individual del abecedario (A-Z, Ñ), indexarla para dactilología
      final trimmed = raw.toUpperCase();
      if (trimmed.length == 1 && RegExp(r'^[A-ZÑ]$').hasMatch(trimmed)) {
        alphabet.putIfAbsent(trimmed, () => entry);
      }

      // 1. Manejar aclaraciones y sinónimos entre paréntesis: ej. "BANCO (FINANCIERO)", "ANULAR (CANCELAR)"
      if (raw.contains('(') && raw.contains(')')) {
        final openIdx = raw.indexOf('(');
        final closeIdx = raw.indexOf(')');
        if (openIdx >= 0 && closeIdx > openIdx) {
          final beforeParen = raw.substring(0, openIdx).trim();
          final insideParen = raw.substring(openIdx + 1, closeIdx).trim();
          addKey(beforeParen, entry);
          if (insideParen.isNotEmpty &&
              !insideParen.contains(RegExp(r'\d')) &&
              insideParen.split(RegExp(r'\s+')).length <= 2) {
            addKey(insideParen, entry);
          }
        }
      }

      // 2. Manejar variantes con coma: ej. "AMIGO, GA", "UNO, UNA", "BAÑAR, SE"
      if (raw.contains(',')) {
        final parts = raw.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          final base = parts[0];
          addKey(base, entry);

          if (parts.length > 1) {
            final suffix = parts[1];
            final sufUpper = suffix.toUpperCase();
            final baseUpper = base.toUpperCase();

            // Verbo reflexivo: "BAÑAR, SE" -> "BAÑARSE"
            if (sufUpper == 'SE') {
              addKey('${base}SE', entry);
            }
            // Palabra completa o sinónimo: "ABAJO, DEBAJO", "UNO, UNA", "PIJAMA, PIYAMA"
            else if (suffix.length >= 3 &&
                (suffix.contains(' ') || suffix.length >= base.length - 2)) {
              addKey(suffix, entry);
            }
            // Sufijo de flexión de género:
            else {
              if (sufUpper == 'A' && (baseUpper.endsWith('O') || baseUpper.endsWith('E'))) {
                addKey('${base.substring(0, base.length - 1)}A', entry);
              } else if (sufUpper.startsWith('R') && baseUpper.endsWith('R')) {
                // DOCTOR, RA -> DOCTORA
                addKey('$base${suffix.substring(1)}', entry);
              } else if (sufUpper.length == 2 &&
                  sufUpper.endsWith('A') &&
                  RegExp(r'(DO|TO|NO|RO|SO|VO|JO|MO|CO|GO|LO|ZO|FO)$').hasMatch(baseUpper)) {
                // ABOGADO, DA -> ABOGADA; AMIGO, GA -> AMIGA; GATO, TA -> GATA
                addKey('${base.substring(0, base.length - 2)}$suffix', entry);
              } else if (sufUpper.length == 3 &&
                  RegExp(r'(LLO|TRO|RIO|BIO|CIO|ÑCO)$').hasMatch(baseUpper)) {
                // AMARILLO, LLA -> AMARILLA; MAESTRO, TRA -> MAESTRA
                addKey('${base.substring(0, base.length - 3)}$suffix', entry);
              } else if (sufUpper == 'TRIZ' && baseUpper.endsWith('TOR')) {
                // ACTOR, TRIZ -> ACTRIZ
                addKey('${base.substring(0, base.length - 3)}TRIZ', entry);
              } else if (sufUpper == 'SA' && baseUpper.endsWith('DE')) {
                // ALCALDE, SA -> ALCALDESA
                addKey('${base.substring(0, base.length - 2)}DESA', entry);
              } else {
                if (baseUpper.endsWith('O') && sufUpper.endsWith('A')) {
                  addKey('${base.substring(0, base.length - 1)}A', entry);
                }
                addKey('$base$suffix', entry);
              }
            }
          }
        }
      }

      // 3. Mapeo de apócopes y formas comunes del español
      final rawUpper = raw.toUpperCase();
      if (rawUpper.contains('UNO, UNA') || rawUpper == 'UNO') {
        addKey('UN', entry);
        addKey('UNO', entry);
        addKey('UNA', entry);
      }
      if (rawUpper.contains('BUENO, NA') || rawUpper == 'BUENO') {
        addKey('BUEN', entry);
      }
      if (rawUpper.contains('PRIMERO, RA') || rawUpper == 'PRIMERO') {
        addKey('PRIMER', entry);
      }
      if (rawUpper.contains('TERCERO, RA') || rawUpper == 'TERCERO') {
        addKey('TERCER', entry);
      }
      if (rawUpper.contains('GRANDE')) {
        addKey('GRAN', entry);
      }
      if (rawUpper.contains('CIENTO')) {
        addKey('CIEN', entry);
      }
    }
    _normalizedIndex = map;
    _phoneticIndex = phoneticMap;
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
  ///
  /// Si [explicit] es `true`, solo se aceptan coincidencias literales exactas.
  /// Si [explicit] es `false`, se activan autocorrecciones fonéticas (ej. avogado -> abogado),
  /// resolución de sinónimos conceptuales (ej. hallar -> encontrar) y distancia de edición Levenshtein.
  Future<MockSignEntry?> findFlexible(String word, {bool explicit = false}) async {
    final all = await getAll();
    final w = _normalize(word);
    if (w.isEmpty) return null;

    // 1. Coincidencia exacta desde índice rápido optimizado
    if (_normalizedIndex != null && _normalizedIndex!.containsKey(w)) {
      return _normalizedIndex![w];
    }

    // 2. Coincidencia exacta recorriendo lista por si no estaba en índice
    for (final entry in all) {
      final norm = _normalize(entry.palabra);
      if (norm == w) return entry;
    }

    // 3. Fallback para plurales en español (ej. "AMIGOS" -> "AMIGO", "CASAS" -> "CASA")
    if (w.endsWith('ES') && w.length > 3) {
      final singular = w.substring(0, w.length - 2);
      final found = await findFlexible(singular, explicit: true);
      if (found != null) return found;
    }
    if (w.endsWith('S') && w.length > 2) {
      final singular = w.substring(0, w.length - 1);
      final found = await findFlexible(singular, explicit: true);
      if (found != null) return found;
    }

    // Si el modo explícito está activado, finalizar aquí sin autocorrecciones
    if (explicit) {
      return null;
    }

    // -------------------------------------------------------------------------
    // MODO INTELIGENTE / FLEXIBLE (Solo si la palabra no existe de forma exacta)
    // -------------------------------------------------------------------------

    // 4. Búsqueda por similitud fonética en español (B/V, LL/Y, Z/S, H muda)
    if (_phoneticIndex != null) {
      final ph = _spanishPhonetic(w);
      if (_phoneticIndex!.containsKey(ph)) {
        return _phoneticIndex![ph];
      }
    }

    // 5. Búsqueda por tabla de sinónimos comunes del español
    if (_commonSynonyms.containsKey(w)) {
      final synonymTarget = _commonSynonyms[w]!;
      final synonymSign = await findFlexible(synonymTarget, explicit: true);
      if (synonymSign != null) return synonymSign;
    }

    // 6. Búsqueda por distancia Levenshtein (<= 1 para palabras de longitud >= 4)
    if (_normalizedIndex != null && w.length >= 4) {
      for (final entry in _normalizedIndex!.entries) {
        final key = entry.key;
        if ((key.length - w.length).abs() <= 1) {
          if (_levenshtein(w, key) == 1) {
            return entry.value;
          }
        }
      }
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
  Future<TranslationResult> translatePhrase(String phrase, {bool explicit = false}) async {
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
        final sign = await findFlexible(triGram, explicit: explicit);
        if (sign != null) {
          matched.add(sign);
          i += 3;
          continue;
        }
      }

      // 2. Probar bigrama (ej. "BUENOS DIAS", "COMO ESTAS", "POR FAVOR", "A TRAVES")
      if (i + 1 < tokens.length) {
        final biGram = '${tokens[i]} ${tokens[i + 1]}';
        final sign = await findFlexible(biGram, explicit: explicit);
        if (sign != null) {
          matched.add(sign);
          i += 2;
          continue;
        }
      }

      // 3. Probar palabra individual (unigrama)
      final singleWord = tokens[i];
      final sign = await findFlexible(singleWord, explicit: explicit);
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
                svgAsset: letterSign.svgAsset,
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
