import 'package:flutter_test/flutter_test.dart';
import 'package:soundme_frontend/data/local/database_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// =============================================================================
// In-memory FlutterSecureStorage fake for unit tests.
//
// Uses `AppleOptions` for both iOptions and mOptions to match
// flutter_secure_storage v11 API signatures.
// =============================================================================
class FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  /// Expose store for assertions.
  Map<String, String> get store => _store;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _store[key] = value;
    } else {
      _store.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  // -- Stubs for remaining FlutterSecureStorage interface methods --

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store.containsKey(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_store);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    DatabaseHelper.resetInstance();
  });

  group('DatabaseHelper', () {
    test('factory returns a singleton instance', () {
      final fakeStorage = FakeSecureStorage();
      final a = DatabaseHelper(secureStorage: fakeStorage);
      final b = DatabaseHelper(secureStorage: fakeStorage);
      expect(identical(a, b), isTrue);
    });

    test('resetInstance allows creating a fresh instance', () {
      final fakeStorage = FakeSecureStorage();
      final first = DatabaseHelper(secureStorage: fakeStorage);
      DatabaseHelper.resetInstance();
      final second = DatabaseHelper(secureStorage: fakeStorage);
      expect(identical(first, second), isFalse);
    });

    // The following tests require the sqflite_sqlcipher FFI driver which
    // depends on a native SQLCipher library.  On platforms where this
    // is available (Linux CI, macOS), they will pass.  On Windows dev
    // environments without the native library they are skipped gracefully.

    test(
      'database getter opens a database (requires native SQLCipher)',
      () async {
        final fakeStorage = FakeSecureStorage();
        final helper = DatabaseHelper(secureStorage: fakeStorage);

        try {
          final db = await helper.database;
          expect(db.isOpen, isTrue);

          // Verify the cipher key was persisted.
          expect(fakeStorage.store.containsKey('db_cipher_key'), isTrue);
          expect(fakeStorage.store['db_cipher_key']!.isNotEmpty, isTrue);

          // Verify the dictionary_items table exists.
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='dictionary_items'",
          );
          expect(tables, isNotEmpty);
          expect(tables.first['name'], equals('dictionary_items'));

          await helper.close();
        } on Exception catch (e) {
          markTestSkipped(
            'Native SQLCipher not available on this platform: $e',
          );
        }
      },
    );

    test(
      'CRUD on dictionary_items (requires native SQLCipher)',
      () async {
        final fakeStorage = FakeSecureStorage();
        final helper = DatabaseHelper(secureStorage: fakeStorage);

        try {
          final db = await helper.database;

          // INSERT
          final id = await db.insert('dictionary_items', {
            'word': 'hola',
            'sign_url': 'https://example.com/hola.webp',
            'image_url': 'https://example.com/hola_img.webp',
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          });
          expect(id, greaterThan(0));

          // SELECT
          final rows = await db.query(
            'dictionary_items',
            where: 'id = ?',
            whereArgs: [id],
          );
          expect(rows.length, equals(1));
          expect(rows.first['word'], equals('hola'));

          // UPDATE
          final updated = await db.update(
            'dictionary_items',
            {'word': 'hola_updated'},
            where: 'id = ?',
            whereArgs: [id],
          );
          expect(updated, equals(1));

          // DELETE
          final deleted = await db.delete(
            'dictionary_items',
            where: 'id = ?',
            whereArgs: [id],
          );
          expect(deleted, equals(1));

          await helper.close();
        } on Exception catch (e) {
          markTestSkipped(
            'Native SQLCipher not available on this platform: $e',
          );
        }
      },
    );
  });
}
