import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TranslationHistoryEntry {
  final String id;
  final String text;
  final DateTime createdAt;
  final List<String> signsInOrder;

  const TranslationHistoryEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.signsInOrder = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'signsInOrder': signsInOrder,
  };

  factory TranslationHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawSigns = json['signsInOrder'];
    final signsList = rawSigns is List
        ? rawSigns.map((item) => item.toString()).toList()
        : const <String>[];

    return TranslationHistoryEntry(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      signsInOrder: signsList,
    );
  }
}

class TranslationHistoryStorage {
  static const String _currentUserKey = 'soundme_current_user_id';
  static const String _historyPrefix = 'soundme_translation_history_';

  Future<void> setCurrentUserId(String userId) async {
    final normalized = _normalizeUserId(userId);
    if (normalized == null || normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, normalized);
  }

  Future<String> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_currentUserKey) ?? 'guest';
    return _normalizeUserId(userId) ?? 'guest';
  }

  Future<void> saveTranslation(
    String text, {
    String? userId,
    List<String>? signsInOrder,
  }) async {
    final cleanText = _normalizeText(text);
    if (cleanText.isEmpty) return;

    final targetUserId = _normalizeUserId(userId) ?? await getCurrentUserId();
    final orderedSigns = (signsInOrder ?? const <String>[])
        .map((sign) => _normalizeText(sign))
        .where((sign) => sign.isNotEmpty)
        .toList();

    final prefs = await SharedPreferences.getInstance();
    final key = '$_historyPrefix$targetUserId';
    final entries = await _readEntries(prefs, key);

    final nextEntries = [
      TranslationHistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: cleanText,
        createdAt: DateTime.now(),
        signsInOrder: orderedSigns,
      ),
      ...entries.where(
        (entry) => entry.text.toLowerCase() != cleanText.toLowerCase(),
      ),
    ];

    final serialized = jsonEncode(
      nextEntries.take(20).map((entry) => entry.toJson()).toList(),
    );

    await prefs.setString(key, serialized);
  }

  Future<List<TranslationHistoryEntry>> getRecentTranslations({
    int limit = 20,
    String? userId,
  }) async {
    final targetUserId = _normalizeUserId(userId) ?? await getCurrentUserId();
    final prefs = await SharedPreferences.getInstance();
    final key = '$_historyPrefix$targetUserId';
    final entries = await _readEntries(prefs, key);
    return entries.take(limit).toList();
  }

  Future<void> clearHistoryForCurrentUser({String? userId}) async {
    final targetUserId = _normalizeUserId(userId) ?? await getCurrentUserId();
    final prefs = await SharedPreferences.getInstance();
    final key = '$_historyPrefix$targetUserId';
    await prefs.remove(key);
  }

  Future<List<TranslationHistoryEntry>> _readEntries(
    SharedPreferences prefs,
    String key,
  ) async {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .map(
            (entry) => TranslationHistoryEntry.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  String? _normalizeUserId(String? userId) {
    final value = (userId ?? '').trim();
    return value.isEmpty ? null : value.toLowerCase();
  }

  String _normalizeText(String text) {
    return text.trim();
  }
}
