// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;

/// Singleton helper that manages the encrypted SQLite database.
///
/// Uses `sqflite_sqlcipher` with a randomly generated AES-256 key stored in
/// [FlutterSecureStorage] (Android Keystore / iOS Keychain).
///
/// The database contains the local dictionary schema needed for offline sync.
class DatabaseHelper {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  static DatabaseHelper? _instance;

  factory DatabaseHelper({FlutterSecureStorage? secureStorage}) {
    _instance ??= DatabaseHelper._internal(
      secureStorage: secureStorage ?? const FlutterSecureStorage(),
    );
    return _instance!;
  }

  /// Resets the singleton.  **Only use in tests.**
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  DatabaseHelper._internal({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  static const String _dbName = 'soundme.db';
  static const int _dbVersion = 1;
  static const String _cipherKeyStorageKey = 'db_cipher_key';

  sqlcipher.Database? _database;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the open (and possibly just-created) database handle.
  Future<sqlcipher.Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Closes the database connection gracefully.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<sqlcipher.Database> _initDatabase() async {
    final dbPath = await sqlcipher.getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    final key = await _getOrCreateCipherKey();

    return sqlcipher.openDatabase(
      path,
      password: key,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Retrieves the existing cipher key from secure storage, or generates a
  /// new random 256-bit key on first run.
  Future<String> _getOrCreateCipherKey() async {
    final existing = await _secureStorage.read(key: _cipherKeyStorageKey);
    if (existing != null && existing.isNotEmpty) return existing;

    // Generate 32 random bytes → 256-bit key encoded as base64.
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final key = base64Url.encode(bytes);

    await _secureStorage.write(key: _cipherKeyStorageKey, value: key);
    return key;
  }

  // ---------------------------------------------------------------------------
  // Schema
  // ---------------------------------------------------------------------------

  Future<void> _onCreate(sqlcipher.Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dictionary_items (
        id            INTEGER PRIMARY KEY,
        word          TEXT    NOT NULL,
        sign_url      TEXT,
        image_url     TEXT,
        updated_at    INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Index for delta-sync queries filtered by timestamp.
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_dict_updated
        ON dictionary_items (updated_at)
    ''');
  }

  Future<void> _onUpgrade(
    sqlcipher.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Placeholder for future migrations.
    // Each migration step should be guarded by version checks:
    //   if (oldVersion < 2) { ... }
  }
}
