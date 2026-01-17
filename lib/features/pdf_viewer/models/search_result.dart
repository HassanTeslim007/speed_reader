import 'package:equatable/equatable.dart';

/// Represents a single search match in the PDF
class SearchResult extends Equatable {
  final int pageNumber;
  final String matchText;
  final int startIndex;
  final int endIndex;
  final String context;

  const SearchResult({
    required this.pageNumber,
    required this.matchText,
    required this.startIndex,
    required this.endIndex,
    required this.context,
  });

  @override
  List<Object?> get props => [
    pageNumber,
    matchText,
    startIndex,
    endIndex,
    context,
  ];

  @override
  String toString() {
    return 'SearchResult(page: $pageNumber, match: "$matchText", context: "$context")';
  }
}
