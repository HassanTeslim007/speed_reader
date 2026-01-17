import 'package:flutter/material.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/features/library/models/library_item.dart';
import 'package:speed_reader/features/library/widgets/shelf_book.dart';

/// A widget that displays library items on a series of shelves.
class LibraryShelf extends StatelessWidget {
  final List<LibraryItem> items;
  final Function(LibraryItem) onItemOpen;
  final Function(LibraryItem)? onItemDelete;

  const LibraryShelf({
    super.key,
    required this.items,
    required this.onItemOpen,
    this.onItemDelete,
  });

  @override
  Widget build(BuildContext context) {
    // We'll group items into "shelves" - let's say 4-5 books per shelf
    // Actually, since they are spines, we can fit more.
    // Let's just use a Wrap for simplicity now, but styled to look like shelves.

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildShelves(context),
      ),
    );
  }

  List<Widget> _buildShelves(BuildContext context) {
    const int itemsPerShelf = 8; // Max items before starting a new shelf
    final List<Widget> shelves = [];

    for (int i = 0; i < items.length; i += itemsPerShelf) {
      final shelfItems = items.skip(i).take(itemsPerShelf).toList();
      shelves.add(_buildShelfRow(context, shelfItems));
      shelves.add(const SizedBox(height: 40)); // Space between shelves
    }

    return shelves;
  }

  Widget _buildShelfRow(BuildContext context, List<LibraryItem> shelfItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The books on the shelf
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: shelfItems.map((item) {
              return ShelfBook(
                item: item,
                onOpen: () => onItemOpen(item),
                onDelete: onItemDelete != null
                    ? () => onItemDelete!(item)
                    : null,
              );
            }).toList(),
          ),
        ),

        // The shelf board divider
        Container(
          width: double.infinity,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.brown[700],
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.brown[600]!, Colors.brown[800]!],
            ),
          ),
        ),
      ],
    );
  }
}
