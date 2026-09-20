import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/features/help/presentation/screens/help_faq_screen.dart';
import 'package:soundme_frontend/features/home/presentation/screens/home_screen.dart';
import 'package:soundme_frontend/features/options/presentation/screens/options_screen.dart';

void main() {
  Widget createHelpScreen({int initialTabIndex = 0}) {
    return ProviderScope(
      child: MaterialApp(
        home: HelpFaqScreen(initialTabIndex: initialTabIndex),
      ),
    );
  }

  testWidgets('HelpFaqScreen renders search bar, category chips, tabs, and guide cards', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createHelpScreen());
    await tester.pumpAndSettle();

    // Verify Header
    expect(find.text('Centro de Ayuda & FAQ'), findsOneWidget);

    // Verify Search Bar
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Buscar en la ayuda o preguntas frecuentes...'), findsOneWidget);

    // Verify Category Chips
    expect(find.widgetWithText(ChoiceChip, 'Todas'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Traductor y Voz'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Reproductor'), findsOneWidget);

    // Verify TabBar
    expect(find.text('Guía de Uso'), findsOneWidget);
    expect(find.text('Preguntas Frecuentes'), findsOneWidget);

    // Verify Guide content loaded
    expect(find.text('Traducción por Voz a Señas'), findsOneWidget);
    expect(find.text('Traducción por Texto y Sugerencias'), findsOneWidget);
  });

  testWidgets('HelpFaqScreen filters guide cards by search query', (tester) async {
    await tester.pumpWidget(createHelpScreen());
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'reproductor');
    await tester.pumpAndSettle();

    // Should match reproductor guide
    expect(find.text('Controles del Reproductor Multimedia'), findsOneWidget);
    // Should NOT match voice guide
    expect(find.text('Traducción por Voz a Señas'), findsNothing);

    // Clear search
    final clearButton = find.byIcon(Icons.clear);
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    // Guides restored
    expect(find.text('Traducción por Voz a Señas'), findsOneWidget);
  });

  testWidgets('HelpFaqScreen FAQ tab expands tile and shows answer', (tester) async {
    await tester.pumpWidget(createHelpScreen(initialTabIndex: 1));
    await tester.pumpAndSettle();

    // Should be on FAQ tab
    final questionText = find.text('¿Por qué el micrófono no me escucha o se detiene solo?');
    expect(questionText, findsOneWidget);

    // Tap to expand question
    await tester.tap(questionText);
    await tester.pumpAndSettle();

    // Verify answer is visible
    expect(find.textContaining('Verifica en Opciones > Notificaciones y Permisos'), findsOneWidget);
    expect(find.text('Verificar Permisos'), findsOneWidget);
  });

  testWidgets('OptionsScreen navigates to HelpFaqScreen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OptionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final helpOption = find.text('Ayuda y Preguntas Frecuentes');
    expect(helpOption, findsOneWidget);

    await tester.scrollUntilVisible(helpOption, 200);
    await tester.tap(helpOption);
    await tester.pumpAndSettle();

    expect(find.text('Centro de Ayuda & FAQ'), findsOneWidget);
  });
}
