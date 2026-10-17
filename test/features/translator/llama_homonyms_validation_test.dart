import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';
import 'package:soundme_frontend/features/main_layout/presentation/screens/main_layout_screen.dart';
import 'package:soundme_frontend/features/options/domain/models/translation_item.dart';
import 'package:soundme_frontend/core/widgets/sign_image_widget.dart';
import 'package:soundme_frontend/features/options/presentation/screens/translation_list_screen.dart';
import 'package:soundme_frontend/features/translator/presentation/screens/translator_screen.dart';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockupDataService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    const MethodChannel channel = MethodChannel(
      'plugin.csdcorp.com/speech_to_text',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'initialize') {
            return true;
          } else if (methodCall.method == 'listen') {
            return true;
          } else if (methodCall.method == 'stop') {
            return true;
          } else if (methodCall.method == 'cancel') {
            return true;
          } else if (methodCall.method == 'hasPermission') {
            return true;
          }
          return null;
        });

    service = MockupDataService();
    await service.getAll();
  });

  group('Validación de Frases: Los 3 tipos de LLAMA (Animal, Fuego, Verbo Llamar)', () {
    test('1. LLAMA tipo ANIMAL (camélido andino) en diversas construcciones', () async {
      final phrasesAnimal = [
        'hoy alimenté a una llama en el campo',
        'hoy me monté en una llama',
        'la llama come pasto',
        'vi una llama en la montaña',
      ];

      for (final phrase in phrasesAnimal) {
        final result = await service.translatePhrase(phrase);
        expect(
          result.matchedSigns.any((s) => s.palabra == 'LLAMA (ANIMAL)'),
          isTrue,
          reason: 'La frase "$phrase" debió resolver a LLAMA (ANIMAL)',
        );
        expect(
          result.matchedSigns.any((s) => s.palabra == 'LLAMAR'),
          isFalse,
          reason: 'La frase "$phrase" NO debió resolver al verbo LLAMAR',
        );
        expect(
          result.matchedSigns.any((s) => s.palabra == 'FUEGO'),
          isFalse,
          reason: 'La frase "$phrase" NO debió resolver a FUEGO',
        );
      }
    });

    test('2. LLAMA tipo FUEGO (llama de vela / flama / calor) en diversas construcciones', () async {
      final phrasesFuego = [
        'la llama del fuego',
        'la llama de la vela quema con fuerza',
        'el calor de la llama',
      ];

      for (final phrase in phrasesFuego) {
        final result = await service.translatePhrase(phrase);
        expect(
          result.matchedSigns.any((s) => s.palabra.contains('FUEGO')),
          isTrue,
          reason: 'La frase "$phrase" debió resolver a FUEGO',
        );
        expect(
          result.matchedSigns.any((s) => s.palabra == 'LLAMA (ANIMAL)'),
          isFalse,
          reason: 'La frase "$phrase" NO debió resolver a animal',
        );
      }
    });

    test('3. LLAMA tipo VERBO LLAMAR (comunicación / telefonear / avisar)', () async {
      final phrasesVerbo = [
        'ella me llama por teléfono',
        'mi madre me llama',
        'llama a una ambulancia por favor',
        'ayer la llamé',
      ];

      for (final phrase in phrasesVerbo) {
        final result = await service.translatePhrase(phrase);
        expect(
          result.matchedSigns.any((s) => s.palabra.contains('LLAMAR')),
          isTrue,
          reason: 'La frase "$phrase" debió resolver al verbo LLAMAR',
        );
        expect(
          result.matchedSigns.any((s) => s.palabra == 'LLAMA (ANIMAL)'),
          isFalse,
          reason: 'La frase "$phrase" NO debió resolver a LLAMA (ANIMAL)',
        );
        expect(
          result.matchedSigns.any((s) => s.palabra == 'FUEGO'),
          isFalse,
          reason: 'La frase "$phrase" NO debió resolver a FUEGO',
        );
      }
    });

    test('4. Homónimo SIENTO: resolución contextual entre SENTIR (emoción) y SENTARSE (asiento)', () async {
      final resEmocion = await service.translatePhrase('yo me siento feliz');
      final signsEmocion = resEmocion.matchedSigns.map((s) => s.palabra).toList();
      print('TRADUCCIÓN EMOCIÓN: "yo me siento feliz" -> $signsEmocion');
      expect(signsEmocion, ['YO', 'SENTIR', 'FELIZ']);

      final resAsiento = await service.translatePhrase('yo me siento en la silla');
      final signsAsiento = resAsiento.matchedSigns.map((s) => s.palabra).toList();
      print('TRADUCCIÓN ASIENTO: "yo me siento en la silla" -> $signsAsiento');
      expect(signsAsiento, ['YO', 'SENTARSE', 'SILLA']);
    });
  });

  group('Historial a Traductor: Montaje y Reproducción', () {
    testWidgets('TranslatorScreen monta initialPhrase y ejecuta traducción automáticamente', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockupDataServiceProvider.overrideWithValue(service),
          ],
          child: const MaterialApp(
            home: TranslatorScreen(
              initialPhrase: 'hola cómo estás',
            ),
          ),
        ),
      );

      // El campo de texto debe tener la frase precargada
      expect(find.text('hola cómo estás'), findsOneWidget);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TranslatorScreen), findsOneWidget);
    });

    testWidgets('Tocar un elemento en TranslationListScreen de Historial abre el traductor con la frase', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final historyItems = [
        TranslationItem(
          id: '1',
          text: 'hoy alimenté a una llama en el campo',
          imageUrl: '',
          signsInOrder: const ['HOY', 'ALIMENTO', 'LLAMA (ANIMAL)', 'CAMPO'],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mockupDataServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            home: TranslationListScreen(
              title: 'Historial',
              items: historyItems,
            ),
          ),
        ),
      );

      expect(find.text('hoy alimenté a una llama en el campo'), findsOneWidget);
      expect(find.text('Toca para reproducir en el traductor'), findsOneWidget);

      // Tocar la tarjeta del historial
      await tester.tap(find.text('hoy alimenté a una llama en el campo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Debe haber navegado a MainLayoutScreen en la pestaña del Traductor con el texto montado
      expect(find.byType(TranslatorScreen), findsOneWidget);
      expect(find.text('hoy alimenté a una llama en el campo'), findsOneWidget);
    });
  });
}
