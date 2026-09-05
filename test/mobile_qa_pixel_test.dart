import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/features/home/presentation/screens/home_screen.dart';
import 'package:soundme_frontend/features/home/presentation/screens/about_screen.dart';
import 'package:soundme_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:soundme_frontend/features/auth/presentation/screens/two_step_auth_screen.dart';
import 'package:soundme_frontend/features/translator/presentation/screens/translator_screen.dart';
import 'package:soundme_frontend/features/dictionary/presentation/dictionary_screen.dart';
import 'package:soundme_frontend/features/options/presentation/screens/options_screen.dart';
import 'package:soundme_frontend/features/options/presentation/screens/permissions_screen.dart';
import 'package:soundme_frontend/features/admin/presentation/screens/admin_home_screen.dart';
import 'package:soundme_frontend/features/main_layout/presentation/screens/main_layout_screen.dart';

import 'package:soundme_frontend/features/dictionary/data/mock_dictionary_repository.dart';

void main() {
  setUp(() {
    // Seed mock dictionary words to avoid loading indicator hang in tests
    MockDictionaryRepository.mockWords = [
      MockDictionaryWord(
        id: 1,
        palabra: 'Hola',
        descripcion: 'Saludo básico',
        gesto: 'Mano levantada',
        imagePaths: [],
      ),
    ];

    // Mock speech_to_text channel
    const MethodChannel channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'initialize') return true;
      if (methodCall.method == 'listen') return true;
      if (methodCall.method == 'stop') return true;
      if (methodCall.method == 'cancel') return true;
      if (methodCall.method == 'hasPermission') return true;
      return true;
    });

    // Mock permissions handler
    const MethodChannel permChannel = MethodChannel('flutter.baseflow.com/permissions/methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permChannel, (MethodCall methodCall) async {
      return 1; // PermissionStatus.granted
    });
  });

  // Helper to calculate relative luminance according to WCAG formula
  double relativeLuminance(Color color) {
    double transform(double c) {
      return (c <= 0.03928) ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
    }
    final r = transform(color.red / 255.0);
    final g = transform(color.green / 255.0);
    final b = transform(color.blue / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  // Helper to calculate contrast ratio according to WCAG formula
  double contrastRatio(Color fg, Color bg) {
    final l1 = relativeLuminance(fg);
    final l2 = relativeLuminance(bg);
    final lighter = max(l1, l2);
    final darker = min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  group('WCAG Contrast QA Validation', () {
    test('AppColors.cardBlueText on cardBlue meets WCAG AA (>= 4.5:1)', () {
      final ratio = contrastRatio(AppColors.cardBlueText, AppColors.cardBlue);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Text on cardBlue must meet WCAG AA contrast');
    });

    test('AppColors.textGray on cardFillColor meets WCAG AA (>= 4.5:1)', () {
      final ratio = contrastRatio(AppColors.textGray, AppColors.cardFillColor);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'textGray on cardFillColor must meet WCAG AA contrast');
    });

    test('AppColors.textGray on white background meets WCAG AA (>= 4.5:1)', () {
      final ratio = contrastRatio(AppColors.textGray, Colors.white);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'textGray on white must meet WCAG AA contrast');
    });

    test('AppColors.primaryNavy on white meets WCAG AAA (>= 7.0:1)', () {
      final ratio = contrastRatio(AppColors.primaryNavy, Colors.white);
      expect(ratio, greaterThanOrEqualTo(7.0),
          reason: 'primaryNavy on white must have excellent contrast');
    });
  });

  group('Google Pixel 10 Mobile Viewport QA (412 x 915 dp, DPR 2.75)', () {
    const pixelWidth = 412.0;
    const pixelHeight = 915.0;
    const pixelDpr = 2.75;

    Future<void> testScreen(WidgetTester tester, Widget screen, String screenName) async {
      tester.view.physicalSize = const Size(pixelWidth * pixelDpr, pixelHeight * pixelDpr);
      tester.view.devicePixelRatio = pixelDpr;
      tester.view.padding = const FakeViewPadding(top: 48 * pixelDpr, bottom: 24 * pixelDpr);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'Inter'),
            home: screen,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull,
          reason: 'RenderFlex overflow detected on Google Pixel 10 viewport for $screenName');
    }

    testWidgets('HomeScreen renders without overflow on Pixel 10', (tester) async {
      await testScreen(tester, const HomeScreen(), 'HomeScreen');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SoundMeLogo), findsOneWidget);
    });

    testWidgets('TranslatorScreen renders without overflow on Pixel 10', (tester) async {
      await testScreen(tester, const TranslatorScreen(), 'TranslatorScreen');
      expect(find.byType(TranslatorScreen), findsOneWidget);
    });

    testWidgets('DictionaryScreen renders without overflow on Pixel 10', (tester) async {
      await testScreen(tester, const DictionaryScreen(), 'DictionaryScreen');
      expect(find.byType(DictionaryScreen), findsOneWidget);
    });

    testWidgets('OptionsScreen renders without overflow on Pixel 10', (tester) async {
      await testScreen(tester, const OptionsScreen(), 'OptionsScreen');
      expect(find.byType(OptionsScreen), findsOneWidget);
    });

    testWidgets('PermissionsScreen renders without overflow on Pixel 10', (tester) async {
      await testScreen(tester, const PermissionsScreen(), 'PermissionsScreen');
      expect(find.byType(PermissionsScreen), findsOneWidget);
    });

    testWidgets('AboutScreen renders without overflow on Pixel 10', (tester) async {
      await testScreen(tester, const AboutScreen(), 'AboutScreen');
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.byTooltip('Regresar'), findsOneWidget);
    });

    testWidgets('LoginScreen renders without overflow on Pixel 10', (tester) async {
      await testScreen(tester, const LoginScreen(), 'LoginScreen');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byTooltip('Regresar'), findsOneWidget);
    });

    testWidgets('TwoStepAuthScreen renders without overflow on Pixel 10', (tester) async {
      await testScreen(
        tester,
        const TwoStepAuthScreen(identification: '123456', password: 'pass'),
        'TwoStepAuthScreen',
      );
      expect(find.byType(TwoStepAuthScreen), findsOneWidget);
      expect(find.byTooltip('Regresar'), findsOneWidget);
    });

    testWidgets('AdminHomeScreen renders without overflow on Pixel 10', (tester) async {
      await testScreen(tester, const AdminHomeScreen(), 'AdminHomeScreen');
      expect(find.byType(AdminHomeScreen), findsOneWidget);
      expect(find.byTooltip('Regresar'), findsOneWidget);
    });
  });

  group('Compact Mobile Screen QA (360 x 800 dp)', () {
    const compactWidth = 360.0;
    const compactHeight = 800.0;
    const compactDpr = 2.0;

    Future<void> testCompactScreen(WidgetTester tester, Widget screen, String screenName) async {
      tester.view.physicalSize = const Size(compactWidth * compactDpr, compactHeight * compactDpr);
      tester.view.devicePixelRatio = compactDpr;
      tester.view.padding = const FakeViewPadding(top: 24 * compactDpr, bottom: 16 * compactDpr);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'Inter'),
            home: screen,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull,
          reason: 'RenderFlex overflow on narrow 360dp screen for $screenName');
    }

    testWidgets('TwoStepAuthScreen 6-digit inputs do not overflow horizontally on 360dp screen', (tester) async {
      await testCompactScreen(
        tester,
        const TwoStepAuthScreen(identification: 'test', password: 'pass'),
        'TwoStepAuthScreen',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('SoundMeLogo does not overflow horizontally on 360dp screen', (tester) async {
      await testCompactScreen(
        tester,
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: SoundMeLogo(),
          ),
        ),
        'SoundMeLogo 360dp',
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Keyboard Active QA (Soft keyboard open reducing height by 335dp)', () {
    const pixelWidth = 412.0;
    const pixelHeight = 915.0;
    const pixelDpr = 2.75;

    Future<void> testWithKeyboard(WidgetTester tester, Widget screen, String screenName) async {
      tester.view.physicalSize = const Size(pixelWidth * pixelDpr, pixelHeight * pixelDpr);
      tester.view.devicePixelRatio = pixelDpr;
      tester.view.viewInsets = const FakeViewPadding(bottom: 335 * pixelDpr);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'Inter'),
            home: screen,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull,
          reason: 'RenderFlex overflow with active keyboard on $screenName');
    }

    testWidgets('LoginScreen does not overflow when virtual keyboard opens', (tester) async {
      await testWithKeyboard(tester, const LoginScreen(), 'LoginScreen with Keyboard');
      expect(tester.takeException(), isNull);
    });

    testWidgets('TwoStepAuthScreen does not overflow when virtual keyboard opens', (tester) async {
      await testWithKeyboard(
        tester,
        const TwoStepAuthScreen(identification: '123', password: 'pass'),
        'TwoStepAuthScreen with Keyboard',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('TranslatorScreen does not overflow when virtual keyboard opens', (tester) async {
      await testWithKeyboard(tester, const TranslatorScreen(), 'TranslatorScreen with Keyboard');
      expect(tester.takeException(), isNull);
    });
  });

  group('Accessibility QA (1.3x Text Scale Factor)', () {
    testWidgets('PermissionsScreen does not overflow with 1.3x accessibility text scale', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.75, 800 * 2.75);
      tester.view.devicePixelRatio = 2.75;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: const PermissionsScreen(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull,
          reason: 'PermissionsScreen overflowed with 1.3x accessibility text scale');
    });

    testWidgets('HomeScreen does not overflow with 1.3x accessibility text scale', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.75, 800 * 2.75);
      tester.view.devicePixelRatio = 2.75;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: const HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull,
          reason: 'HomeScreen overflowed with 1.3x accessibility text scale');
    });
  });

  group('End-to-End Navigation QA', () {
    testWidgets('HomeScreen "Opciones" button navigates to OptionsScreen (tab index 3)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final opcionesBtn = find.widgetWithText(OutlinedButton, 'Opciones');
      expect(opcionesBtn, findsOneWidget);

      await tester.tap(opcionesBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MainLayoutScreen), findsOneWidget);
      expect(find.byType(OptionsScreen), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
    });

    testWidgets('HomeScreen "Diccionario" button navigates to DictionaryScreen (tab index 2)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final dictBtn = find.widgetWithText(OutlinedButton, 'Diccionario');
      expect(dictBtn, findsOneWidget);

      await tester.tap(dictBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MainLayoutScreen), findsOneWidget);
      expect(find.byType(DictionaryScreen), findsOneWidget);
    });

    testWidgets('HomeScreen "Traductor" button navigates to TranslatorScreen (tab index 1)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final traductorBtn = find.widgetWithText(ElevatedButton, 'Traductor');
      expect(traductorBtn, findsOneWidget);

      await tester.tap(traductorBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MainLayoutScreen), findsOneWidget);
      expect(find.byType(TranslatorScreen), findsOneWidget);
    });

    testWidgets('HomeScreen "Sobre Nosotros" navigates to AboutScreen and back button works', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final aboutBtn = find.widgetWithText(OutlinedButton, 'Sobre Nosotros');
      await tester.tap(aboutBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AboutScreen), findsOneWidget);

      // Tap back button
      final backBtn = find.byTooltip('Regresar');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('LoginScreen back button returns to HomeScreen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap admin button
      final adminBtn = find.byIcon(Icons.manage_accounts_outlined);
      await tester.tap(adminBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LoginScreen), findsOneWidget);

      // Tap back button
      final backBtn = find.byTooltip('Regresar');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
