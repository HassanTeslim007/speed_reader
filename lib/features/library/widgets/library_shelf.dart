import 'package:flutter/material.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/core/widgets/pattern_painters.dart';
import 'package:speed_reader/features/library/models/library_item.dart';
import 'package:speed_reader/features/library/widgets/shelf_book.dart';

/// A premium widget that displays library items on high-fidelity wooden shelves.
/// Dynamically calculates shelves based on available width.
class LibraryShelf extends StatefulWidget {
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
  State<LibraryShelf> createState() => _LibraryShelfState();
}

class _LibraryShelfState extends State<LibraryShelf> {
  String? _expandedItemId;

  void _handleToggleExpand(String itemId) {
    setState(() {
      if (_expandedItemId == itemId) {
        _expandedItemId = null;
      } else {
        _expandedItemId = itemId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildShelves(context, constraints.maxWidth),
          ),
        );
      },
    );
  }

  List<Widget> _buildShelves(BuildContext context, double maxWidth) {
    const double approxBookWidth = 46.0;
    final double availableWidth = maxWidth - (AppConstants.spacingMd * 2);

    int itemsPerShelf = (availableWidth / approxBookWidth).floor();
    if (itemsPerShelf < 1) itemsPerShelf = 1;

    final List<Widget> shelves = [];
    for (int i = 0; i < widget.items.length; i += itemsPerShelf) {
      final shelfItems = widget.items.skip(i).take(itemsPerShelf).toList();
      shelves.add(_buildShelfRow(context, shelfItems));
      shelves.add(const SizedBox(height: 50));
    }

    return shelves;
  }

  Widget _buildShelfRow(BuildContext context, List<LibraryItem> shelfItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: shelfItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ShelfBook(
                      item: item,
                      isExpanded: _expandedItemId == item.id,
                      onToggleExpand: () => _handleToggleExpand(item.id),
                      onOpen: () => widget.onItemOpen(item),
                      onDelete: widget.onItemDelete != null
                          ? () => widget.onItemDelete!(item)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),

        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
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
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
                    ),
                  ),
                ),
                // Wood Grain Texture (Procedural)
                CustomPaint(
                  size: Size.infinite,
                  painter: WoodGrainPainter(color: Colors.white),
                ),
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
