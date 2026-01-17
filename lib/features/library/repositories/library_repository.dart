import 'dart:convert';
import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/features/library/models/library_item.dart';
import 'package:uuid/uuid.dart';

/// Repository for library operations
class LibraryRepository {
  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  LibraryRepository(this._prefs);

  /// Get all library items
  List<LibraryItem> getLibraryItems() {
    final jsonString = _prefs.getString(AppConstants.keyRecentFiles);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => LibraryItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a new library item
  Future<LibraryItem?> addLibraryItem(String filePath) async {
    try {
      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      // Get PDF info
      final document = await PdfDocument.openFile(filePath);
      final fileName = filePath.split('/').last;

      // Generate thumbnail
      String? thumbnailPath;
      try {
        final page = await document.getPage(1);
        final pageImage = await page.render(
          width: page.width * 0.5,
          height: page.height * 0.5,
          format: PdfPageImageFormat.jpeg,
          quality: 50,
        );

        if (pageImage != null) {
          final directory = await getApplicationDocumentsDirectory();
          final thumbnailsDir = Directory('${directory.path}/thumbnails');
          if (!await thumbnailsDir.exists()) {
            await thumbnailsDir.create(recursive: true);
          }

          final thumbFile = File('${thumbnailsDir.path}/${_uuid.v4()}.jpg');
          await thumbFile.writeAsBytes(pageImage.bytes);
          thumbnailPath = thumbFile.path;
        }
        await page.close();
      } catch (e) {
        // Thumbnail generation failed, proceed without it
      }

      final item = LibraryItem(
        id: _uuid.v4(),
        filePath: filePath,
        fileName: fileName,
        totalPages: document.pagesCount,
        addedDate: DateTime.now(),
        thumbnailPath: thumbnailPath,
      );

      await document.close();

      // Save to library
      final items = getLibraryItems();

      // Check if already exists
      if (items.any((i) => i.filePath == filePath)) {
        return items.firstWhere((i) => i.filePath == filePath);
      }

      items.add(item);
      await _saveLibraryItems(items);

      return item;
    } catch (e) {
      return null;
    }
  }

  /// Update library item
  Future<void> updateLibraryItem(LibraryItem item) async {
    final items = getLibraryItems();
    final index = items.indexWhere((i) => i.id == item.id);

    if (index != -1) {
      items[index] = item;
      await _saveLibraryItems(items);
    }
  }

  /// Remove library item
  Future<void> removeLibraryItem(String id) async {
    final items = getLibraryItems();
    items.removeWhere((item) => item.id == id);
    await _saveLibraryItems(items);
  }

  /// Update last opened date
  Future<void> updateLastOpened(String id, int currentPage) async {
    final items = getLibraryItems();
    final index = items.indexWhere((i) => i.id == id);

    if (index != -1) {
      items[index] = items[index].copyWith(
        lastOpenedDate: DateTime.now(),
        currentPage: currentPage,
      );
      await _saveLibraryItems(items);
    }
  }

  /// Generate thumbnail for an existing item
  Future<String?> generateThumbnail(String filePath) async {
    try {
      final document = await PdfDocument.openFile(filePath);
      final page = await document.getPage(1);
      final pageImage = await page.render(
        width: page.width * 0.5,
        height: page.height * 0.5,
        format: PdfPageImageFormat.jpeg,
        quality: 50,
      );

      String? thumbnailPath;
      if (pageImage != null) {
        final directory = await getApplicationDocumentsDirectory();
        final thumbnailsDir = Directory('${directory.path}/thumbnails');
        if (!await thumbnailsDir.exists()) {
          await thumbnailsDir.create(recursive: true);
        }

        final thumbFile = File('${thumbnailsDir.path}/${_uuid.v4()}.jpg');
        await thumbFile.writeAsBytes(pageImage.bytes);
        thumbnailPath = thumbFile.path;
      }

      await page.close();
      await document.close();
      return thumbnailPath;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveLibraryItems(List<LibraryItem> items) async {
    final jsonList = items.map((item) => item.toJson()).toList();
    await _prefs.setString(AppConstants.keyRecentFiles, jsonEncode(jsonList));
  }
}
