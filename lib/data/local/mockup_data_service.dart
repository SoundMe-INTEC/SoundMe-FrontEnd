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

class _SuffixRule {
  final String suffix;
  final List<String> candidateEndings;
  const _SuffixRule(this.suffix, this.candidateEndings);
}

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

  /// Tabla completa de lemas y conjugaciones de verbos irregulares y frecuentes del español.
  /// Mapea cualquier tiempo (presente, pretérito, copretérito/imperfecto, futuro, subjuntivo, condicional,
  /// gerundio y participio) directamente a su seña oficial en infinitivo o equivalente en LSRD.
  static const Map<String, String> _verbLemmas = {
    // QUERER (Cubre 'quería', 'quiero', 'quise', 'quisiera', etc.)
    'QUIERO': 'QUERER',
    'QUIERES': 'QUERER',
    'QUIERE': 'QUERER',
    'QUEREMOS': 'QUERER',
    'QUEREIS': 'QUERER',
    'QUIEREN': 'QUERER',
    'QUERIA': 'QUERER',
    'QUERIAS': 'QUERER',
    'QUERIAMOS': 'QUERER',
    'QUERIAIS': 'QUERER',
    'QUERIAN': 'QUERER',
    'QUISE': 'QUERER',
    'QUISISTE': 'QUERER',
    'QUISO': 'QUERER',
    'QUISIMOS': 'QUERER',
    'QUISISTEIS': 'QUERER',
    'QUISIERON': 'QUERER',
    'QUERRE': 'QUERER',
    'QUERRAS': 'QUERER',
    'QUERRA': 'QUERER',
    'QUERREMOS': 'QUERER',
    'QUERREIS': 'QUERER',
    'QUERRAN': 'QUERER',
    'QUERRIA': 'QUERER',
    'QUERRIAS': 'QUERER',
    'QUERRIAMOS': 'QUERER',
    'QUERRIAIS': 'QUERER',
    'QUERRIAN': 'QUERER',
    'QUIERA': 'QUERER',
    'QUIERAS': 'QUERER',
    'QUERAMOS': 'QUERER',
    'QUERAIS': 'QUERER',
    'QUIERAN': 'QUERER',
    'QUISIERA': 'QUERER',
    'QUISIERAS': 'QUERER',
    'QUISIERAMOS': 'QUERER',
    'QUISIERAIS': 'QUERER',
    'QUISIERAN': 'QUERER',
    'QUISIESE': 'QUERER',
    'QUISIESES': 'QUERER',
    'QUISIESEMOS': 'QUERER',
    'QUISIESEIS': 'QUERER',
    'QUISIESEN': 'QUERER',
    'QUERIENDO': 'QUERER',
    'QUERIDO': 'QUERER',
    'QUERIDA': 'QUERER',
    'QUERIDOS': 'QUERER',
    'QUERIDAS': 'QUERER',
    'QUERERTE': 'QUERER',
    'QUERERME': 'QUERER',
    'QUERERLO': 'QUERER',
    'QUERERLA': 'QUERER',
    'QUERERNOS': 'QUERER',
    'QUERERLOS': 'QUERER',
    'QUERERLAS': 'QUERER',
    'QUERERLE': 'QUERER',
    'QUERERLES': 'QUERER',

    // IR (Cubre 'voy', 'iba', 'fui', 'irá', 'vaya', etc.)
    'VOY': 'IR',
    'VAS': 'IR',
    'VA': 'IR',
    'VAMOS': 'IR',
    'VAIS': 'IR',
    'VAN': 'IR',
    'IBA': 'IR',
    'IBAS': 'IR',
    'IBAMOS': 'IR',
    'IBAIS': 'IR',
    'IBAN': 'IR',
    'FUI': 'IR',
    'FUISTE': 'IR',
    'FUE': 'IR',
    'FUIMOS': 'IR',
    'FUISTEIS': 'IR',
    'FUERON': 'IR',
    'IRE': 'IR',
    'IRAS': 'IR',
    'IRA': 'IR',
    'IREMOS': 'IR',
    'IREIS': 'IR',
    'IRAN': 'IR',
    'IRIA': 'IR',
    'IRIAS': 'IR',
    'IRIAMOS': 'IR',
    'IRIAIS': 'IR',
    'IRIAN': 'IR',
    'VAYA': 'IR',
    'VAYAS': 'IR',
    'VAYAMOS': 'IR',
    'VAYAIS': 'IR',
    'VAYAN': 'IR',
    'FUERA': 'IR',
    'FUERAS': 'IR',
    'FUERAMOS': 'IR',
    'FUERAIS': 'IR',
    'FUERAN': 'IR',
    'FUESE': 'IR',
    'FUESES': 'IR',
    'FUESEMOS': 'IR',
    'FUESEIS': 'IR',
    'FUESEN': 'IR',
    'YENDO': 'IR',
    'IDO': 'IR',
    'IDA': 'IR',
    'IDOS': 'IR',
    'IDAS': 'IR',
    'IRME': 'IR',
    'IRTE': 'IR',
    'IRSE': 'IR',
    'IRNOS': 'IR',

    // TENER (Cubre 'tengo', 'tenía', 'tuve', 'tendré', 'tenga', etc.)
    'TENGO': 'TENER',
    'TIENES': 'TENER',
    'TIENE': 'TENER',
    'TENEMOS': 'TENER',
    'TENEIS': 'TENER',
    'TIENEN': 'TENER',
    'TENIA': 'TENER',
    'TENIAS': 'TENER',
    'TENIAMOS': 'TENER',
    'TENIAIS': 'TENER',
    'TENIAN': 'TENER',
    'TUVE': 'TENER',
    'TUVISTE': 'TENER',
    'TUVO': 'TENER',
    'TUVIMOS': 'TENER',
    'TUVISTEIS': 'TENER',
    'TUVIERON': 'TENER',
    'TENDRE': 'TENER',
    'TENDRAS': 'TENER',
    'TENDRA': 'TENER',
    'TENDREMOS': 'TENER',
    'TENDREIS': 'TENER',
    'TENDRAN': 'TENER',
    'TENDRIA': 'TENER',
    'TENDRIAS': 'TENER',
    'TENDRIAMOS': 'TENER',
    'TENDRIAIS': 'TENER',
    'TENDRIAN': 'TENER',
    'TENGA': 'TENER',
    'TENGAS': 'TENER',
    'TENGAMOS': 'TENER',
    'TENGAIS': 'TENER',
    'TENGAN': 'TENER',
    'TUVIERA': 'TENER',
    'TUVIERAS': 'TENER',
    'TUVIERAMOS': 'TENER',
    'TUVIERAIS': 'TENER',
    'TUVIERAN': 'TENER',
    'TUVIESE': 'TENER',
    'TUVIESES': 'TENER',
    'TUVIESEMOS': 'TENER',
    'TUVIESEIS': 'TENER',
    'TUVIESEN': 'TENER',
    'TENIENDO': 'TENER',
    'TENIDO': 'TENER',
    'TENIDA': 'TENER',
    'TENERTE': 'TENER',
    'TENERME': 'TENER',
    'TENERLO': 'TENER',
    'TENERLA': 'TENER',
    'TENERNOS': 'TENER',

    // PODER (Cubre 'puedo', 'podía', 'pude', 'podré', 'pueda', etc.)
    'PUEDO': 'PODER',
    'PUEDES': 'PODER',
    'PUEDE': 'PODER',
    'PODEMOS': 'PODER',
    'PODEIS': 'PODER',
    'PUEDEN': 'PODER',
    'PODIA': 'PODER',
    'PODIAS': 'PODER',
    'PODIAMOS': 'PODER',
    'PODIAIS': 'PODER',
    'PODIAN': 'PODER',
    'PUDE': 'PODER',
    'PUDISTE': 'PODER',
    'PUDO': 'PODER',
    'PUDIMOS': 'PODER',
    'PUDISTEIS': 'PODER',
    'PUDIERON': 'PODER',
    'PODRE': 'PODER',
    'PODRAS': 'PODER',
    'PODRA': 'PODER',
    'PODREMOS': 'PODER',
    'PODREIS': 'PODER',
    'PODRAN': 'PODER',
    'PODRIA': 'PODER',
    'PODRIAS': 'PODER',
    'PODRIAMOS': 'PODER',
    'PODRIAIS': 'PODER',
    'PODRIAN': 'PODER',
    'PUEDA': 'PODER',
    'PUEDAS': 'PODER',
    'PODAMOS': 'PODER',
    'PODAIS': 'PODER',
    'PUEDAN': 'PODER',
    'PUDIERA': 'PODER',
    'PUDIERAS': 'PODER',
    'PUDIERAMOS': 'PODER',
    'PUDIERAIS': 'PODER',
    'PUDIERAN': 'PODER',
    'PUDIESE': 'PODER',
    'PUDIESES': 'PODER',
    'PUDIESEMOS': 'PODER',
    'PUDIESEIS': 'PODER',
    'PUDIESEN': 'PODER',
    'PUDIENDO': 'PODER',
    'PODIDO': 'PODER',

    // HACER (Cubre 'hago', 'hacía', 'hice', 'hizo', 'haré', 'haga', etc.)
    'HAGO': 'HACER',
    'HACES': 'HACER',
    'HACE': 'HACER',
    'HACEMOS': 'HACER',
    'HACEIS': 'HACER',
    'HACEN': 'HACER',
    'HACIA': 'HACER',
    'HACIAS': 'HACER',
    'HACIAMOS': 'HACER',
    'HACIAIS': 'HACER',
    'HACIAN': 'HACER',
    'HICE': 'HACER',
    'HICISTE': 'HACER',
    'HIZO': 'HACER',
    'HICIMOS': 'HACER',
    'HICISTEIS': 'HACER',
    'HICIERON': 'HACER',
    'HARE': 'HACER',
    'HARAS': 'HACER',
    'HARA': 'HACER',
    'HAREMOS': 'HACER',
    'HAREIS': 'HACER',
    'HARAN': 'HACER',
    'HARIA': 'HACER',
    'HARIAS': 'HACER',
    'HARIAMOS': 'HACER',
    'HARIAIS': 'HACER',
    'HARIAN': 'HACER',
    'HAGA': 'HACER',
    'HAGAS': 'HACER',
    'HAGAMOS': 'HACER',
    'HAGAIS': 'HACER',
    'HAGAN': 'HACER',
    'HICIERA': 'HACER',
    'HICIERAS': 'HACER',
    'HICIERAMOS': 'HACER',
    'HICIERAIS': 'HACER',
    'HICIERAN': 'HACER',
    'HICIESE': 'HACER',
    'HICIESES': 'HACER',
    'HICIESEMOS': 'HACER',
    'HICIESEIS': 'HACER',
    'HICIESEN': 'HACER',
    'HACIENDO': 'HACER',
    'HECHO': 'HACER',
    'HECHA': 'HACER',
    'HECHOS': 'HACER',
    'HECHAS': 'HACER',
    'HACERLO': 'HACER',
    'HACERLA': 'HACER',
    'HACERME': 'HACER',
    'HACERTE': 'HACER',
    'HACERNOS': 'HACER',

    // DECIR (Cubre 'digo', 'decía', 'dije', 'dijo', 'diré', 'diga', etc.)
    'DIGO': 'DECIR',
    'DICES': 'DECIR',
    'DICE': 'DECIR',
    'DECIMOS': 'DECIR',
    'DECIS': 'DECIR',
    'DICEN': 'DECIR',
    'DECIA': 'DECIR',
    'DECIAS': 'DECIR',
    'DECIAMOS': 'DECIR',
    'DECIAIS': 'DECIR',
    'DECIAN': 'DECIR',
    'DIJE': 'DECIR',
    'DIJISTE': 'DECIR',
    'DIJO': 'DECIR',
    'DIJIMOS': 'DECIR',
    'DIJISTEIS': 'DECIR',
    'DIJERON': 'DECIR',
    'DIRE': 'DECIR',
    'DIRAS': 'DECIR',
    'DIRA': 'DECIR',
    'DIREMOS': 'DECIR',
    'DIREIS': 'DECIR',
    'DIRAN': 'DECIR',
    'DIRIA': 'DECIR',
    'DIRIAS': 'DECIR',
    'DIRIAMOS': 'DECIR',
    'DIRIAIS': 'DECIR',
    'DIRIAN': 'DECIR',
    'DIGA': 'DECIR',
    'DIGAS': 'DECIR',
    'DIGAMOS': 'DECIR',
    'DIGAIS': 'DECIR',
    'DIGAN': 'DECIR',
    'DIJERA': 'DECIR',
    'DIJERAS': 'DECIR',
    'DIJERAMOS': 'DECIR',
    'DIJERAIS': 'DECIR',
    'DIJERAN': 'DECIR',
    'DIJESE': 'DECIR',
    'DICIENDO': 'DECIR',
    'DICHO': 'DECIR',
    'DICHA': 'DECIR',
    'DIME': 'DECIR',
    'DILE': 'DECIR',
    'DINOS': 'DECIR',
    'DECIRTE': 'DECIR',
    'DECIRME': 'DECIR',
    'DECIRLE': 'DECIR',
    'DECIRLES': 'DECIR',
    'DECIRNOS': 'DECIR',

    // SABER (Cubre 'sé', 'sabía', 'supe', 'supo', 'sabré', 'sepa', etc.)
    'SE': 'SABER',
    'SABES': 'SABER',
    'SABE': 'SABER',
    'SABEMOS': 'SABER',
    'SABEIS': 'SABER',
    'SABEN': 'SABER',
    'SABIA': 'SABER',
    'SABIAS': 'SABER',
    'SABIAMOS': 'SABER',
    'SABIAIS': 'SABER',
    'SABIAN': 'SABER',
    'SUPE': 'SABER',
    'SUPISTE': 'SABER',
    'SUPO': 'SABER',
    'SUPIMOS': 'SABER',
    'SUPISTEIS': 'SABER',
    'SUPIERON': 'SABER',
    'SABRE': 'SABER',
    'SABRAS': 'SABER',
    'SABRA': 'SABER',
    'SABREMOS': 'SABER',
    'SABREIS': 'SABER',
    'SABRAN': 'SABER',
    'SABRIA': 'SABER',
    'SABRIAS': 'SABER',
    'SABRIAMOS': 'SABER',
    'SABRIAIS': 'SABER',
    'SABRIAN': 'SABER',
    'SEPA': 'SABER',
    'SEPAS': 'SABER',
    'SEPAMOS': 'SABER',
    'SEPAIS': 'SABER',
    'SEPAN': 'SABER',
    'SUPIERA': 'SABER',
    'SUPIERAS': 'SABER',
    'SUPIERAMOS': 'SABER',
    'SUPIERAIS': 'SABER',
    'SUPIERAN': 'SABER',
    'SABIENDO': 'SABER',
    'SABIDO': 'SABER',

    // VER (Cubre 'veo', 'veía', 'vi', 'vio', 'veré', 'vea', etc.)
    'VEO': 'VER',
    'VES': 'VER',
    'VE': 'VER',
    'VEMOS': 'VER',
    'VEIS': 'VER',
    'VEN': 'VER',
    'VEIA': 'VER',
    'VEIAS': 'VER',
    'VEIAMOS': 'VER',
    'VEIAIS': 'VER',
    'VEIAN': 'VER',
    'VI': 'VER',
    'VISTE': 'VER',
    'VIO': 'VER',
    'VIMOS': 'VER',
    'VISTEIS': 'VER',
    'VIERON': 'VER',
    'VERE': 'VER',
    'VERAS': 'VER',
    'VERA': 'VER',
    'VEREMOS': 'VER',
    'VEREIS': 'VER',
    'VERAN': 'VER',
    'VERIA': 'VER',
    'VERIAS': 'VER',
    'VERIAMOS': 'VER',
    'VERIAIS': 'VER',
    'VERIAN': 'VER',
    'VEA': 'VER',
    'VEAS': 'VER',
    'VEAMOS': 'VER',
    'VEAIS': 'VER',
    'VEAN': 'VER',
    'VIERA': 'VER',
    'VIERAS': 'VER',
    'VIERAMOS': 'VER',
    'VIERAIS': 'VER',
    'VIERAN': 'VER',
    'VIENDO': 'VER',
    'VISTO': 'VER',
    'VISTA': 'VER',
    'VERTE': 'VER',
    'VERME': 'VER',
    'VERLO': 'VER',
    'VERLA': 'VER',
    'VERNOS': 'VER',

    // DAR (Cubre 'doy', 'daba', 'di', 'dio', 'daré', 'dé', etc.)
    'DOY': 'DAR',
    'DAS': 'DAR',
    'DA': 'DAR',
    'DAMOS': 'DAR',
    'DAIS': 'DAR',
    'DAN': 'DAR',
    'DABA': 'DAR',
    'DABAS': 'DAR',
    'DABAMOS': 'DAR',
    'DABAIS': 'DAR',
    'DABAN': 'DAR',
    'DI': 'DAR',
    'DISTE': 'DAR',
    'DIO': 'DAR',
    'DIMOS': 'DAR',
    'DISTEIS': 'DAR',
    'DIERON': 'DAR',
    'DARE': 'DAR',
    'DARAS': 'DAR',
    'DARA': 'DAR',
    'DAREMOS': 'DAR',
    'DAREIS': 'DAR',
    'DARAN': 'DAR',
    'DARIA': 'DAR',
    'DARIAS': 'DAR',
    'DARIAMOS': 'DAR',
    'DARIAIS': 'DAR',
    'DARIAN': 'DAR',
    'DE': 'DAR',
    'DES': 'DAR',
    'DEMOS': 'DAR',
    'DEIS': 'DAR',
    'DEN': 'DAR',
    'DIERA': 'DAR',
    'DIERAS': 'DAR',
    'DIERAMOS': 'DAR',
    'DIERAIS': 'DAR',
    'DIERAN': 'DAR',
    'DANDO': 'DAR',
    'DADO': 'DAR',
    'DADA': 'DAR',
    'DARTE': 'DAR',
    'DARME': 'DAR',
    'DARLE': 'DAR',
    'DARLES': 'DAR',
    'DARNOS': 'DAR',
    'DARLO': 'DAR',
    'DARLA': 'DAR',

    // VENIR (Cubre 'vengo', 'venía', 'vine', 'vino', 'vendré', 'venga', etc.)
    'VENGO': 'VENIR',
    'VIENES': 'VENIR',
    'VIENE': 'VENIR',
    'VENIMOS': 'VENIR',
    'VENIS': 'VENIR',
    'VIENEN': 'VENIR',
    'VENIA': 'VENIR',
    'VENIAS': 'VENIR',
    'VENIAMOS': 'VENIR',
    'VENIAIS': 'VENIR',
    'VENIAN': 'VENIR',
    'VINE': 'VENIR',
    'VINISTE': 'VENIR',
    'VINO': 'VENIR',
    'VINIMOS': 'VENIR',
    'VINISTEIS': 'VENIR',
    'VINIERON': 'VENIR',
    'VENDRE': 'VENIR',
    'VENDRAS': 'VENIR',
    'VENDRA': 'VENIR',
    'VENDREMOS': 'VENIR',
    'VENDREIS': 'VENIR',
    'VENDRAN': 'VENIR',
    'VENDRIA': 'VENIR',
    'VENGA': 'VENIR',
    'VENGAS': 'VENIR',
    'VENGAMOS': 'VENIR',
    'VENGAIS': 'VENIR',
    'VENGAN': 'VENIR',
    'VINIERA': 'VENIR',
    'VINIENDO': 'VENIR',
    'VENIDO': 'VENIR',

    // PONER (Cubre 'pongo', 'ponía', 'puse', 'puso', 'pondré', 'ponga', etc.)
    'PONGO': 'PONER',
    'PONES': 'PONER',
    'PONE': 'PONER',
    'PONEMOS': 'PONER',
    'PONEIS': 'PONER',
    'PONEN': 'PONER',
    'PONIA': 'PONER',
    'PONIAS': 'PONER',
    'PONIAMOS': 'PONER',
    'PONIAIS': 'PONER',
    'PONIAN': 'PONER',
    'PUSE': 'PONER',
    'PUSISTE': 'PONER',
    'PUSO': 'PONER',
    'PUSIMOS': 'PONER',
    'PUSISTEIS': 'PONER',
    'PUSIERON': 'PONER',
    'PONDRE': 'PONER',
    'PONDRAS': 'PONER',
    'PONDRA': 'PONER',
    'PONDREMOS': 'PONER',
    'PONDREIS': 'PONER',
    'PONDRAN': 'PONER',
    'PONDRIA': 'PONER',
    'PONGA': 'PONER',
    'PONGAS': 'PONER',
    'PONGAMOS': 'PONER',
    'PONGAIS': 'PONER',
    'PONGAN': 'PONER',
    'PUSIERA': 'PONER',
    'PONIENDO': 'PONER',
    'PUESTO': 'PONER',
    'PUESTA': 'PONER',

    // SALIR (Cubre 'salgo', 'salía', 'salí', 'salió', 'saldré', 'salga', etc.)
    'SALGO': 'SALIR',
    'SALES': 'SALIR',
    'SALE': 'SALIR',
    'SALIMOS': 'SALIR',
    'SALIS': 'SALIR',
    'SALEN': 'SALIR',
    'SALIA': 'SALIR',
    'SALIAS': 'SALIR',
    'SALIAMOS': 'SALIR',
    'SALIAIS': 'SALIR',
    'SALIAN': 'SALIR',
    'SALI': 'SALIR',
    'SALISTE': 'SALIR',
    'SALIO': 'SALIR',
    'SALIERON': 'SALIR',
    'SALDRE': 'SALIR',
    'SALDRAS': 'SALIR',
    'SALDRA': 'SALIR',
    'SALDREMOS': 'SALIR',
    'SALDREIS': 'SALIR',
    'SALDRAN': 'SALIR',
    'SALDRIA': 'SALIR',
    'SALGA': 'SALIR',
    'SALGAS': 'SALIR',
    'SALGAMOS': 'SALIR',
    'SALGAIS': 'SALIR',
    'SALGAN': 'SALIR',
    'SALIERA': 'SALIR',
    'SALIENDO': 'SALIR',
    'SALIDO': 'SALIR',

    // TRAER
    'TRAIGO': 'TRAER',
    'TRAES': 'TRAER',
    'TRAE': 'TRAER',
    'TRAEMOS': 'TRAER',
    'TRAEIS': 'TRAER',
    'TRAEN': 'TRAER',
    'TRAIA': 'TRAER',
    'TRAIAS': 'TRAER',
    'TRAIAMOS': 'TRAER',
    'TRAIAIS': 'TRAER',
    'TRAIAN': 'TRAER',
    'TRAJE': 'TRAER',
    'TRAJISTE': 'TRAER',
    'TRAJO': 'TRAER',
    'TRAJIMOS': 'TRAER',
    'TRAJISTEIS': 'TRAER',
    'TRAJERON': 'TRAER',
    'TRAERE': 'TRAER',
    'TRAERAS': 'TRAER',
    'TRAERA': 'TRAER',
    'TRAEREMOS': 'TRAER',
    'TRAEREIS': 'TRAER',
    'TRAERAN': 'TRAER',
    'TRAERIA': 'TRAER',
    'TRAIGA': 'TRAER',
    'TRAIGAS': 'TRAER',
    'TRAIGAMOS': 'TRAER',
    'TRAIGAIS': 'TRAER',
    'TRAIGAN': 'TRAER',
    'TRAJERA': 'TRAER',
    'TRAYENDO': 'TRAER',
    'TRAIDO': 'TRAER',

    // OÍR -> ESCUCHAR (Equivalente canónico en LSRD)
    'OIR': 'ESCUCHAR',
    'OIGO': 'ESCUCHAR',
    'OYES': 'ESCUCHAR',
    'OYE': 'ESCUCHAR',
    'OIMOS': 'ESCUCHAR',
    'OIS': 'ESCUCHAR',
    'OYEN': 'ESCUCHAR',
    'OIA': 'ESCUCHAR',
    'OIAS': 'ESCUCHAR',
    'OIAMOS': 'ESCUCHAR',
    'OIAIS': 'ESCUCHAR',
    'OIAN': 'ESCUCHAR',
    'OI': 'ESCUCHAR',
    'OISTE': 'ESCUCHAR',
    'OYO': 'ESCUCHAR',
    'OYERON': 'ESCUCHAR',
    'OIRE': 'ESCUCHAR',
    'OIRA': 'ESCUCHAR',
    'OIGA': 'ESCUCHAR',
    'OIGAN': 'ESCUCHAR',
    'OYENDO': 'ESCUCHAR',
    'OIDO': 'ESCUCHAR',

    // COMER -> COMIDA (Equivalente canónico en LSRD)
    'COMER': 'COMIDA',
    'COMO': 'COMIDA',
    'COMES': 'COMIDA',
    'COME': 'COMIDA',
    'COMEMOS': 'COMIDA',
    'COMEIS': 'COMIDA',
    'COMEN': 'COMIDA',
    'COMIA': 'COMIDA',
    'COMIAS': 'COMIDA',
    'COMIAMOS': 'COMIDA',
    'COMIAIS': 'COMIDA',
    'COMIAN': 'COMIDA',
    'COMI': 'COMIDA',
    'COMISTE': 'COMIDA',
    'COMIO': 'COMIDA',
    'COMIMOS': 'COMIDA',
    'COMISTEIS': 'COMIDA',
    'COMIERON': 'COMIDA',
    'COMERE': 'COMIDA',
    'COMERA': 'COMIDA',
    'COMERIA': 'COMIDA',
    'COMA': 'COMIDA',
    'COMAN': 'COMIDA',
    'COMIENDO': 'COMIDA',
    'COMIDO': 'COMIDA',
    'COMERLO': 'COMIDA',
    'COMERLA': 'COMIDA',
    'COMERTE': 'COMIDA',
    'COMERME': 'COMIDA',

    // DORMIR
    'DUERMO': 'DORMIR',
    'DUERMES': 'DORMIR',
    'DUERME': 'DORMIR',
    'DORMIMOS': 'DORMIR',
    'DORMIS': 'DORMIR',
    'DUERMEN': 'DORMIR',
    'DORMIA': 'DORMIR',
    'DORMIAS': 'DORMIR',
    'DORMIAMOS': 'DORMIR',
    'DORMIAIS': 'DORMIR',
    'DORMIAN': 'DORMIR',
    'DORMI': 'DORMIR',
    'DORMISTE': 'DORMIR',
    'DURMIO': 'DORMIR',
    'DORMIMOS_P': 'DORMIR',
    'DURMIERON': 'DORMIR',
    'DORMIRE': 'DORMIR',
    'DORMIRA': 'DORMIR',
    'DUERMA': 'DORMIR',
    'DUERMAN': 'DORMIR',
    'DURMIENDO': 'DORMIR',
    'DORMIDO': 'DORMIR',

    // SENTAR / SENTARSE
    'SIENTO': 'SENTARSE',
    'SIENTAS': 'SENTARSE',
    'SIENTA': 'SENTARSE',
    'SENTAMOS': 'SENTARSE',
    'SENTAIS': 'SENTARSE',
    'SIENTAN': 'SENTARSE',
    'SENTABA': 'SENTARSE',
    'SENTABAS': 'SENTARSE',
    'SENTABAMOS': 'SENTARSE',
    'SENTABAN': 'SENTARSE',
    'SENTE': 'SENTARSE',
    'SENTASTE': 'SENTARSE',
    'SENTO': 'SENTARSE',
    'SENTARON': 'SENTARSE',
    'SIENTATE': 'SENTARSE',
    'SENTATE': 'SENTARSE',
    'SENTARME': 'SENTARSE',
    'SENTARTE': 'SENTARSE',
    'SENTARNOS': 'SENTARSE',
    'SENTANDO': 'SENTARSE',
    'SENTADO': 'SENTARSE',
    'SENTADA': 'SENTARSE',

    // SENTIR / SENTIRSE
    'SIENTES': 'SENTIR',
    'SIENTE': 'SENTIR',
    'SENTIMOS': 'SENTIR',
    'SENTIS': 'SENTIR',
    'SIENTEN': 'SENTIR',
    'SENTIA': 'SENTIR',
    'SENTIAS': 'SENTIR',
    'SENTIAMOS': 'SENTIR',
    'SENTIAN': 'SENTIR',
    'SENTI': 'SENTIR',
    'SENTISTE': 'SENTIR',
    'SINTIO': 'SENTIR',
    'SINTIERON': 'SENTIR',
    'SENTIRE': 'SENTIR',
    'SENTIRA': 'SENTIR',
    'SINTIENDO': 'SENTIR',
    'SENTIDO': 'SENTIR',

    // PEDIR
    'PIDO': 'PEDIR',
    'PIDES': 'PEDIR',
    'PIDE': 'PEDIR',
    'PEDIMOS': 'PEDIR',
    'PEDIS': 'PEDIR',
    'PIDEN': 'PEDIR',
    'PEDIA': 'PEDIR',
    'PEDIAS': 'PEDIR',
    'PEDIAMOS': 'PEDIR',
    'PEDIAN': 'PEDIR',
    'PEDI': 'PEDIR',
    'PEDISTE': 'PEDIR',
    'PIDIO': 'PEDIR',
    'PIDIERON': 'PEDIR',
    'PIDA': 'PEDIR',
    'PIDAN': 'PEDIR',
    'PIDIENDO': 'PEDIR',
    'PEDIDO': 'PEDIR',
    'PEDIRTE': 'PEDIR',
    'PEDIRME': 'PEDIR',
    'PEDIRLE': 'PEDIR',
    'PEDIRLES': 'PEDIR',
    'PEDIRNOS': 'PEDIR',

    // PENSAR
    'PIENSO': 'PENSAR',
    'PIENSAS': 'PENSAR',
    'PIENSA': 'PENSAR',
    'PENSAMOS': 'PENSAR',
    'PENSAIS': 'PENSAR',
    'PIENSAN': 'PENSAR',
    'PENSABA': 'PENSAR',
    'PENSABAS': 'PENSAR',
    'PENSABAMOS': 'PENSAR',
    'PENSABAN': 'PENSAR',
    'PENSE': 'PENSAR',
    'PENSASTE': 'PENSAR',
    'PENSO': 'PENSAR',
    'PENSARON': 'PENSAR',
    'PIENSE': 'PENSAR',
    'PIENSEN': 'PENSAR',
    'PENSANDO': 'PENSAR',
    'PENSADO': 'PENSAR',

    // RECORDAR
    'RECUERDO': 'RECORDAR',
    'RECUERDAS': 'RECORDAR',
    'RECUERDA': 'RECORDAR',
    'RECORDAMOS': 'RECORDAR',
    'RECUERDAN': 'RECORDAR',
    'RECORDABA': 'RECORDAR',
    'RECORDABAS': 'RECORDAR',
    'RECORDABAMOS': 'RECORDAR',
    'RECORDABAN': 'RECORDAR',
    'RECORDE': 'RECORDAR',
    'RECORDASTE': 'RECORDAR',
    'RECORDO': 'RECORDAR',
    'RECORDARON': 'RECORDAR',
    'RECUERDE': 'RECORDAR',
    'RECUERDEN': 'RECORDAR',
    'RECORDANDO': 'RECORDAR',
    'RECORDADO': 'RECORDAR',

    // VOLVER
    'VUELVO': 'VOLVER',
    'VUELVES': 'VOLVER',
    'VUELVE': 'VOLVER',
    'VOLVEMOS': 'VOLVER',
    'VOLVEIS': 'VOLVER',
    'VUELVEN': 'VOLVER',
    'VOLVIA': 'VOLVER',
    'VOLVIAS': 'VOLVER',
    'VOLVIAMOS': 'VOLVER',
    'VOLVIAN': 'VOLVER',
    'VOLVI': 'VOLVER',
    'VOLVISTE': 'VOLVER',
    'VOLVIO': 'VOLVER',
    'VOLVIERON': 'VOLVER',
    'VUELVA': 'VOLVER',
    'VUELVAN': 'VOLVER',
    'VOLVIENDO': 'VOLVER',
    'VUELTO': 'VOLVER',

    // EMPEZAR & COMENZAR
    'EMPIEZO': 'EMPEZAR',
    'EMPIEZAS': 'EMPEZAR',
    'EMPIEZA': 'EMPEZAR',
    'EMPEZAMOS': 'EMPEZAR',
    'EMPIEZAN': 'EMPEZAR',
    'EMPEZABA': 'EMPEZAR',
    'EMPECE': 'EMPEZAR',
    'EMPEZO': 'EMPEZAR',
    'EMPEZARON': 'EMPEZAR',
    'EMPIECE': 'EMPEZAR',
    'EMPIECEN': 'EMPEZAR',
    'EMPEZANDO': 'EMPEZAR',
    'EMPEZADO': 'EMPEZAR',
    'COMIENZO': 'COMENZAR',
    'COMIENZAS': 'COMENZAR',
    'COMIENZA': 'COMENZAR',
    'COMENZAMOS': 'COMENZAR',
    'COMIENZAN': 'COMENZAR',
    'COMENZABA': 'COMENZAR',
    'COMENCE': 'COMENZAR',
    'COMENZO': 'COMENZAR',
    'COMENZARON': 'COMENZAR',
    'COMIENCE': 'COMENZAR',
    'COMIENCEN': 'COMENZAR',
    'COMENZANDO': 'COMENZAR',

    // ENCONTRAR
    'ENCUENTRO': 'ENCONTRAR',
    'ENCUENTRAS': 'ENCONTRAR',
    'ENCUENTRA': 'ENCONTRAR',
    'ENCONTRAMOS': 'ENCONTRAR',
    'ENCUENTRAN': 'ENCONTRAR',
    'ENCONTRABA': 'ENCONTRAR',
    'ENCONTRE': 'ENCONTRAR',
    'ENCONTRO': 'ENCONTRAR',
    'ENCONTRARON': 'ENCONTRAR',
    'ENCUENTRE': 'ENCONTRAR',
    'ENCUENTREN': 'ENCONTRAR',
    'ENCONTRANDO': 'ENCONTRAR',
    'ENCONTRADO': 'ENCONTRAR',

    // JUGAR -> JUEGO
    'JUGAR': 'JUEGO',
    'JUEGO_V': 'JUEGO',
    'JUEGAS': 'JUEGO',
    'JUEGA': 'JUEGO',
    'JUGAMOS': 'JUEGO',
    'JUEGAN': 'JUEGO',
    'JUGABA': 'JUEGO',
    'JUGABAS': 'JUEGO',
    'JUGABAMOS': 'JUEGO',
    'JUGABAN': 'JUEGO',
    'JUGUE': 'JUEGO',
    'JUGASTE': 'JUEGO',
    'JUGO': 'JUEGO',
    'JUGARON': 'JUEGO',
    'JUEGUE': 'JUEGO',
    'JUEGUEN': 'JUEGO',
    'JUGANDO': 'JUEGO',
    'JUGADO': 'JUEGO',

    // ENTENDER
    'ENTIENDO': 'ENTENDER',
    'ENTIENDES': 'ENTENDER',
    'ENTIENDE': 'ENTENDER',
    'ENTENDEMOS': 'ENTENDER',
    'ENTIENDEIS': 'ENTENDER',
    'ENTIENDEN': 'ENTENDER',
    'ENTENDIA': 'ENTENDER',
    'ENTENDIAS': 'ENTENDER',
    'ENTENDIAMOS': 'ENTENDER',
    'ENTENDIAN': 'ENTENDER',
    'ENTENDI': 'ENTENDER',
    'ENTENDISTE': 'ENTENDER',
    'ENTENDIO': 'ENTENDER',
    'ENTENDIERON': 'ENTENDER',
    'ENTIENDA': 'ENTENDER',
    'ENTIENDAN': 'ENTENDER',
    'ENTENDIENDO': 'ENTENDER',
    'ENTENDIDO': 'ENTENDER',

    // CONOCER
    'CONOZCO': 'CONOCER',
    'CONOCES': 'CONOCER',
    'CONOCE': 'CONOCER',
    'CONOCEMOS': 'CONOCER',
    'CONOCEN': 'CONOCER',
    'CONOCIA': 'CONOCER',
    'CONOCIAS': 'CONOCER',
    'CONOCIAMOS': 'CONOCER',
    'CONOCIAN': 'CONOCER',
    'CONOCI': 'CONOCER',
    'CONOCISTE': 'CONOCER',
    'CONOCIO': 'CONOCER',
    'CONOCIERON': 'CONOCER',
    'CONOZCA': 'CONOCER',
    'CONOZCAN': 'CONOCER',
    'CONOCIENDO': 'CONOCER',
    'CONOCIDO': 'CONOCER',

    // AMAR -> AMOR
    'AMAR': 'AMOR',
    'AMO': 'AMOR',
    'AMAS': 'AMOR',
    'AMA': 'AMOR',
    'AMAMOS': 'AMOR',
    'AMAN': 'AMOR',
    'AMABA': 'AMOR',
    'AMABAS': 'AMOR',
    'AMABAMOS': 'AMOR',
    'AMABAN': 'AMOR',
    'AME': 'AMOR',
    'AMASTE': 'AMOR',
    'AMARON': 'AMOR',
    'AMANDO': 'AMOR',
    'AMADO': 'AMOR',
    'AMADA': 'AMOR',

    // MORIR -> MUERTE
    'MORIR': 'MUERTE',
    'MUERO': 'MUERTE',
    'MUERES': 'MUERTE',
    'MUERE': 'MUERTE',
    'MORIMOS': 'MUERTE',
    'MUEREN': 'MUERTE',
    'MORIA': 'MUERTE',
    'MORIAS': 'MUERTE',
    'MORIAMOS': 'MUERTE',
    'MORIAN': 'MUERTE',
    'MORI': 'MUERTE',
    'MORISTE': 'MUERTE',
    'MURIO': 'MUERTE',
    'MURIERON': 'MUERTE',
    'MUERA': 'MUERTE',
    'MUERAN': 'MUERTE',
    'MURIENDO': 'MUERTE',
    'MUERTO': 'MUERTE',
    'MUERTA': 'MUERTE',
    'MUERTOS': 'MUERTE',
    'MUERTAS': 'MUERTE',

    // GUSTAR -> ME GUSTA
    'GUSTA': 'ME GUSTA',
    'GUSTAN': 'ME GUSTA',
    'GUSTABA': 'ME GUSTA',
    'GUSTABAN': 'ME GUSTA',
    'GUSTO': 'ME GUSTA',
    'GUSTARON': 'ME GUSTA',
    'GUSTARIA': 'ME GUSTA',
    'GUSTARIAN': 'ME GUSTA',

    // LEER
    'LEO': 'LEER',
    'LEES': 'LEER',
    'LEE': 'LEER',
    'LEEMOS': 'LEER',
    'LEEN': 'LEER',
    'LEIA': 'LEER',
    'LEIAS': 'LEER',
    'LEIAMOS': 'LEER',
    'LEIAN': 'LEER',
    'LEI': 'LEER',
    'LEYO': 'LEER',
    'LEYERON': 'LEER',
    'LEYENDO': 'LEER',
    'LEIDO': 'LEER',
  };

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
    'VELOCIDAD': 'RAPIDO',
    'VELOZ': 'RÁPIDO',
    'PRONTO': 'RÁPIDO',
    'FINALIZAR': 'TERMINAR',
    'CONCLUIR': 'TERMINAR',
    'INICIAR': 'EMPEZAR',
    'RETORNAR': 'REGRESAR',
    // Deportes
    'BAKET': 'BÁSQUETBOL',
    'BASKET': 'BÁSQUETBOL',
    'BASKETBOL': 'BÁSQUETBOL',
    'BALONCESTO': 'BÁSQUETBOL',
    'BASQUETBOL': 'BÁSQUETBOL',
    'BASQUET': 'BÁSQUETBOL',
    // Pronombres personales (formas átonas -> seña base)
    'ME': 'YO',
    'MI': 'YO',
    'TE': 'TU',
    'TI': 'TU',
    'LE': 'EL',
    // Intensificadores y adverbios comunes
    'MUY': 'MUCHO',
    'MUCHISIMO': 'MUCHO',
    'BASTANTE': 'MUCHO',
    'DEMASIADO': 'MUCHO',
    'POQUITO': 'POCO',
    'AQUI': 'AQU Í',
    'DESPACITO': 'DESPACIO',
    'LENTAMENTE': 'DESPACIO',
    'RAPIDAMENTE': 'RÁPIDO',
    'LUEGO': 'DESPUÉS',
    // Expresiones conversacionales cotidianas
    'CHAO': 'ADIÓS',
    'HELLO': 'HOLA',
    'BYE': 'ADIÓS',
    'PORFA': 'POR FAVOR',
    'PLEASE': 'POR FAVOR',
    'OK': 'BIEN',
    'VALE': 'BIEN',
    'EXCELENTE': 'BIEN',
    'GENIAL': 'BIEN',
    'PERFECTO': 'BIEN',
    // Locuciones adversativas sin seña propia -> equivalente conceptual
    'SIN EMBARGO': 'PERO',
    'NO OBSTANTE': 'PERO',
    'A PESAR DE': 'PERO',
    'AUNQUE': 'PERO',
    // Verbos adicionales con correspondencia conceptual en LSRD
    'COCINAR': 'COCINA',
    'COCINO': 'COCINA',
    'COCINAS': 'COCINA',
    'COCINANDO': 'COCINA',
    'VISITAR': 'VISITA',
    'VISITO': 'VISITA',
    'VISITAS': 'VISITA',
    'VISITANDO': 'VISITA',
    'GANAR': 'GANANCIA',
    'GANO': 'GANANCIA',
    'GANAS': 'GANANCIA',
    'GANANDO': 'GANANCIA',
    'DEFENDER': 'DEFENSA',
    'DUDAR': 'DUDA',
    'DUDA': 'DUDA',
    'PREFERIR': 'PREFERIDO, DA',
    'COMPRENDER': 'ENTENDER',
    'SEGUIR': 'CONTINUAR',
    'SIGO': 'CONTINUAR',
    'SIGUES': 'CONTINUAR',
    'SIGUE': 'CONTINUAR',
    'SIGUEN': 'CONTINUAR',
    'SIGUIENDO': 'CONTINUAR',
    'TOMAR': 'BEBER',
  };

  /// Locuciones multi-palabra que deben evaluarse como bloque antes de filtrar stop words.
  /// Mapea la locución normalizada a la seña objetivo.
  static const Map<String, String> _multiWordPhrases = {
    'SIN EMBARGO': 'PERO',
    'NO OBSTANTE': 'PERO',
    'A PESAR DE': 'PERO',
    'SIN DUDA': 'SEGURO',
    'DE REPENTE': 'REPENTE',
    'DE VERDAD': 'VERDAD',
    'POR FAVOR': 'POR FAVOR',
    'DE NADA': 'DE NADA',
    'BUENOS DIAS': 'BUENOS DÍAS',
    'BUENAS TARDES': 'BUENAS TARDES',
    'BUENAS NOCHES': 'BUENAS NOCHES',
    'MUCHAS GRACIAS': 'MUCHAS GRACIAS',
  };

  /// Diccionario de resolución contextual de homónimos.
  static const Map<String, List<Map<String, dynamic>>> _contextualHomonyms = {
    'BANCO': [
      {
        'keywords': ['DINERO', 'SACAR', 'COBRAR', 'PAGAR', 'CUENTA', 'CHEQUE', 'EFECTIVO', 'AHORRAR'],
        'sign': 'BANCO (FINANCIERO)'
      },
      {
        'keywords': ['SENTAR', 'SENTARSE', 'ASIENTO', 'PARQUE', 'PLAZA', 'SILLA', 'CANSADO', 'DESCANSAR'],
        'sign': 'BANCO'
      }
    ]
  };

  static const List<String> _cliticSuffixes = [
    'MELO', 'SELO', 'TELO', 'NOSLO',
    'ME', 'TE', 'SE', 'NOS', 'OS', 'LE', 'LES', 'LO', 'LA', 'LOS', 'LAS',
  ];

  static const List<_SuffixRule> _regularSuffixRules = [
    _SuffixRule('ARIAMOS', ['AR']),
    _SuffixRule('ERIAMOS', ['ER']),
    _SuffixRule('IRIAMOS', ['IR']),
    _SuffixRule('ASEMOS', ['AR']),
    _SuffixRule('AREMOS', ['AR']),
    _SuffixRule('EREMOS', ['ER']),
    _SuffixRule('IREMOS', ['IR']),
    _SuffixRule('ABAMOS', ['AR']),
    _SuffixRule('IAMOS', ['ER', 'IR']),
    _SuffixRule('IERON', ['ER', 'IR']),
    _SuffixRule('IERAN', ['ER', 'IR']),
    _SuffixRule('IERAS', ['ER', 'IR']),
    _SuffixRule('IESEN', ['ER', 'IR']),
    _SuffixRule('IESES', ['ER', 'IR']),
    _SuffixRule('IENDO', ['ER', 'IR']),
    _SuffixRule('ARIAN', ['AR']),
    _SuffixRule('ARIAS', ['AR']),
    _SuffixRule('ERIAN', ['ER']),
    _SuffixRule('ERIAS', ['ER']),
    _SuffixRule('IRIAN', ['IR']),
    _SuffixRule('IRIAS', ['IR']),
    _SuffixRule('ASTEIS', ['AR']),
    _SuffixRule('ISTEIS', ['ER', 'IR']),
    _SuffixRule('ARAN', ['AR']),
    _SuffixRule('ARAS', ['AR']),
    _SuffixRule('ERAN', ['ER']),
    _SuffixRule('ERAS', ['ER']),
    _SuffixRule('IRAN', ['IR']),
    _SuffixRule('IRAS', ['IR']),
    _SuffixRule('ANDO', ['AR']),
    _SuffixRule('ARON', ['AR']),
    _SuffixRule('ABAN', ['AR']),
    _SuffixRule('ABAS', ['AR']),
    _SuffixRule('ABAIS', ['AR']),
    _SuffixRule('ARIA', ['AR']),
    _SuffixRule('ERIA', ['ER']),
    _SuffixRule('IRIA', ['IR']),
    _SuffixRule('ADOS', ['AR']),
    _SuffixRule('ADAS', ['AR']),
    _SuffixRule('IDOS', ['ER', 'IR']),
    _SuffixRule('IDAS', ['ER', 'IR']),
    _SuffixRule('AMOS', ['AR']),
    _SuffixRule('IMOS', ['IR']),
    _SuffixRule('EMOS', ['AR', 'ER']),
    _SuffixRule('ASTE', ['AR']),
    _SuffixRule('ISTE', ['ER', 'IR']),
    _SuffixRule('ABA', ['AR']),
    _SuffixRule('ADO', ['AR']),
    _SuffixRule('ADA', ['AR']),
    _SuffixRule('IDO', ['ER', 'IR']),
    _SuffixRule('IDA', ['ER', 'IR']),
    _SuffixRule('IAN', ['ER', 'IR']),
    _SuffixRule('IAS', ['ER', 'IR']),
    _SuffixRule('IA', ['ER', 'IR']),
    _SuffixRule('ARA', ['AR']),
    _SuffixRule('ASE', ['AR']),
    _SuffixRule('ARE', ['AR']),
    _SuffixRule('ERA', ['ER']),
    _SuffixRule('ESE', ['ER']),
    _SuffixRule('ERE', ['ER']),
    _SuffixRule('IRA', ['IR']),
    _SuffixRule('IRE', ['IR']),
    _SuffixRule('AIS', ['AR']),
    _SuffixRule('EIS', ['ER']),
    _SuffixRule('AN', ['AR']),
    _SuffixRule('EN', ['ER', 'AR']),
    _SuffixRule('AS', ['AR']),
    _SuffixRule('ES', ['ER', 'IR']),
    _SuffixRule('IO', ['ER', 'IR']),
    _SuffixRule('O', ['AR', 'ER', 'IR']),
    _SuffixRule('A', ['AR', 'ER', 'IR']),
    _SuffixRule('E', ['AR', 'ER', 'IR']),
    _SuffixRule('I', ['ER', 'IR']),
  ];

  /// Lematiza un verbo regular en español probando desinencias morfológicas y enclíticos.
  MockSignEntry? _lemmatizeRegularVerb(String word) {
    if (_normalizedIndex == null) return null;
    final w = _normalize(word);
    if (w.length < 3) return null;

    // 1. Probar quitar pronombres clíticos (ej. AYÚDAME -> AYUDA -> AYUDAR)
    for (final clitic in _cliticSuffixes) {
      if (w.endsWith(clitic) && w.length > clitic.length + 2) {
        final base = w.substring(0, w.length - clitic.length);
        if (_normalizedIndex!.containsKey(base)) {
          return _normalizedIndex![base];
        }
        final baseLemmatized = _lemmatizeRegularVerb(base);
        if (baseLemmatized != null) {
          return baseLemmatized;
        }
      }
    }

    // 2. Probar reglas morfológicas de conjugación regular
    for (final rule in _regularSuffixRules) {
      if (w.endsWith(rule.suffix)) {
        final stem = w.substring(0, w.length - rule.suffix.length);
        if (stem.length >= 2) {
          for (final ending in rule.candidateEndings) {
            final candidate = '$stem$ending';
            if (_normalizedIndex!.containsKey(candidate)) {
              return _normalizedIndex![candidate];
            }
            final reflexiveCandidate = '${candidate}SE';
            if (_normalizedIndex!.containsKey(reflexiveCandidate)) {
              return _normalizedIndex![reflexiveCandidate];
            }
          }
        }
      }
    }

    return null;
  }

  /// Determina si una palabra probablemente funciona como verbo en español.
  bool _isProbableVerb(String word) {
    final w = _normalize(word);
    if (_verbLemmas.containsKey(w)) return true;
    if (_normalizedIndex != null && _normalizedIndex!.containsKey(w)) {
      final entry = _normalizedIndex![w]!;
      final p = entry.palabra.toUpperCase();
      if (p.endsWith('AR') ||
          p.endsWith('ER') ||
          p.endsWith('IR') ||
          p.endsWith('SE') ||
          p.contains('CLIC') ||
          (entry.categoria?.toLowerCase() == 'verbos') ||
          entry.infoAdicional.toLowerCase().contains('verbo')) {
        return true;
      }
    }
    return _lemmatizeRegularVerb(w) != null;
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

    // 4. Resolver anomalías de espaciado donde una letra quedó separada (ej. "AJ Í" -> "AJI", "AQU Í" -> "AQUI")
    final spacedKeys = <String, MockSignEntry>{};
    for (final e in map.entries) {
      if (e.key.contains(' ')) {
        final condensed = e.key.replaceAll(' ', '');
        if (condensed == 'AJI' || condensed == 'AQUI') {
          spacedKeys[condensed] = e.value;
        }
      }
    }
    map.addAll(spacedKeys);

    // 5. Indexación universal de lemas verbales irregulares (ej. "QUERÍA" -> "QUERER")
    for (final vEntry in _verbLemmas.entries) {
      final conjugated = _normalize(vEntry.key);
      final lemma = _normalize(vEntry.value);
      final target = map[lemma] ?? map[_normalize(_commonSynonyms[lemma] ?? '')];
      if (target != null && !map.containsKey(conjugated)) {
        map[conjugated] = target;
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

  /// Búsqueda de una sola palabra o locución.
  /// Prioridad: coincidencia exacta > sinónimos > plurales > fonética > Levenshtein.
  ///
  /// Si [explicit] es `true`, solo se aceptan coincidencias exactas.
  Future<MockSignEntry?> findFlexible(String word, {bool explicit = false}) async {
    final all = await getAll();
    final w = _normalize(word);
    if (w.isEmpty) return null;

    // 1. Coincidencia exacta desde índice rápido optimizado
    if (_normalizedIndex != null && _normalizedIndex!.containsKey(w)) {
      return _normalizedIndex![w];
    }

    // 2. Coincidencia exacta recorriendo lista (cubre casos no indexados)
    for (final entry in all) {
      final norm = _normalize(entry.palabra);
      if (norm == w) return entry;
    }

    // 3. Fallback para plurales en español (ej. "AMIGOS" -> "AMIGO", "CASAS" -> "CASA")
    if (w.endsWith('ES') && w.length > 4) {
      final singular = w.substring(0, w.length - 2);
      if (_normalizedIndex != null && _normalizedIndex!.containsKey(singular)) {
        return _normalizedIndex![singular];
      }
    }
    if (w.endsWith('S') && w.length > 3) {
      final singular = w.substring(0, w.length - 1);
      if (_normalizedIndex != null && _normalizedIndex!.containsKey(singular)) {
        return _normalizedIndex![singular];
      }
    }

    // 4. Lematización de verbos regulares y formas con enclíticos (ej. "TRABAJABA" -> "TRABAJAR", "AYÚDAME" -> "AYUDAR")
    final lemmatizedVerb = _lemmatizeRegularVerb(w);
    if (lemmatizedVerb != null) {
      return lemmatizedVerb;
    }

    // Si el modo explícito está activado, no aplicar inferencias difusas
    if (explicit) {
      return null;
    }

    // 5. Búsqueda por similitud fonética en español (B/V, LL/Y, Z/S, H muda)
    if (_phoneticIndex != null) {
      final ph = _spanishPhonetic(w);
      if (_phoneticIndex!.containsKey(ph)) {
        return _phoneticIndex![ph];
      }
    }

    // 6. Búsqueda por tabla de sinónimos
    if (_commonSynonyms.containsKey(w)) {
      final synonymTarget = _normalizedIndex?[_normalize(_commonSynonyms[w]!)];
      if (synonymTarget != null) return synonymTarget;
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
  /// Aplica filtrado de stop words respetando locuciones multi-palabra (ej: "sin embargo"),
  /// y detecta pronombres por posicion/tilde (el vs el, tu vs tu).
  Future<TranslationResult> translatePhrase(String phrase, {bool explicit = false}) async {
    await getAll();

    // Paso 1: Limpiar signos de puntuacion preservando la caja original
    var cleanPhrase = phrase.trim();
    cleanPhrase = cleanPhrase.replaceAll(RegExp(r'[\u00bf?\u00a1!.,;:"()\[\]_]'), ' ');
    cleanPhrase = cleanPhrase.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleanPhrase.isEmpty) {
      return const TranslationResult(matchedSigns: [], notFoundWords: []);
    }

    final rawTokens = cleanPhrase.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final bool isMultiWord = rawTokens.length > 1;

    // Stop words a filtrar en frases multi-palabra (excluyendo numerales y palabras con seña directa como UN/UNO)
    const stopWords = {
      'LA', 'LOS', 'LAS', 'UNOS', 'UNAS',
      'DE', 'A', 'EN', 'POR', 'PARA', 'CON', 'SIN', 'AL', 'DEL',
      'QUE', 'Y', 'O', 'SU', 'SUS', 'PORQUE',
    };

    // Paso 2: Pre-escanear locuciones multi-palabra y frases del diccionario para protegerlas del filtro
    final tokens = <String>[];
    int ti = 0;
    while (ti < rawTokens.length) {
      // Probar 4-grama de frase en diccionario
      if (ti + 3 < rawTokens.length) {
        final quad = '${_normalize(rawTokens[ti])} ${_normalize(rawTokens[ti + 1])} ${_normalize(rawTokens[ti + 2])} ${_normalize(rawTokens[ti + 3])}';
        if (_normalizedIndex != null && _normalizedIndex!.containsKey(quad)) {
          tokens.add(quad);
          ti += 4;
          continue;
        }
      }
      // Probar trigrama de frase en diccionario o locución
      if (ti + 2 < rawTokens.length) {
        final triRaw = '${rawTokens[ti].toUpperCase()} ${rawTokens[ti + 1].toUpperCase()} ${rawTokens[ti + 2].toUpperCase()}';
        if (_multiWordPhrases.containsKey(triRaw)) {
          tokens.add(_normalize(_multiWordPhrases[triRaw]!));
          ti += 3;
          continue;
        }
        final tri = '${_normalize(rawTokens[ti])} ${_normalize(rawTokens[ti + 1])} ${_normalize(rawTokens[ti + 2])}';
        if (_normalizedIndex != null && _normalizedIndex!.containsKey(tri)) {
          tokens.add(tri);
          ti += 3;
          continue;
        }
      }
      // Probar bigrama de frase en diccionario o locución
      if (ti + 1 < rawTokens.length) {
        final biRaw = '${rawTokens[ti].toUpperCase()} ${rawTokens[ti + 1].toUpperCase()}';
        if (_multiWordPhrases.containsKey(biRaw)) {
          tokens.add(_normalize(_multiWordPhrases[biRaw]!));
          ti += 2;
          continue;
        }
        final bi = '${_normalize(rawTokens[ti])} ${_normalize(rawTokens[ti + 1])}';
        if (_normalizedIndex != null && _normalizedIndex!.containsKey(bi)) {
          tokens.add(bi);
          ti += 2;
          continue;
        }
      }

      // Token individual: aplicar reglas gramaticales
      final raw = rawTokens[ti];
      final upper = raw.toUpperCase();

      // "el" (artículo, sin tilde) -> saltar | "él" (pronombre, con tilde o precediendo verbo) -> conservar
      if (raw == 'el' || raw == 'El') {
        if (ti + 1 < rawTokens.length && _isProbableVerb(rawTokens[ti + 1])) {
          tokens.add('EL');
        }
        ti++;
        continue;
      }
      if (raw == 'él' || raw == 'Él') {
        tokens.add('EL');
        ti++;
        continue;
      }

      // "tu" (posesivo) -> saltar | "tú" (pronombre, con tilde o precediendo verbo) -> conservar
      if (raw == 'tu' || raw == 'Tu') {
        if (ti + 1 < rawTokens.length && _isProbableVerb(rawTokens[ti + 1])) {
          tokens.add('TU');
        }
        ti++;
        continue;
      }
      if (raw == 'tú' || raw == 'Tú') {
        tokens.add('TU');
        ti++;
        continue;
      }

      // En LSRD, los verbos copulativos (ser/estar) antes de predicados/adjetivos se omiten en frases compuestas
      const copulas = {
        'SOY', 'ERES', 'ES', 'SOMOS', 'SON', 'ERA', 'ERAS', 'ERAMOS', 'ERAN',
        'ESTOY', 'ESTAS', 'ESTA', 'ESTAMOS', 'ESTAN', 'ESTABA', 'ESTABAS', 'ESTABAMOS', 'ESTABAN',
        'ESTUVE', 'ESTUVO', 'ESTUVIMOS', 'ESTUVIERON'
      };
      if (isMultiWord && copulas.contains(upper)) {
        ti++;
        continue;
      }

      // Filtrar stop words en frases (no en búsqueda de palabra sola)
      if (isMultiWord && stopWords.contains(upper)) {
        ti++;
        continue;
      }

      tokens.add(_normalize(raw));
      ti++;
    }

    if (tokens.isEmpty) {
      return const TranslationResult(matchedSigns: [], notFoundWords: []);
    }

    // Paso 3: Traducir tokens con resolucion de homonimos contextual
    final List<MockSignEntry> matched = [];
    final List<String> notFound = [];
    final List<String> spelled = [];

    int i = 0;
    while (i < tokens.length) {
      // Probar trigrama
      if (i + 2 < tokens.length) {
        final triGram = '${tokens[i]} ${tokens[i + 1]} ${tokens[i + 2]}';
        final sign = await findFlexible(triGram, explicit: explicit);
        if (sign != null) {
          matched.add(sign);
          i += 3;
          continue;
        }
      }

      // Probar bigrama
      if (i + 1 < tokens.length) {
        final biGram = '${tokens[i]} ${tokens[i + 1]}';
        final sign = await findFlexible(biGram, explicit: explicit);
        if (sign != null) {
          matched.add(sign);
          i += 2;
          continue;
        }
      }

      // Unigrama con resolucion de homonimos por contexto
      String wordToSearch = tokens[i];
      if (_contextualHomonyms.containsKey(wordToSearch)) {
        final contexts = _contextualHomonyms[wordToSearch]!;
        outer:
        for (final contextDef in contexts) {
          final keywords = (contextDef['keywords'] as List).cast<String>();
          for (final cw in keywords) {
            if (tokens.contains(_normalize(cw))) {
              wordToSearch = _normalize(contextDef['sign'] as String);
              break outer;
            }
          }
        }
      }

      final sign = await findFlexible(wordToSearch, explicit: explicit);
      if (sign != null) {
        matched.add(sign);
      } else {
        // Fallback: deletreo dactilologico
        final letterSigns = <MockSignEntry>[];
        bool allLettersFound = true;

        for (int charIdx = 0; charIdx < wordToSearch.length; charIdx++) {
          final ch = wordToSearch[charIdx];
          final letterSign = getLetterSign(ch);
          if (letterSign != null) {
            letterSigns.add(
              MockSignEntry(
                id: letterSign.id,
                palabra: '$ch ($wordToSearch)',
                descripcion: 'Deletreo de "$wordToSearch": Letra $ch',
                gesto: letterSign.gesto.isNotEmpty
                    ? letterSign.gesto
                    : 'Configuracion manual de la letra $ch',
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
          spelled.add(wordToSearch);
          if (!allLettersFound) notFound.add(wordToSearch);
        } else {
          notFound.add(wordToSearch);
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
