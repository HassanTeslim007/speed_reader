import 'package:equatable/equatable.dart';

/// Reading progress model
class ReadingProgress extends Equatable {
  final String documentId;
  final int currentPage;
  final double scrollPosition;
  final DateTime lastReadDate;

  const ReadingProgress({
    required this.documentId,
    required this.currentPage,
    this.scrollPosition = 0.0,
    required this.lastReadDate,
  });

  ReadingProgress copyWith({
    String? documentId,
    int? currentPage,
    double? scrollPosition,
    DateTime? lastReadDate,
  }) {
    return ReadingProgress(
      documentId: documentId ?? this.documentId,
      currentPage: currentPage ?? this.currentPage,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      lastReadDate: lastReadDate ?? this.lastReadDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'currentPage': currentPage,
      'scrollPosition': scrollPosition,
      'lastReadDate': lastReadDate.toIso8601String(),
    };
  }

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      documentId: json['documentId'] as String,
      currentPage: json['currentPage'] as int,
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0.0,
      lastReadDate: DateTime.parse(json['lastReadDate'] as String),
    );
  }

  @override
  List<Object?> get props => [
    documentId,
    currentPage,
    scrollPosition,
    lastReadDate,
  ];
}
