import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium glassmorphic container with blur effect.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final BoxBorder? boxBorder;
  final List<BoxShadow>? shadows;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.opacity = 0.1,
    this.borderRadius = 24.0,
    this.color,
    this.padding,
    this.margin,
    this.border,
    this.boxBorder,
    this.shadows,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassColor =
        color ??
        (theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: opacity)
            : Colors.black.withValues(alpha: opacity));

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border:
                  boxBorder ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1.0,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
