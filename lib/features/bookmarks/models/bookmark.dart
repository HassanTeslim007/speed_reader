import 'package:equatable/equatable.dart';

/// Model representing a bookmark in a PDF document
class Bookmark extends Equatable {
  final String id;
  final String documentId;
  final int pageNumber;
  final String? note;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    this.note,
    required this.createdAt,
  });

  Bookmark copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    String? note,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'pageNumber': pageNumber,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      pageNumber: json['pageNumber'] as int,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, documentId, pageNumber, note, createdAt];
}
