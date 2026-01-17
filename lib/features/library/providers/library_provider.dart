import 'package:flutter/foundation.dart';
import 'package:speed_reader/features/library/models/library_item.dart';
import 'package:speed_reader/features/library/repositories/library_repository.dart';

/// State for library
class LibraryState {
  final List<LibraryItem> items;
  final bool isLoading;
  final String? error;

  const LibraryState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  LibraryState copyWith({
    List<LibraryItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return LibraryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Library notifier using ChangeNotifier
class LibraryNotifier extends ChangeNotifier {
  final LibraryRepository _repository;
  LibraryState _state = const LibraryState();

  LibraryNotifier(this._repository) {
    loadLibrary();
  }

  LibraryState get state => _state;

  void loadLibrary() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final items = _repository.getLibraryItems();

      // Sort by last opened date (most recent first)
      items.sort((a, b) {
        if (a.lastOpenedDate == null && b.lastOpenedDate == null) {
          return b.addedDate.compareTo(a.addedDate);
        }
        if (a.lastOpenedDate == null) return 1;
        if (b.lastOpenedDate == null) return -1;
        return b.lastOpenedDate!.compareTo(a.lastOpenedDate!);
      });

      _state = _state.copyWith(items: items, isLoading: false);
      notifyListeners();

      // Proactively generate missing thumbnails
      bool updated = false;
      for (int i = 0; i < items.length; i++) {
        if (items[i].thumbnailPath == null) {
          final thumb = await _repository.generateThumbnail(items[i].filePath);
          if (thumb != null) {
            items[i] = items[i].copyWith(thumbnailPath: thumb);
            await _repository.updateLibraryItem(items[i]);
            updated = true;
          }
        }
      }

      if (updated) {
        _state = _state.copyWith(items: List.from(items));
        notifyListeners();
      }
    } catch (e) {
      _state = _state.copyWith(
        error: 'Failed to load library: ${e.toString()}',
        isLoading: false,
      );
      notifyListeners();
    }
  }

  Future<LibraryItem?> addItem(String filePath) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final item = await _repository.addLibraryItem(filePath);
      if (item != null) {
        loadLibrary(); // Reload to get updated list
      }
      return item;
    } catch (e) {
      _state = _state.copyWith(
        error: 'Failed to add item: ${e.toString()}',
        isLoading: false,
      );
      notifyListeners();
      return null;
    }
  }

  Future<void> removeItem(String id) async {
    await _repository.removeLibraryItem(id);
    loadLibrary();
  }

  Future<void> updateLastOpened(String id, int currentPage) async {
    await _repository.updateLastOpened(id, currentPage);
    loadLibrary();
  }
}
