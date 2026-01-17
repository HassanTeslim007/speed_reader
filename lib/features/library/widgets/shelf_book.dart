import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speed_reader/features/library/models/library_item.dart';

/// A widget that represents a book on a shelf.
/// It shows the spine by default and expands to show the cover on tap.
class ShelfBook extends StatefulWidget {
  final LibraryItem item;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  const ShelfBook({
    super.key,
    required this.item,
    required this.onOpen,
    this.onDelete,
  });

  @override
  State<ShelfBook> createState() => _ShelfBookState();
}

class _ShelfBookState extends State<ShelfBook>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  // A random color for the spine if one isn't provided
  late Color _spineColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    // Generate a consistent color based on the item id
    final random = math.Random(widget.item.id.hashCode);
    _spineColor = Colors.primaries[random.nextInt(Colors.primaries.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_isExpanded) {
          _toggleExpand();
        } else {
          widget.onOpen();
        }
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Calculate dimensions
          const double spineWidth = 40.0;
          const double coverWidth = 160.0;
          const double height = 200.0;

          final currentWidth =
              spineWidth + (coverWidth - spineWidth) * _animation.value;

          return Container(
            width: currentWidth,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // The Front Cover (visible when expanded)
                if (_animation.value > 0)
                  Opacity(
                    opacity: _animation.value,
                    child: Container(
                      width: coverWidth,
                      height: height,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          widget.item.thumbnailPath != null &&
                              File(widget.item.thumbnailPath!).existsSync()
                          ? Image.file(
                              File(widget.item.thumbnailPath!),
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Icon(
                                Icons.picture_as_pdf,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                    ),
                  ),

                // The Spine
                Container(
                  width: spineWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: _spineColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(4),
                      bottomLeft: const Radius.circular(4),
                      topRight: Radius.circular(4 * (1 - _animation.value)),
                      bottomRight: Radius.circular(4 * (1 - _animation.value)),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _spineColor,
                        _spineColor.withValues(alpha: 0.8),
                        _spineColor,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Vertical text
                      Center(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              widget.item.fileName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                      // Decorative lines
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Close button (only when expanded)
                if (_isExpanded)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        _toggleExpand();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Delete button
                if (_isExpanded && widget.onDelete != null)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                      onPressed: widget.onDelete,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                        padding: const EdgeInsets.all(4),
                      ),
                      constraints: const BoxConstraints(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
