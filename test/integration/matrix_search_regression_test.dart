import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/core/widgets/sign_image_widget.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockupDataService service;

  setUp(() {
    service = MockupDataService();
  });

  group('SoundMe - Suite de Regresión de Matrices de Imágenes y Búsqueda Semántica', () {
    test('1. Carga íntegra de 2,427 señas mapeadas a 114 Matrices WebP', () async {
      final signs = await service.getAll();

      // Total de señas en el diccionario oficial
      expect(signs.length, 2427);

      final matrices = <String>{};
      for (final s in signs) {
        expect(s.isMatrixSign, isTrue, reason: 'Seña ${s.palabra} debe ser tipo matriz');
        expect(s.archivoMatriz, isNotNull);
        expect(s.archivoMatriz!.endsWith('.webp'), isTrue);
        expect(s.coordenadas, isNotNull);
        expect(s.coordenadas!.width, 200.0);
        expect(s.coordenadas!.height, 200.0);
        matrices.add(s.archivoMatriz!);
      }

      // Exactamente 114 Sprite Sheets WebP
      expect(matrices.length, 114);
    });

    test('2. Resolución correcta de "UN" -> "UNO, UNA" y erradicación del falso positivo con "UN PLACER CONOCERTE"', () async {
      // 2.1 Búsqueda directa de la palabra aislada "UN"
      final signUn = await service.findFlexible('UN');
      expect(signUn, isNotNull);
      expect(signUn!.palabra, contains('UNO, UNA'),
          reason: '"UN" debe resolver a "UNO, UNA", jamás a "UN PLACER CONOCERTE"');

      // 2.2 Búsqueda de "UNO" y "UNA"
      final signUno = await service.findFlexible('UNO');
      expect(signUno, isNotNull);
      expect(signUno!.palabra, contains('UNO, UNA'));

      final signUna = await service.findFlexible('UNA');
      expect(signUna, isNotNull);
      expect(signUna!.palabra, contains('UNO, UNA'));

      // 2.3 Búsqueda de la frase compuesta completa "UN PLACER CONOCERTE"
      final signPlacer = await service.findFlexible('UN PLACER CONOCERTE');
      expect(signPlacer, isNotNull);
      expect(signPlacer!.palabra, 'UN PLACER CONOCERTE');

      // 2.4 Traducción de la frase aislada "UN"
      final translationUn = await service.translatePhrase('UN');
      expect(translationUn.matchedSigns.length, 1);
      expect(translationUn.matchedSigns.first.palabra, contains('UNO, UNA'));

      // 2.5 Traducción de "UN AMIGO": debe dar 2 señas ("UNO, UNA" + "AMIGO, GA")
      final translationUnAmigo = await service.translatePhrase('UN AMIGO');
      expect(translationUnAmigo.matchedSigns.length, 2);
      expect(translationUnAmigo.matchedSigns[0].palabra, contains('UNO, UNA'));
      expect(translationUnAmigo.matchedSigns[1].palabra, contains('AMIGO, GA'));

      // 2.6 Traducción de "UN PLACER CONOCERTE": debe dar exactamente 1 seña compuesta
      final translationPlacer = await service.translatePhrase('UN PLACER CONOCERTE');
      expect(translationPlacer.matchedSigns.length, 1);
      expect(translationPlacer.matchedSigns.first.palabra, 'UN PLACER CONOCERTE');
    });

    test('3. Flexión de género y sufijos en el diccionario ("AMIGA", "ABOGADA", "DOCTORA")', () async {
      // Masculino y femenino de AMIGO, GA
      final amigo = await service.findFlexible('AMIGO');
      final amiga = await service.findFlexible('AMIGA');
      expect(amigo, isNotNull);
      expect(amiga, isNotNull);
      expect(amigo!.id, amiga!.id);
      expect(amigo.palabra, contains('AMIGO, GA'));

      // ABOGADO, DA
      final abogado = await service.findFlexible('ABOGADO');
      final abogada = await service.findFlexible('ABOGADA');
      expect(abogado, isNotNull);
      expect(abogada, isNotNull);
      expect(abogado!.id, abogada!.id);

      // DOCTOR, RA
      final doctor = await service.findFlexible('DOCTOR');
      final doctora = await service.findFlexible('DOCTORA');
      expect(doctor, isNotNull);
      expect(doctora, isNotNull);
      expect(doctor!.id, doctora!.id);

      // MAESTRO, TRA
      final maestro = await service.findFlexible('MAESTRO');
      final maestra = await service.findFlexible('MAESTRA');
      expect(maestro, isNotNull);
      expect(maestra, isNotNull);
      expect(maestro!.id, maestra!.id);
    });

    test('4. Apócopes y sinónimos entre paréntesis ("BUEN", "PRIMER", "CANCELAR", "BAÑARSE")', () async {
      // Apócopes
      final buen = await service.findFlexible('BUEN');
      expect(buen, isNotNull);
      expect(buen!.palabra, contains('BUENO, NA'));

      final primer = await service.findFlexible('PRIMER');
      expect(primer, isNotNull);
      expect(primer!.palabra, contains('PRIMERO, RA'));

      // Sinónimo entre paréntesis: "CANCELAR" está en "ANULAR (CANCELAR)"
      final cancelar = await service.findFlexible('CANCELAR');
      expect(cancelar, isNotNull);
      expect(cancelar!.palabra, contains('ANULAR (CANCELAR)'));

      // Verbo reflexivo con sufijo "SE": "BAÑARSE" está en "BAÑAR, SE"
      final banarse = await service.findFlexible('BAÑARSE');
      expect(banarse, isNotNull);
      expect(banarse!.palabra, contains('BAÑAR, SE'));
    });

    test('5. Prevención de contaminación de prefijos ("POR" vs "POR FAVOR")', () async {
      final porFavor = await service.findFlexible('POR FAVOR');
      expect(porFavor, isNotNull);
      expect(porFavor!.palabra, 'POR FAVOR');

      // Traducir "POR EJEMPLO" debe emparejar la frase completa si existe
      final translationPorFavor = await service.translatePhrase('POR FAVOR');
      expect(translationPorFavor.matchedSigns.length, 1);
      expect(translationPorFavor.matchedSigns.first.palabra, 'POR FAVOR');
    });

    testWidgets('6. MatrixSignImage renderiza con aceleración GPU para matrices de imágenes', (tester) async {
      late MockSignEntry sign;
      await tester.runAsync(() async {
        final all = await service.getAll();
        sign = all.first;
      });

      expect(sign.isMatrixSign, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MatrixSignImage(
                matrixAsset: sign.archivoMatriz!,
                coordinates: sign.coordenadas!,
                width: 150,
                height: 150,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Debe instanciar MatrixSignImage y Transform
      expect(find.byType(MatrixSignImage), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
    });
  });
}
