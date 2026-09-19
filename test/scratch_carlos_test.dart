import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Proper nouns like CARLOS spell dactilologically and do not hijack similar singulars', () async {
    final service = MockupDataService();
    final res = await service.translatePhrase('CARLOS');
    expect(res.matchedSigns.length, 6);
    expect(res.spelledWords, contains('CARLOS'));
  });
}
