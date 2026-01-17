import 'package:equatable/equatable.dart';

/// Library item model
class LibraryItem extends Equatable {
  final String id;
  final String filePath;
  final String fileName;
  final int totalPages;
  final DateTime addedDate;
  final DateTime? lastOpenedDate;
  final int? currentPage;
  final String? thumbnailPath;

  const LibraryItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.totalPages,
    required this.addedDate,
    this.lastOpenedDate,
    this.currentPage,
    this.thumbnailPath,
  });

  double get progress {
    if (currentPage == null || totalPages == 0) return 0.0;
    return currentPage! / totalPages;
  }

  LibraryItem copyWith({
    String? id,
    String? filePath,
    String? fileName,
    int? totalPages,
    DateTime? addedDate,
    DateTime? lastOpenedDate,
    int? currentPage,
    String? thumbnailPath,
  }) {
    return LibraryItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      totalPages: totalPages ?? this.totalPages,
      addedDate: addedDate ?? this.addedDate,
      lastOpenedDate: lastOpenedDate ?? this.lastOpenedDate,
      currentPage: currentPage ?? this.currentPage,
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
      'currentPage': currentPage,
      'thumbnailPath': thumbnailPath,
    };
  }

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      totalPages: json['totalPages'] as int,
      addedDate: DateTime.parse(json['addedDate'] as String),
      lastOpenedDate: json['lastOpenedDate'] != null
          ? DateTime.parse(json['lastOpenedDate'] as String)
          : null,
      currentPage: json['currentPage'] as int?,
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
    currentPage,
    thumbnailPath,
  ];
}
