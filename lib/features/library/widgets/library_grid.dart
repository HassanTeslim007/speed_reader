import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/features/library/models/library_item.dart';

/// Grid view for library items
class LibraryGrid extends StatelessWidget {
  final List<LibraryItem> items;
  final Function(LibraryItem) onItemTap;
  final Function(LibraryItem)? onItemDelete;

  const LibraryGrid({
    super.key,
    required this.items,
    required this.onItemTap,
    this.onItemDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: AppConstants.spacingMd,
        mainAxisSpacing: AppConstants.spacingMd,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _LibraryCard(
          item: item,
          onTap: () => onItemTap(item),
          onDelete: onItemDelete != null ? () => onItemDelete!(item) : null,
        );
      },
    );
  }
}

class _LibraryCard extends StatelessWidget {
  final LibraryItem item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _LibraryCard({required this.item, required this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.primaryContainer,
                child:
                    item.thumbnailPath != null &&
                        File(item.thumbnailPath!).existsSync()
                    ? Image.file(File(item.thumbnailPath!), fit: BoxFit.cover)
                    : Icon(
                        Icons.picture_as_pdf,
                        size: 64,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
              ),
            ),

            // Progress indicator
            if (item.currentPage != null && item.currentPage! > 0)
              LinearProgressIndicator(
                value: item.progress,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),

            // File info
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: AppConstants.iconSizeSm,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: AppConstants.spacingXs),
                      Text(
                        '${item.totalPages} pages',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const Spacer(),
                      if (onDelete != null)
                        InkWell(
                          onTap: onDelete,
                          child: Icon(
                            Icons.delete_outline,
                            size: AppConstants.iconSizeSm,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                  if (item.currentPage != null) ...[
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      'Page ${item.currentPage} of ${item.totalPages}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
