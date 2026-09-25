import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/features/translator/presentation/screens/translator_screen.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
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
  });

  testWidgets(
    'QA Validation: TranslatorScreen renders and mic button is clickable',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: TranslatorScreen())),
      );

      final micButton = find.byKey(const Key('translator_mic_button'));
      expect(micButton, findsOneWidget);

      await tester.tap(micButton);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.mic), findsOneWidget);

      expect(find.byType(TextField), findsOneWidget);

      // Wait for the stop timer to clear out (since speech_to_text creates a timer on stop)
      // We unmount the widget first to trigger dispose(), then pump time forward.
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'QA Validation: TranslatorScreen help button opens quick guide sheet',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: TranslatorScreen())),
      );

      // Find the help button in the header
      final helpButton = find.byIcon(Icons.help_outline_rounded);
      expect(helpButton, findsWidgets);

      // Tap the header help button
      await tester.tap(helpButton.first);
      await tester.pumpAndSettle();

      // Verify bottom sheet title and content appeared
      expect(find.text('Guía Rápida del Traductor'), findsOneWidget);
      expect(find.text('Traducción por Voz'), findsOneWidget);
      expect(find.text('Traducción por Texto'), findsOneWidget);
      expect(find.text('Velocidad y Controles'), findsOneWidget);
      expect(find.text('Deletreo Dactilológico'), findsOneWidget);
      expect(find.text('Ver Guía Completa y FAQ'), findsOneWidget);

      // Close the sheet
      await tester.tap(find.text('Ver Guía Completa y FAQ'));
      await tester.pumpAndSettle();

      // Verifies navigation to full HelpFaqScreen
      expect(find.text('Centro de Ayuda & FAQ'), findsOneWidget);
    },
  );
}
