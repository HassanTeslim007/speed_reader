import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/features/pdf_viewer/providers/pdf_viewer_provider.dart';

/// PDF viewer controls widget
class PdfControls extends StatelessWidget {
  final PdfController controller;

  const PdfControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfViewerNotifier>(
      builder: (context, notifier, child) {
        final viewerState = notifier.state;

        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous page
                IconButton.filled(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: viewerState.currentPage > 1
                      ? () {
                          notifier.previousPage();
                          controller.previousPage(
                            duration: AppConstants.animationNormal,
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),

                // Page indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                    vertical: AppConstants.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  child: Text(
                    '${viewerState.currentPage} / ${viewerState.totalPages}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),

                // Next page
                IconButton.filled(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: viewerState.currentPage < viewerState.totalPages
                      ? () {
                          notifier.nextPage();
                          controller.nextPage(
                            duration: AppConstants.animationNormal,
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),

                // Fullscreen button
                IconButton.filled(
                  icon: Icon(
                    viewerState.isFullscreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                  ),
                  tooltip: viewerState.isFullscreen
                      ? 'Exit fullscreen'
                      : 'Fullscreen',
                  onPressed: () => notifier.toggleFullscreen(),
                ),

                // Zoom controls
                PopupMenuButton<double>(
                  icon: const Icon(Icons.zoom_in),
                  tooltip: 'Zoom',
                  onSelected: (zoom) {
                    notifier.setZoom(zoom);
                    // Note: pdfx doesn't support programmatic zoom
                    // This is stored for future use or custom implementation
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0.5, child: Text('50%')),
                    const PopupMenuItem(value: 0.75, child: Text('75%')),
                    const PopupMenuItem(value: 1.0, child: Text('100%')),
                    const PopupMenuItem(value: 1.25, child: Text('125%')),
                    const PopupMenuItem(value: 1.5, child: Text('150%')),
                    const PopupMenuItem(value: 2.0, child: Text('200%')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
