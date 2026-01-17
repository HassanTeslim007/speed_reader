import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/features/pdf_viewer/models/reading_progress.dart';

/// Repository for PDF-related operations
class PdfRepository {
  final SharedPreferences _prefs;

  PdfRepository(this._prefs);

  /// Save reading progress
  Future<void> saveReadingProgress(ReadingProgress progress) async {
    final key = '${AppConstants.keyReadingProgress}${progress.documentId}';
    await _prefs.setString(key, jsonEncode(progress.toJson()));
  }

  /// Get reading progress for a document
  ReadingProgress? getReadingProgress(String documentId) {
    final key = '${AppConstants.keyReadingProgress}$documentId';
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ReadingProgress.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Delete reading progress
  Future<void> deleteReadingProgress(String documentId) async {
    final key = '${AppConstants.keyReadingProgress}$documentId';
    await _prefs.remove(key);
  }

  /// Get all reading progress entries
  Map<String, ReadingProgress> getAllReadingProgress() {
    final Map<String, ReadingProgress> progressMap = {};
    final keys = _prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(AppConstants.keyReadingProgress)) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          try {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final progress = ReadingProgress.fromJson(json);
            progressMap[progress.documentId] = progress;
          } catch (e) {
            // Skip invalid entries
          }
        }
      }
    }

    return progressMap;
  }
}
