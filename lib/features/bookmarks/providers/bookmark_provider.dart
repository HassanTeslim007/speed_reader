import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:speed_reader/features/bookmarks/models/bookmark.dart';
import 'package:speed_reader/features/bookmarks/repositories/bookmark_repository.dart';

class BookmarkState {
  final List<Bookmark> bookmarks;
  final bool isLoading;
  final String? error;

  BookmarkState({
    this.bookmarks = const [],
    this.isLoading = false,
    this.error,
  });

  BookmarkState copyWith({
    List<Bookmark>? bookmarks,
    bool? isLoading,
    String? error,
  }) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BookmarkProvider extends ChangeNotifier {
  final BookmarkRepository _repository;
  final _uuid = const Uuid();

  BookmarkState _state = BookmarkState();
  BookmarkState get state => _state;

  String? _currentDocumentId;

  BookmarkProvider(this._repository);

  /// Load bookmarks for a document
  void loadBookmarks(String documentId) {
    if (_currentDocumentId == documentId) return;

    _currentDocumentId = documentId;
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final bookmarks = _repository.getBookmarks(documentId);
      _state = _state.copyWith(bookmarks: bookmarks, isLoading: false);
    } catch (e) {
      _state = _state.copyWith(error: e.toString(), isLoading: false);
    }
    notifyListeners();
  }

  /// Check if a specific page is bookmarked
  bool isPageBookmarked(int pageNumber) {
    return _state.bookmarks.any((b) => b.pageNumber == pageNumber);
  }

  /// Toggle bookmark for a page
  Future<void> toggleBookmark(String documentId, int pageNumber) async {
    final existing = _state.bookmarks
        .where((b) => b.pageNumber == pageNumber)
        .toList();

    if (existing.isNotEmpty) {
      // Remove all bookmarks for this page (usually just one)
      for (var b in existing) {
        await _repository.removeBookmark(documentId, b.id);
      }
    } else {
      // Add new bookmark
      final bookmark = Bookmark(
        id: _uuid.v4(),
        documentId: documentId,
        pageNumber: pageNumber,
        createdAt: DateTime.now(),
      );
      await _repository.saveBookmark(bookmark);
    }

    // Reload state
    final bookmarks = _repository.getBookmarks(documentId);
    _state = _state.copyWith(bookmarks: bookmarks);
    notifyListeners();
  }

  /// Update a bookmark's note
  Future<void> updateNote(
    String documentId,
    String bookmarkId,
    String note,
  ) async {
    final index = _state.bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (index == -1) return;

    final updated = _state.bookmarks[index].copyWith(note: note);
    await _repository.saveBookmark(updated);

    // Reload state
    final bookmarks = _repository.getBookmarks(documentId);
    _state = _state.copyWith(bookmarks: bookmarks);
    notifyListeners();
  }

  /// Clear bookmarks for current doc
  void clear() {
    _currentDocumentId = null;
    _state = BookmarkState();
    notifyListeners();
  }
}
