import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_reader/features/bookmarks/models/bookmark.dart';

/// Repository for managing bookmarks
class BookmarkRepository {
  final SharedPreferences _prefs;
  static const String _keyPrefix = 'bookmarks_';

  BookmarkRepository(this._prefs);

  /// Get all bookmarks for a specific document
  List<Bookmark> getBookmarks(String documentId) {
    final key = '$_keyPrefix$documentId';
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => Bookmark.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add or update a bookmark
  Future<void> saveBookmark(Bookmark bookmark) async {
    final bookmarks = getBookmarks(bookmark.documentId);
    final index = bookmarks.indexWhere((b) => b.id == bookmark.id);

    if (index != -1) {
      bookmarks[index] = bookmark;
    } else {
      bookmarks.add(bookmark);
    }

    await _saveBookmarks(bookmark.documentId, bookmarks);
  }

  /// Remove a bookmark by ID
  Future<void> removeBookmark(String documentId, String bookmarkId) async {
    final bookmarks = getBookmarks(documentId);
    bookmarks.removeWhere((b) => b.id == bookmarkId);
    await _saveBookmarks(documentId, bookmarks);
  }

  /// Remove bookmark for a specific page
  Future<void> removeBookmarkForPage(String documentId, int pageNumber) async {
    final bookmarks = getBookmarks(documentId);
    bookmarks.removeWhere((b) => b.pageNumber == pageNumber);
    await _saveBookmarks(documentId, bookmarks);
  }

  Future<void> _saveBookmarks(
    String documentId,
    List<Bookmark> bookmarks,
  ) async {
    final key = '$_keyPrefix$documentId';
    final jsonList = bookmarks.map((b) => b.toJson()).toList();
    await _prefs.setString(key, jsonEncode(jsonList));
  }
}
