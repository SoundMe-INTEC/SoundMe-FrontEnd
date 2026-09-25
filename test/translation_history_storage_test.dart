import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundme_frontend/core/services/translation_history_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'guarda el historial por usuario y mantiene cada lista separada',
    () async {
      final history = TranslationHistoryStorage();

      await history.setCurrentUserId('alice');
      await history.saveTranslation(
        'hola',
        userId: 'alice',
        signsInOrder: ['HOLA'],
      );
      await history.saveTranslation(
        'gracias',
        userId: 'alice',
        signsInOrder: ['GRACIAS'],
      );

      await history.setCurrentUserId('bob');
      await history.saveTranslation(
        'buenos días',
        userId: 'bob',
        signsInOrder: ['BUENOS', 'DÍAS'],
      );

      final aliceHistory = await history.getRecentTranslations(userId: 'alice');
      final bobHistory = await history.getRecentTranslations(userId: 'bob');

      expect(aliceHistory.map((entry) => entry.text).toList(), [
        'gracias',
        'hola',
      ]);
      expect(aliceHistory.first.signsInOrder, ['GRACIAS']);
      expect(bobHistory.map((entry) => entry.text).toList(), ['buenos días']);
      expect(bobHistory.first.signsInOrder, ['BUENOS', 'DÍAS']);
    },
  );
}
