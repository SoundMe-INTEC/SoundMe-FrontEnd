import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/core/widgets/sign_image_widget.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LSRD SVG Integration & Regression Test Suite', () {
    late MockupDataService service;

    setUp(() {
      service = MockupDataService(
        defaultDictionaryPath: 'assets/matrices/diccionario_matrices_svg.json',
      );
    });

    test('1. Diccionario completo carga 2,427 señas vectoriales SVG', () async {
      final entries = await service.getAll();
      expect(entries.length, 2427, reason: 'El diccionario debe contener exactamente 2,427 señas');

      int svgCount = 0;
      for (final e in entries) {
        if (e.isSvg) {
          svgCount++;
          expect(e.svgAsset, isNotNull);
          expect(e.svgAsset, startsWith('assets/senias_svg/'));
          expect(e.svgAsset, endsWith('.svg'));
        }
      }

      expect(svgCount, 2427, reason: 'El 100% de las señas deben tener asset vectorial SVG asociado');
    });

    test('2. Verificación de cobertura completa por secciones canónicas', () async {
      final entries = await service.getAll();
      final canonicalSections = [
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
        'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
        'EXTRAS', 'LOCUCIONES', 'NOMBRES_HISTORICOS', 'PREGUNTAS', 'PROVINCIAS'
      ];

      final Map<String, int> countsBySection = {};
      for (final e in entries) {
        final sec = e.seccion.toUpperCase().trim();
        countsBySection[sec] = (countsBySection[sec] ?? 0) + 1;
      }

      for (final sec in canonicalSections) {
        expect(countsBySection.containsKey(sec), isTrue, reason: 'La sección $sec debe estar presente');
        expect(countsBySection[sec]!, greaterThan(0), reason: 'La sección $sec debe tener al menos 1 seña');
      }

      // Validar casos clave de control
      expect(countsBySection['A']!, greaterThanOrEqualTo(250));
      expect(countsBySection['B']!, greaterThanOrEqualTo(100));
      expect(countsBySection['C']!, greaterThanOrEqualTo(300));
      expect(countsBySection['PROVINCIAS']!, greaterThanOrEqualTo(30));
    });

    test('3. Búsqueda y traducción generan señas vectoriales SVG puras', () async {
      // Prueba de búsqueda unitaria
      final senaHola = await service.findFlexible('HOLA');
      expect(senaHola, isNotNull);
      expect(senaHola!.isSvg, isTrue);
      expect(senaHola.svgAsset, contains('.svg'));

      // Frase compuesta
      final resCompuesta = await service.translatePhrase('HOLA BUENOS DÍAS AMIGOS');
      expect(resCompuesta.matchedSigns, isNotEmpty);
      for (final s in resCompuesta.matchedSigns) {
        expect(s.isSvg, isTrue, reason: 'Cada seña en la traducción debe ser vectorial SVG');
      }

      // Deletreo dactilológico
      final resDact = await service.translatePhrase('XYZ');
      expect(resDact.matchedSigns.length, 3);
      for (final s in resDact.matchedSigns) {
        expect(s.isSvg, isTrue);
        expect(s.svgAsset, contains('.svg'));
      }
    });

    testWidgets('4. SignImage renderiza SvgPicture sin excepciones visuales ni errores de parser', (tester) async {
      late MockSignEntry sampleEntry;
      await tester.runAsync(() async {
        final entries = await service.getAll();
        sampleEntry = entries.firstWhere((e) => e.palabra == 'A');
      });

      final svgOnlyEntry = MockSignEntry(
        id: sampleEntry.id,
        palabra: sampleEntry.palabra,
        descripcion: sampleEntry.descripcion,
        gesto: sampleEntry.gesto,
        imagenAsset: sampleEntry.imagenAsset,
        seccion: sampleEntry.seccion,
        infoAdicional: sampleEntry.infoAdicional,
        svgAsset: sampleEntry.svgAsset,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SignImage(
                sign: svgOnlyEntry,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );

      // Verificar que el widget montó un SvgPicture
      expect(find.byType(SignImage), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(MatrixSignImage), findsNothing);
    });
  });
}
