import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/core/router/app_router.dart';
import 'package:speed_reader/core/widgets/common_widgets.dart';
import 'package:speed_reader/core/widgets/pattern_painters.dart';
import 'package:speed_reader/features/library/providers/library_provider.dart';
import 'package:speed_reader/features/library/widgets/library_shelf.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:path_provider/path_provider.dart';

/// Library Screen - Main screen showing all PDFs
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Future<void> _addFromWeb(BuildContext context) async {
    final urlController = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Web Article'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(hintText: 'https://example.com/article'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, urlController.text), child: const Text('Add')),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final document = parse(response.body);
          final docTitle = document.head?.querySelector('title')?.text ?? '';
          final title = docTitle.isNotEmpty ? docTitle : uri.host;
          final articleElement = document.querySelector('article') ?? document.body;
          
          // Remove unwanted script/style tags before extracting text
          if (articleElement != null) {
            final unwantedTags = ['script', 'style', 'noscript', 'meta', 'link', 'nav', 'header', 'footer', 'aside'];
            for (final tag in unwantedTags) {
              articleElement.querySelectorAll(tag).forEach((e) => e.remove());
            }
          }

          String textContent = articleElement?.text ?? '';
          textContent = textContent.replaceAll(RegExp(r'\s+'), ' ').trim();

          final dir = await getTemporaryDirectory();
          final tempFile = File('${dir.path}/${title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.txt');
          await tempFile.writeAsString(textContent);

          if (context.mounted) {
            Navigator.pop(context); // Close loading dialog
            final item = await context.read<LibraryNotifier>().addItem(tempFile.path);
            if (item != null && context.mounted) {
              context.push(AppRouter.textReader, extra: item.filePath);
            }
          }
        } else {
          throw Exception('Failed to load: HTTP ${response.statusCode}');
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedExtensions,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        if (context.mounted) {
          final item = await context.read<LibraryNotifier>().addItem(filePath);

          if (item != null && context.mounted) {
            // Check if it's text or pdf and route properly
            final ext = item.filePath.split('.').last.toLowerCase();
            if (ext == 'txt' || ext == 'html') {
              context.push(AppRouter.textReader, extra: item.filePath);
            } else {
              context.push(AppRouter.pdfViewer, extra: item.filePath);
            }
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to add document to library')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Add Web Article',
            onPressed: () => _addFromWeb(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRouter.settings),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: Stack(
          children: [
            // Subtle Pattern Overlay (Procedural)
            CustomPaint(
              size: Size.infinite,
              painter: GeometricGridPainter(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
              child: Consumer<LibraryNotifier>(
                builder: (context, notifier, child) {
                  final libraryState = notifier.state;

                  if (libraryState.isLoading) {
                    return const LoadingWidget(message: 'Loading library...');
                  }

                  if (libraryState.error != null) {
                    return AppErrorWidget(
                      message: libraryState.error!,
                      onRetry: () => notifier.loadLibrary(),
                    );
                  }

                  if (libraryState.items.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.library_books,
                      title: 'No PDFs in library',
                      subtitle: 'Add your first PDF to get started',
                      action: FilledButton.icon(
                        onPressed: () => _pickFile(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add PDF'),
                      ),
                    );
                  }

                  return LibraryShelf(
                    items: libraryState.items,
                    onItemOpen: (item) {
                      final ext = item.filePath.split('.').last.toLowerCase();
                      if (ext == 'txt' || ext == 'html') {
                        context.push(AppRouter.textReader, extra: item.filePath);
                      } else {
                        context.push(AppRouter.pdfViewer, extra: item.filePath);
                      }
                    },
                    onItemDelete: (item) async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Remove PDF'),
                          content: Text(
                            'Remove "${item.fileName}" from library?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        context.read<LibraryNotifier>().removeItem(item.id);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickFile(context),
        icon: const Icon(Icons.add),
        label: const Text('Add PDF'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
