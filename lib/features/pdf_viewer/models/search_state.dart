import 'package:equatable/equatable.dart';
import 'package:speed_reader/features/pdf_viewer/models/search_result.dart';

/// Represents the current state of a search session
class SearchState extends Equatable {
  final String query;
  final List<SearchResult> results;
  final int currentMatchIndex;
  final bool caseSensitive;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.currentMatchIndex = -1,
    this.caseSensitive = false,
    this.isSearching = false,
  });

  bool get hasResults => results.isNotEmpty;
  int get totalMatches => results.length;

  SearchResult? get currentMatch {
    if (currentMatchIndex >= 0 && currentMatchIndex < results.length) {
      return results[currentMatchIndex];
    }
    return null;
  }

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    int? currentMatchIndex,
    bool? caseSensitive,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      currentMatchIndex: currentMatchIndex ?? this.currentMatchIndex,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props => [
    query,
    results,
    currentMatchIndex,
    caseSensitive,
    isSearching,
  ];
}
