import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/core/widgets/sign_image_widget.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';
import 'package:soundme_frontend/features/translator/presentation/screens/translator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TranslatorScreen & SVG High Fidelity Rendering Tests', () {
    late MockupDataService service;

    setUp(() async {
      service = MockupDataService();
      await service.getAll(); // Precargar cache para ejecución síncrona en widget tests
    });

    test('1. translatePhrase entrega señas vectoriales SVG con rutas de assets válidas', () async {
      final res = await service.translatePhrase('HOLA');
      expect(res.matchedSigns, isNotEmpty);
      final holaSign = res.matchedSigns.first;
      expect(holaSign.palabra, 'HOLA');
      expect(holaSign.isSvg, isTrue);
      expect(holaSign.svgAsset, isNotNull);
      expect(holaSign.svgAsset, startsWith('assets/senias_svg/'));
      expect(holaSign.svgAsset, endsWith('.svg'));
    });

    testWidgets('2. SignImage renderiza SvgPicture individualmente con máxima nitidez y sin errores', (tester) async {
      final res = await service.translatePhrase('HOLA');
      final sign = res.matchedSigns.first;

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: SignImage(
                    sign: sign,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      });

      // Debe encontrar SignImage y SvgPicture montados en la vista
      expect(find.byType(SignImage), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      // No debe existir ningún MatrixSignImage
      expect(find.byType(MatrixSignImage), findsNothing);
    });

    testWidgets('3. TranslatorScreen renderiza buscador y traduce reactivamente al escribir', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mockupDataServiceProvider.overrideWithValue(service),
            ],
            child: const MaterialApp(
              home: TranslatorScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      // Estado inicial: mensaje de invitación a traducir
      expect(find.textContaining('para traducir'), findsOneWidget);

      // Simular escritura de 'HOLA' en el TextField
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'HOLA');
      await tester.pump(const Duration(milliseconds: 450)); // Esperar debounce de 380ms
      await tester.pump();

      // Debe haber renderizado la seña 'HOLA' y su SvgPicture
      expect(find.byType(SignImage), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('HOLA'), findsWidgets);

      // Limpiar texto
      await tester.enterText(textField, '');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Vuelve al estado inicial limpio sin errores
      expect(find.textContaining('para traducir'), findsOneWidget);
    });

    testWidgets('4. TranslatorScreen realiza deletreo dactilológico en SVG para nombres no indexados', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mockupDataServiceProvider.overrideWithValue(service),
            ],
            child: const MaterialApp(
              home: TranslatorScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'CARLOS');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();

      // CARLOS se deletrea dactilológicamente (C-A-R-L-O-S = 6 señas)
      expect(find.byType(SignImage), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.textContaining('deletreo: CARLOS'), findsOneWidget);
    });
  });
}
