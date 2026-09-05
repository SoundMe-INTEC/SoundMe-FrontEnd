import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/features/translator/presentation/screens/translator_screen.dart';

void main() {
  setUp(() {
    const MethodChannel channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
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

  testWidgets('QA Validation: TranslatorScreen renders and mic button is clickable', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TranslatorScreen(),
        ),
      ),
    );

    // Initial render check
    expect(find.byType(TranslatorScreen), findsOneWidget);
    
    // Find the mic button
    final micIcon = find.byIcon(Icons.mic);
    expect(micIcon, findsOneWidget);

    // Tap the mic button
    await tester.tap(micIcon);
    await tester.pump();

    // After tapping, it should initialize and turn red / show mic_off
    // Use pump with duration rather than pumpAndSettle because _pulseController.repeat() animates indefinitely
    await tester.pump(const Duration(milliseconds: 300));

    // The icon should change to mic_off.
    expect(find.byIcon(Icons.mic_off), findsOneWidget);

    // Verify text field exists
    expect(find.byType(TextField), findsOneWidget);

    // Wait for the stop timer to clear out (since speech_to_text creates a timer on stop)
    // We unmount the widget first to trigger dispose(), then pump time forward.
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 3));
  });
}
