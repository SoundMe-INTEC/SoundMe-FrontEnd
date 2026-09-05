import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockSignEntry Model Tests', () {
    test('parses matrix JSON format correctly', () {
      final json = {
        'palabra_clave': 'A',
        'archivo_matriz': 'matriz_a_01.webp',
        'coordenadas': {
          'x': 0,
          'y': 0,
          'width': 200,
          'height': 200,
        },
        'descripcion': 'La mano se cierra con la palma hacia afuera',
        'gesto_facial': 'Neutral',
        'categoria': 'Educación',
      };

      final entry = MockSignEntry.fromJson(json, 1);

      expect(entry.id, 1);
      expect(entry.palabra, 'A');
      expect(entry.archivoMatriz, 'matriz_a_01.webp');
      expect(entry.coordenadas, const Rect.fromLTWH(0, 0, 200, 200));
      expect(entry.isMatrixSign, isTrue);
      expect(entry.seccion, 'A');
      expect(entry.gestoFacial, 'Neutral');
      expect(entry.categoria, 'Educación');
    });

    test('parses legacy JSON format correctly', () {
      final json = {
        'id': 10,
        'palabra': 'HOLA',
        'descripcion': 'Saludo formal',
        'gesto': 'Mano levantada',
        'imagen_asset': 'assets/images/mockup/senia_0010.png',
        'seccion': 'H',
        'info_adicional': 'Interjección',
      };

      final entry = MockSignEntry.fromJson(json);

      expect(entry.id, 10);
      expect(entry.palabra, 'HOLA');
      expect(entry.isMatrixSign, isFalse);
      expect(entry.imagenAsset, 'assets/images/mockup/senia_0010.png');
      expect(entry.seccion, 'H');
    });
  });

  group('MockupDataService Functional Tests', () {
    late MockupDataService service;

    setUp(() {
      service = MockupDataService();
    });

    test('getAll loads the full dictionary (2427 entries)', () async {
      final all = await service.getAll();
      expect(all.length, greaterThanOrEqualTo(2400));
      expect(all.first.isMatrixSign, isTrue);
    });

    test('findFlexible matches exact, accents and plurals', () async {
      final hola = await service.findFlexible('HOLA');
      expect(hola, isNotNull);
      expect(hola!.palabra, 'HOLA');

      final buenosDias = await service.findFlexible('buenos dias');
      expect(buenosDias, isNotNull);
      expect(buenosDias!.palabra, contains('BUENOS D'));

      final pluralAmigos = await service.findFlexible('amigos');
      expect(pluralAmigos, isNotNull);
      expect(pluralAmigos!.palabra, contains('AMIGO'));
    });

    test('translatePhrase decomposes sentences with compound locutions', () async {
      final result = await service.translatePhrase('HOLA CÓMO ESTÁS');
      expect(result.matchedSigns, isNotEmpty);
      expect(result.matchedSigns.length, 2);
      expect(result.matchedSigns[0].palabra, 'HOLA');
      expect(result.matchedSigns[1].palabra, contains('CÓMO ESTÁS'));

      final result2 = await service.translatePhrase('GRACIAS POR TU AYUDA');
      expect(result2.matchedSigns, isNotEmpty);
      final words = result2.matchedSigns.map((e) => e.palabra).toList();
      expect(words, contains('GRACIAS'));
      expect(words, contains('AYUDA'));
    });

    test('translates unknown words into a succession of letter signs (fingerspelling)', () async {
      final result = await service.translatePhrase('CARLOS');
      expect(result.matchedSigns.length, 6);
      expect(result.spelledWords, contains('CARLOS'));
      expect(result.matchedSigns[0].palabra, 'C (CARLOS)');
      expect(result.matchedSigns[1].palabra, 'A (CARLOS)');
      expect(result.matchedSigns[2].palabra, 'R (CARLOS)');
      expect(result.matchedSigns[3].palabra, 'L (CARLOS)');
      expect(result.matchedSigns[4].palabra, 'O (CARLOS)');
      expect(result.matchedSigns[5].palabra, 'S (CARLOS)');
      expect(result.matchedSigns.every((s) => s.isMatrixSign), isTrue);

      final mixed = await service.translatePhrase('HOLA CARLOS');
      expect(mixed.matchedSigns.length, 7); // HOLA + 6 letters
      expect(mixed.matchedSigns[0].palabra, 'HOLA');
      expect(mixed.spelledWords, contains('CARLOS'));
    });

    test('category methods return populated lists', () async {
      final greetings = await service.getGreetings();
      expect(greetings, isNotEmpty);

      final common = await service.getCommonPhrases();
      expect(common, isNotEmpty);

      final emergencies = await service.getEmergencies();
      expect(emergencies, isNotEmpty);
    });
  });
}
