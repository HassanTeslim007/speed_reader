import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speed_reader/features/pdf_viewer/models/search_result.dart';
import 'package:speed_reader/features/pdf_viewer/models/search_state.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion_pdf;

/// Isolate function for extracting all text from PDF
Map<String, dynamic> _extractAllPdfTextIsolate(List<int> bytes) {
  try {
    final pdfDocument = syncfusion_pdf.PdfDocument(inputBytes: bytes);
    final totalPages = pdfDocument.pages.count;

    final List<String> pageTexts = [];

    // Extract text from all pages
    for (int i = 0; i < totalPages; i++) {
      final text = syncfusion_pdf.PdfTextExtractor(
        pdfDocument,
      ).extractText(startPageIndex: i, endPageIndex: i);
      pageTexts.add(text);
    }

    pdfDocument.dispose();

    return {'success': true, 'pageTexts': pageTexts};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

/// Isolate function for searching text
Map<String, dynamic> _searchTextIsolate(Map<String, dynamic> params) {
  try {
    final pageTexts = params['pageTexts'] as List<String>;
    final query = params['query'] as String;
    final caseSensitive = params['caseSensitive'] as bool;

    final List<Map<String, dynamic>> results = [];

    for (int pageIndex = 0; pageIndex < pageTexts.length; pageIndex++) {
      final pageText = pageTexts[pageIndex];
      final searchText = caseSensitive ? pageText : pageText.toLowerCase();
      final searchQuery = caseSensitive ? query : query.toLowerCase();

      int startIndex = 0;
      while (true) {
        final index = searchText.indexOf(searchQuery, startIndex);
        if (index == -1) break;

        // Get context (50 chars before and after)
        final contextStart = (index - 50).clamp(0, pageText.length);
        final contextEnd = (index + searchQuery.length + 50).clamp(
          0,
          pageText.length,
        );
        final context = pageText.substring(contextStart, contextEnd);

        results.add({
          'pageNumber': pageIndex + 1,
          'matchText': pageText.substring(index, index + searchQuery.length),
          'startIndex': index,
          'endIndex': index + searchQuery.length,
          'context': context,
        });

        startIndex = index + 1;
      }
    }

    return {'success': true, 'results': results};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

/// Provider for managing PDF text search
class SearchProvider extends ChangeNotifier {
  SearchState _state = const SearchState();
  List<String>? _cachedPageTexts;
  String? _cachedFilePath;

  SearchState get state => _state;

  /// Extract and cache all text from PDF
  Future<void> extractText(String filePath) async {
    // Return if already cached for this file
    if (_cachedFilePath == filePath && _cachedPageTexts != null) {
      return;
    }

    try {
      final bytes = await File(filePath).readAsBytes();
      final result = await compute(_extractAllPdfTextIsolate, bytes);

      if (result['success'] == true) {
        _cachedPageTexts = List<String>.from(result['pageTexts']);
        _cachedFilePath = filePath;
      } else {
        debugPrint('Error extracting text: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Error extracting text: $e');
    }
  }

  /// Perform search
  Future<void> search(String query, {bool? caseSensitive}) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    if (_cachedPageTexts == null) {
      debugPrint('No cached text available. Call extractText first.');
      return;
    }

    _state = _state.copyWith(
      query: query,
      isSearching: true,
      caseSensitive: caseSensitive,
    );
    notifyListeners();

    try {
      final result = await compute(_searchTextIsolate, {
        'pageTexts': _cachedPageTexts!,
        'query': query,
        'caseSensitive': _state.caseSensitive,
      });

      if (result['success'] == true) {
        final resultMaps = List<Map<String, dynamic>>.from(result['results']);
        final searchResults = resultMaps.map((map) {
          return SearchResult(
            pageNumber: map['pageNumber'] as int,
            matchText: map['matchText'] as String,
            startIndex: map['startIndex'] as int,
            endIndex: map['endIndex'] as int,
            context: map['context'] as String,
          );
        }).toList();

        _state = _state.copyWith(
          results: searchResults,
          currentMatchIndex: searchResults.isNotEmpty ? 0 : -1,
          isSearching: false,
        );
      } else {
        _state = _state.copyWith(
          results: [],
          currentMatchIndex: -1,
          isSearching: false,
        );
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      _state = _state.copyWith(
        results: [],
        currentMatchIndex: -1,
        isSearching: false,
      );
    }

    notifyListeners();
  }

  /// Navigate to next match
  void nextMatch() {
    if (_state.results.isEmpty) return;

    final newIndex = (_state.currentMatchIndex + 1) % _state.results.length;
    _state = _state.copyWith(currentMatchIndex: newIndex);
    notifyListeners();
  }

  /// Navigate to previous match
  void previousMatch() {
    if (_state.results.isEmpty) return;

    final newIndex =
        (_state.currentMatchIndex - 1 + _state.results.length) %
        _state.results.length;
    _state = _state.copyWith(currentMatchIndex: newIndex);
    notifyListeners();
  }

  /// Jump to specific match
  void jumpToMatch(int index) {
    if (index >= 0 && index < _state.results.length) {
      _state = _state.copyWith(currentMatchIndex: index);
      notifyListeners();
    }
  }

  /// Toggle case sensitivity
  void toggleCaseSensitive() {
    _state = _state.copyWith(caseSensitive: !_state.caseSensitive);
    notifyListeners();

    // Re-search with new case sensitivity
    if (_state.query.isNotEmpty) {
      search(_state.query);
    }
  }

  /// Clear search results
  void clearSearch() {
    _state = const SearchState();
    notifyListeners();
  }

  /// Clear cache (call when switching documents)
  void clearCache() {
    _cachedPageTexts = null;
    _cachedFilePath = null;
    clearSearch();
  }
}
