import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/core/router/app_router.dart';
import 'package:speed_reader/core/widgets/common_widgets.dart';
import 'package:speed_reader/features/library/providers/library_provider.dart';
import 'package:speed_reader/features/library/widgets/library_grid.dart';

/// Library Screen - Main screen showing all PDFs
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

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
            // Navigate to PDF viewer
            context.push(AppRouter.pdfViewer, extra: filePath);
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to add PDF to library')),
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
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRouter.settings),
          ),
        ],
      ),
      body: Consumer<LibraryNotifier>(
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

          return LibraryGrid(
            items: libraryState.items,
            onItemTap: (item) {
              context.push(AppRouter.pdfViewer, extra: item.filePath);
            },
            onItemDelete: (item) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Remove PDF'),
                  content: Text('Remove "${item.fileName}" from library?'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickFile(context),
        icon: const Icon(Icons.add),
        label: const Text('Add PDF'),
      ),
    );
  }
}
