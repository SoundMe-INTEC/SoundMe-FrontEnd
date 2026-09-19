import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';
import 'package:soundme_frontend/features/options/presentation/screens/options_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockupDataService service;

  setUp(() {
    service = MockupDataService();
  });

  group('Pruebas de Configuración: Modo de Traducción Explícita vs Flexible', () {
    test('1. Modo Explícito (explicit: true) restringe estrictamente a coincidencias exactas', () async {
      // 1.1 Coincidencia exacta funciona normalmente
      final signHola = await service.findFlexible('HOLA', explicit: true);
      expect(signHola, isNotNull);
      expect(signHola!.palabra, 'HOLA');

      // 1.2 Palabras con errores o sinónimos NO se adivinan en modo explícito
      final signAvogado = await service.findFlexible('avogado', explicit: true);
      expect(signAvogado, isNull, reason: '"avogado" no debe corregirse en modo explícito');

      final signHayar = await service.findFlexible('hayar', explicit: true);
      expect(signHayar, isNull, reason: '"hayar" no debe corregirse ni buscar sinónimos en modo explícito');

      final signSapato = await service.findFlexible('sapato', explicit: true);
      expect(signSapato, isNull, reason: '"sapato" no debe corregirse a zapato en modo explícito');

      // 1.3 Frase completa en modo explícito: la palabra mal escrita se deletrea dactilológicamente
      final translation = await service.translatePhrase('HOLA AVOGADO', explicit: true);
      expect(translation.matchedSigns.isNotEmpty, isTrue);
      // Primera seña: "HOLA"
      expect(translation.matchedSigns.first.palabra, 'HOLA');
      // La palabra "avogado" debe haberse deletreado letra por letra
      expect(translation.spelledWords, contains('AVOGADO'));
    });

    test('2. Modo Flexible (explicit: false) autocorrige errores fonéticos frecuentes en español', () async {
      // 2.1 Corrección B <-> V: "avogado" -> "ABOGADO,DA", "varato" -> "BARATO, TA"
      final signAbogado = await service.findFlexible('avogado', explicit: false);
      expect(signAbogado, isNotNull);
      expect(signAbogado!.palabra, contains('ABOGADO'));

      final signBarato = await service.findFlexible('varato', explicit: false);
      expect(signBarato, isNotNull);
      expect(signBarato!.palabra, contains('BARATO'));

      // 2.2 Corrección C/S/Z (seseo): "sapato" -> "ZAPATO"
      final signZapato = await service.findFlexible('sapato', explicit: false);
      expect(signZapato, isNotNull);
      expect(signZapato!.palabra, 'ZAPATO');

      // 2.3 Omisión de H muda: "ermano" -> "HERMANO"
      final signHermano = await service.findFlexible('ermano', explicit: false);
      expect(signHermano, isNotNull);
      expect(signHermano!.palabra, contains('HERMANO'));
    });

    test('3. Modo Flexible (explicit: false) resuelve sinónimos y errores combinados (hayar/hallar -> ENCONTRAR)', () async {
      // 3.1 "hallar" -> mapea a "ENCONTRAR"
      final signHallar = await service.findFlexible('hallar', explicit: false);
      expect(signHallar, isNotNull);
      expect(signHallar!.palabra, 'ENCONTRAR');

      // 3.2 "hayar" (con Y en lugar de LL) -> mapea a "ENCONTRAR"
      final signHayar = await service.findFlexible('hayar', explicit: false);
      expect(signHayar, isNotNull);
      expect(signHayar!.palabra, 'ENCONTRAR');

      // 3.3 "auto" o "vehiculo" -> mapea a "CARRO"
      final signAuto = await service.findFlexible('auto', explicit: false);
      expect(signAuto, isNotNull);
      expect(signAuto!.palabra, contains('CARRO'));
    });

    test('4. Modo Flexible (explicit: false) resuelve erratas de teclado por distancia Levenshtein', () async {
      // "abogdo" (falta la segunda 'a') -> distancia 1 de "ABOGADO"
      final signAbogdo = await service.findFlexible('abogdo', explicit: false);
      expect(signAbogdo, isNotNull);
      expect(signAbogdo!.palabra, contains('ABOGADO'));
    });

    test('5. Traducción de frase completa en Modo Flexible aplica autocorrecciones de forma integrada', () async {
      final res = await service.translatePhrase('HOLA AVOGADO', explicit: false);
      expect(res.matchedSigns.length, 2);
      expect(res.matchedSigns[0].palabra, 'HOLA');
      expect(res.matchedSigns[1].palabra, contains('ABOGADO'));
      expect(res.spelledWords, isEmpty);
    });

    testWidgets('6. OptionsScreen muestra switch de Traducción Explícita y permite alternar estado', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OptionsScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verificar que el título y switch están en pantalla
      expect(find.text('Traducción Explícita'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Inicialmente en modo flexible (false)
      final initialSwitch = tester.widget<Switch>(find.byType(Switch));
      expect(initialSwitch.value, isFalse);
      expect(find.textContaining('Modo flexible activo'), findsOneWidget);

      // Tocar el switch para activar modo explícito
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Ahora el switch debe estar en true y reflejar modo estricto
      final activeSwitch = tester.widget<Switch>(find.byType(Switch));
      expect(activeSwitch.value, isTrue);
      expect(find.textContaining('Modo estricto activo'), findsOneWidget);
    });
  });
}
