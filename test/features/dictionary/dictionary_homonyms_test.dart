import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/features/dictionary/data/mock_dictionary_repository.dart';
import 'package:soundme_frontend/features/dictionary/presentation/dictionary_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await MockDictionaryRepository.loadData();
  });

  group('Dictionary Homonyms and Context Tests', () {
    test('MockDictionaryRepository loads contextual homonyms from JSON', () {
      expect(MockDictionaryRepository.contextualHomonyms, isNotEmpty);
      final llama = MockDictionaryRepository.findHomonymForWord('LLAMA');
      expect(llama, isNotNull);
      expect(llama!.acepciones.length, greaterThanOrEqualTo(2));
      expect(llama.acepciones.any((a) => a.sign == 'LLAMAR'), isTrue);
      expect(llama.acepciones.any((a) => a.sign == 'FUEGO'), isTrue);

      final banco = MockDictionaryRepository.findHomonymForWord('BANCO');
      expect(banco, isNotNull);
      expect(banco!.acepciones.any((a) => a.sign == 'BANCO (FINANCIERO)'), isTrue);
    });

    test('MockDictionaryWord correctly identifies homonym and matched sense', () {
      final fuegoWord = MockDictionaryRepository.mockWords.firstWhere(
        (w) => w.palabra == 'FUEGO',
      );
      expect(fuegoWord.contextualHomonym, isNotNull);
      expect(fuegoWord.contextualHomonym!.palabra, 'LLAMA');
      expect(fuegoWord.matchedSense, isNotNull);
      expect(fuegoWord.matchedSense!.sentido, contains('Fuego'));

      final sentarWord = MockDictionaryRepository.mockWords.firstWhere(
        (w) => w.palabra == 'SENTARSE',
      );
      expect(sentarWord.palabra, 'SENTARSE');
    });

    testWidgets('DictionaryScreen displays contextual homonym card when searching "llama"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DictionaryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'llama');
      await tester.pumpAndSettle();

      // Card contextual de palabra homógrafa
      expect(find.textContaining('Palabra homógrafa: LLAMA'), findsOneWidget);
      expect(find.textContaining('Fuego / flama'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Verbo llamar'), findsAtLeastNWidgets(1));
    });

    testWidgets('DictionaryScreen searching "sentar" finds SENTARSE', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DictionaryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'sentar');
      await tester.pumpAndSettle();

      expect(find.text('SENTARSE'), findsOneWidget);
    });
  });
}
