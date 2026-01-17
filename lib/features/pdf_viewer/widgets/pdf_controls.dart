import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/core/widgets/glass_container.dart';
import 'package:speed_reader/features/pdf_viewer/providers/pdf_viewer_provider.dart';

/// Premium floating PDF viewer controls
class PdfControls extends StatelessWidget {
  final PdfController controller;

  const PdfControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfViewerNotifier>(
      builder: (context, notifier, child) {
        final viewerState = notifier.state;
        final theme = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
          child: GlassContainer(
            padding: const EdgeInsets.all(12),
            borderRadius: 32,
            opacity: theme.brightness == Brightness.dark ? 0.2 : 0.4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous page
                _ControlButton(
                  icon: Icons.chevron_left,
                  onPressed: viewerState.currentPage > 1
                      ? () {
                          notifier.previousPage();
                          controller.previousPage(
                            duration: AppConstants.animationNormal,
                            curve: Curves.easeInOutCubic,
                          );
                        }
                      : null,
                ),

                const SizedBox(width: 12),

                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${viewerState.currentPage} / ${viewerState.totalPages}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Next page
                _ControlButton(
                  icon: Icons.chevron_right,
                  onPressed: viewerState.currentPage < viewerState.totalPages
                      ? () {
                          notifier.nextPage();
                          controller.nextPage(
                            duration: AppConstants.animationNormal,
                            curve: Curves.easeInOutCubic,
                          );
                        }
                      : null,
                ),

                const SizedBox(width: 8),
                Container(
                  height: 24,
                  width: 1,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                const SizedBox(width: 8),

                // Fullscreen
                _ControlButton(
                  icon: viewerState.isFullscreen
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  onPressed: () => notifier.toggleFullscreen(),
                  isHighlighted: viewerState.isFullscreen,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isHighlighted;

  const _ControlButton({
    required this.icon,
    this.onPressed,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHighlighted
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isEnabled
                ? (isHighlighted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface)
                : theme.disabledColor,
          ),
        ),
      ),
    );
  }
}
