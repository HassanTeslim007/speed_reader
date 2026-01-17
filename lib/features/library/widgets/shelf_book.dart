import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speed_reader/core/widgets/pattern_painters.dart';
import 'package:speed_reader/features/library/models/library_item.dart';

/// A premium widget that represents a book on a shelf.
/// It shows the spine by default and expands to show the cover when isExpanded is true.
class ShelfBook extends StatefulWidget {
  final LibraryItem item;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  const ShelfBook({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onOpen,
    this.onDelete,
  });

  @override
  State<ShelfBook> createState() => _ShelfBookState();
}

class _ShelfBookState extends State<ShelfBook>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Color _spineColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }

    final random = math.Random(widget.item.id.hashCode);
    _spineColor = Colors.primaries[random.nextInt(Colors.primaries.length)];
  }

  @override
  void didUpdateWidget(ShelfBook oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double spineWidth = 42.0;
    const double coverWidth = 160.0;
    const double height = 210.0;

    return GestureDetector(
      onTap: () {
        if (!widget.isExpanded) {
          widget.onToggleExpand();
        } else {
          widget.onOpen();
        }
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final currentWidth =
              spineWidth + (coverWidth - spineWidth) * _animation.value;

          return Container(
            width: currentWidth,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Stack(
              children: [
                // The Front Cover (visible when expanded)
                if (_animation.value > 0)
                  Positioned(
                    left: spineWidth * (1 - _animation.value),
                    child: Opacity(
                      opacity: _animation.value,
                      child: Container(
                        width: coverWidth,
                        height: height,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(4, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            widget.item.thumbnailPath != null &&
                                    File(
                                      widget.item.thumbnailPath!,
                                    ).existsSync()
                                ? Image.file(
                                    File(widget.item.thumbnailPath!),
                                    fit: BoxFit.cover,
                                    width: coverWidth,
                                    height: height,
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.picture_as_pdf,
                                      size: 48,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                            Container(
                              width: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                      topLeft: const Radius.circular(6),
                      bottomLeft: const Radius.circular(6),
                      topRight: Radius.circular(6 * (1 - _animation.value)),
                      bottomRight: Radius.circular(6 * (1 - _animation.value)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(2, 4),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _spineColor.withValues(alpha: 0.8),
                        _spineColor,
                        _spineColor.withValues(alpha: 0.9),
                        _spineColor.withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Texture Overlay (Procedural)
                      CustomPaint(
                        size: Size.infinite,
                        painter: LeatherPainter(color: Colors.white),
                      ),
                      Center(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              widget.item.fileName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                                overflow: TextOverflow.ellipsis,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                      _buildSpineLine(top: 25),
                      _buildSpineLine(bottom: 25),
                    ],
                  ),
                ),

                if (_animation.value > 0.8) ...[
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _CircleIconButton(
                      icon: Icons.close,
                      onTap: widget.onToggleExpand,
                    ),
                  ),
                  if (widget.onDelete != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _CircleIconButton(
                        icon: Icons.delete_outline,
                        onTap: widget.onDelete!,
                        color: Colors.redAccent,
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpineLine({double? top, double? bottom}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: 0,
      right: 0,
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.3),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color ?? Colors.white),
      ),
    );
  }
}
