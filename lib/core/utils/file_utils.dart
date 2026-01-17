import 'dart:io';
import 'package:path/path.dart' as path;

/// Utility functions for file operations
class FileUtils {
  FileUtils._();

  /// Get file name from path
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Get file extension
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  /// Check if file is a PDF
  static bool isPdfFile(String filePath) {
    return getFileExtension(filePath) == '.pdf';
  }

  /// Get file size in human-readable format
  static String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if file exists
  static Future<bool> fileExists(String filePath) async {
    return File(filePath).exists();
  }

  /// Delete file
  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get file last modified date
  static Future<DateTime> getLastModified(String filePath) async {
    final file = File(filePath);
    return file.lastModified();
  }
}
