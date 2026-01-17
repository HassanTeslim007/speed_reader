import 'package:flutter/foundation.dart';
import 'package:speed_reader/features/pdf_viewer/models/reading_progress.dart';
import 'package:speed_reader/features/pdf_viewer/repositories/pdf_repository.dart';

/// State for PDF viewer
class PdfViewerState {
  final int currentPage;
  final int totalPages;
  final double zoom;
  final bool isLoading;
  final String? error;
  final bool isFullscreen;

  const PdfViewerState({
    this.currentPage = 1,
    this.totalPages = 0,
    this.zoom = 1.0,
    this.isLoading = false,
    this.error,
    this.isFullscreen = false,
  });

  PdfViewerState copyWith({
    int? currentPage,
    int? totalPages,
    double? zoom,
    bool? isLoading,
    String? error,
    bool? isFullscreen,
  }) {
    return PdfViewerState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      zoom: zoom ?? this.zoom,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isFullscreen: isFullscreen ?? this.isFullscreen,
    );
  }
}

/// PDF Viewer notifier using ChangeNotifier
class PdfViewerNotifier extends ChangeNotifier {
  final PdfRepository _repository;
  String? _currentDocumentId;
  PdfViewerState _state = const PdfViewerState();

  PdfViewerNotifier(this._repository);

  PdfViewerState get state => _state;

  void initialize(String documentId, int totalPages) {
    _currentDocumentId = documentId;

    // Try to restore reading progress
    final progress = _repository.getReadingProgress(documentId);

    _state = _state.copyWith(
      totalPages: totalPages,
      currentPage: progress?.currentPage ?? 1,
      isLoading: false,
    );
    notifyListeners();
  }

  void setCurrentPage(int page) {
    _state = _state.copyWith(currentPage: page);
    notifyListeners();
    _saveProgress();
  }

  void setZoom(double zoom) {
    _state = _state.copyWith(zoom: zoom);
    notifyListeners();
  }

  void nextPage() {
    if (_state.currentPage < _state.totalPages) {
      setCurrentPage(_state.currentPage + 1);
    }
  }

  void previousPage() {
    if (_state.currentPage > 1) {
      setCurrentPage(_state.currentPage - 1);
    }
  }

  void toggleFullscreen() {
    _state = _state.copyWith(isFullscreen: !_state.isFullscreen);
    notifyListeners();
  }

  void _saveProgress() {
    if (_currentDocumentId != null) {
      final progress = ReadingProgress(
        documentId: _currentDocumentId!,
        currentPage: _state.currentPage,
        lastReadDate: DateTime.now(),
      );
      _repository.saveReadingProgress(progress);
    }
  }

  @override
  void dispose() {
    _saveProgress();
    super.dispose();
  }
}
