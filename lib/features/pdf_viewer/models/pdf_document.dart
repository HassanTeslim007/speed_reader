import 'package:equatable/equatable.dart';

/// PDF Document model
class PdfDocument extends Equatable {
  final String id;
  final String filePath;
  final String fileName;
  final int totalPages;
  final DateTime addedDate;
  final DateTime? lastOpenedDate;
  final String? thumbnailPath;

  const PdfDocument({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.totalPages,
    required this.addedDate,
    this.lastOpenedDate,
    this.thumbnailPath,
  });

  PdfDocument copyWith({
    String? id,
    String? filePath,
    String? fileName,
    int? totalPages,
    DateTime? addedDate,
    DateTime? lastOpenedDate,
    String? thumbnailPath,
  }) {
    return PdfDocument(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      totalPages: totalPages ?? this.totalPages,
      addedDate: addedDate ?? this.addedDate,
      lastOpenedDate: lastOpenedDate ?? this.lastOpenedDate,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'totalPages': totalPages,
      'addedDate': addedDate.toIso8601String(),
      'lastOpenedDate': lastOpenedDate?.toIso8601String(),
      'thumbnailPath': thumbnailPath,
    };
  }

  factory PdfDocument.fromJson(Map<String, dynamic> json) {
    return PdfDocument(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      totalPages: json['totalPages'] as int,
      addedDate: DateTime.parse(json['addedDate'] as String),
      lastOpenedDate: json['lastOpenedDate'] != null
          ? DateTime.parse(json['lastOpenedDate'] as String)
          : null,
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    filePath,
    fileName,
    totalPages,
    addedDate,
    lastOpenedDate,
    thumbnailPath,
  ];
}
