import 'package:flutter/material.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/features/library/models/library_item.dart';
import 'package:speed_reader/features/library/widgets/shelf_book.dart';

/// A premium widget that displays library items on high-fidelity wooden shelves.
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
    const int itemsPerShelf = 8;
    final List<Widget> shelves = [];

    for (int i = 0; i < items.length; i += itemsPerShelf) {
      final shelfItems = items.skip(i).take(itemsPerShelf).toList();
      shelves.add(_buildShelfRow(context, shelfItems));
      shelves.add(const SizedBox(height: 50));
    }

    return shelves;
  }

  Widget _buildShelfRow(BuildContext context, List<LibraryItem> shelfItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Books with Ambient Occlusion shadow underneath
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Shelf shadow on the wall behind books
            Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: shelfItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ShelfBook(
                        item: item,
                        onOpen: () => onItemOpen(item),
                        onDelete: onItemDelete != null
                            ? () => onItemDelete!(item)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        // The Premium Shelf Board
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(4),
            ),
            boxShadow: [
              // Bottom shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              // Side depth
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 2,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(4),
            ),
            child: Stack(
              children: [
                // Base Wood Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF5D4037), // Lighter brown top edge
                        const Color(0xFF3E2723), // Deep brown bottom
                      ],
                    ),
                  ),
                ),
                // Wood Grain Texture (Overlay)
                Opacity(
                  opacity: 0.1,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://www.transparenttextures.com/patterns/wood-pattern.png',
                        ),
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                  ),
                ),
                // Edge Highlight
                Container(
                  height: 1.5,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
