import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:speed_reader/core/router/app_router.dart';
import 'package:speed_reader/core/widgets/common_widgets.dart';
import 'package:speed_reader/features/pdf_viewer/providers/pdf_viewer_provider.dart';
import 'package:speed_reader/features/pdf_viewer/providers/search_provider.dart';
import 'package:speed_reader/features/pdf_viewer/widgets/pdf_controls.dart';
import 'package:speed_reader/features/pdf_viewer/widgets/search_bar_widget.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion_pdf;
import 'package:speed_reader/features/bookmarks/providers/bookmark_provider.dart';
import 'package:speed_reader/features/bookmarks/widgets/bookmarks_drawer_widget.dart';

/// Isolate function for extracting text from PDF
/// Must be top-level or static to work with compute
Map<String, dynamic> _extractPdfTextIsolate(Map<String, dynamic> params) {
  try {
    final bytes = params['bytes'] as List<int>;
    final currentPage = params['currentPage'] as int;

    final pdfDocument = syncfusion_pdf.PdfDocument(inputBytes: bytes);
    final totalPages = pdfDocument.pages.count;

    final StringBuffer extractedText = StringBuffer();

    // Start from current page (pages are 0-indexed in syncfusion)
    for (int i = currentPage - 1; i < totalPages; i++) {
      final text = syncfusion_pdf.PdfTextExtractor(
        pdfDocument,
      ).extractText(startPageIndex: i, endPageIndex: i);

      if (text.isNotEmpty) {
        extractedText.writeln(text);
        extractedText.writeln(); // Add spacing between pages
      }
    }

    pdfDocument.dispose();

    return {'success': true, 'text': extractedText.toString().trim()};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

/// PDF Viewer Screen
class PdfViewerScreen extends StatefulWidget {
  final String? filePath;

  const PdfViewerScreen({super.key, this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PdfController? _pdfController;
  bool _isLoading = true;
  bool _isExtractingText = false;
  bool _isSearchVisible = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePdf();
  }

  Future<void> _initializePdf() async {
    if (widget.filePath == null) {
      setState(() {
        _error = 'No file selected';
        _isLoading = false;
      });
      return;
    }

    try {
      // PdfController expects a Future<PdfDocument>
      final controller = PdfController(
        document: PdfDocument.openFile(widget.filePath!),
      );

      // Wait for the document to load to get page count
      final document = await PdfDocument.openFile(widget.filePath!);

      setState(() {
        _pdfController = controller;
        _isLoading = false;
      });

      // Initialize the provider with document info and get saved page
      if (mounted) {
        final documentId = widget.filePath!.hashCode.toString();
        context.read<PdfViewerNotifier>().initialize(
          documentId,
          document.pagesCount,
        );

        // Load bookmarks
        context.read<BookmarkProvider>().loadBookmarks(documentId);

        // Jump to saved page after a short delay to ensure controller is ready
        final savedPage = context.read<PdfViewerNotifier>().state.currentPage;
        if (savedPage > 1) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _pdfController != null) {
              _pdfController!.jumpToPage(savedPage);
            }
          });
        }

        // Extract text for search functionality
        context.read<SearchProvider>().extractText(widget.filePath!);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load PDF: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  void _handleSwipe(DragEndDetails details, PdfViewerNotifier notifier) {
    final velocity = details.primaryVelocity ?? 0;

    // Swipe left (next page)
    if (velocity < -500) {
      if (notifier.state.currentPage < notifier.state.totalPages) {
        notifier.nextPage();
        _pdfController?.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    // Swipe right (previous page)
    else if (velocity > 500) {
      if (notifier.state.currentPage > 1) {
        notifier.previousPage();
        _pdfController?.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _launchRsvpMode(BuildContext context) async {
    // Show loading overlay
    setState(() {
      _isExtractingText = true;
    });

    // Give UI time to render the loading overlay
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Load PDF bytes
      final bytes = await File(widget.filePath!).readAsBytes();
      if (!context.mounted) return;
      final currentPage = context.read<PdfViewerNotifier>().state.currentPage;

      // Run text extraction in isolate to keep UI responsive
      final result = await compute(_extractPdfTextIsolate, {
        'bytes': bytes,
        'currentPage': currentPage,
      });

      // Hide loading overlay
      if (mounted) {
        setState(() {
          _isExtractingText = false;
        });
      }

      // Check result
      if (result['success'] != true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error extracting text: ${result['error']}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final finalText = result['text'] as String;

      if (finalText.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No text found in PDF from current page'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Navigate to RSVP screen with extracted text
      if (context.mounted) {
        context.push(AppRouter.rsvp, extra: finalText);
      }
    } catch (e) {
      // Hide loading overlay
      if (mounted) {
        setState(() {
          _isExtractingText = false;
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting text: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget(message: 'Loading PDF...'));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('PDF Viewer')),
        body: AppErrorWidget(
          message: _error!,
          onRetry: () {
            setState(() {
              _isLoading = true;
              _error = null;
            });
            _initializePdf();
          },
        ),
      );
    }

    if (_pdfController == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('PDF Viewer')),
        body: const EmptyStateWidget(
          icon: Icons.picture_as_pdf,
          title: 'No PDF loaded',
          subtitle: 'Please select a PDF file to view',
        ),
      );
    }

    return Consumer<PdfViewerNotifier>(
      builder: (context, notifier, child) {
        final viewerState = notifier.state;

        // Fullscreen mode
        if (viewerState.isFullscreen) {
          // Hide system UI in fullscreen
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

          return Scaffold(
            backgroundColor: Colors.black,
            body: GestureDetector(
              onHorizontalDragEnd: (details) => _handleSwipe(details, notifier),
              onTap: () {
                // Exit fullscreen on tap
                notifier.toggleFullscreen();
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              },
              child: Stack(
                children: [
                  // PDF View
                  Center(
                    child: PdfView(
                      controller: _pdfController!,
                      onPageChanged: (page) {
                        notifier.setCurrentPage(page);
                      },
                    ),
                  ),

                  // Page indicator overlay
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${viewerState.currentPage} / ${viewerState.totalPages}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Swipe hint (show briefly)
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Swipe to navigate • Tap to exit',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Normal mode
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

        return Stack(
          children: [
            Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Text(
                  'Page ${viewerState.currentPage} of ${viewerState.totalPages}',
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearchVisible = !_isSearchVisible;
                      });

                      // Navigate to current match if search is active
                      if (_isSearchVisible) {
                        final searchProvider = context.read<SearchProvider>();
                        final currentMatch = searchProvider.state.currentMatch;
                        if (currentMatch != null) {
                          _pdfController?.jumpToPage(currentMatch.pageNumber);
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.speed),
                    tooltip: 'Speed Reader (RSVP)',
                    onPressed: () => _launchRsvpMode(context),
                  ),
                  Consumer<BookmarkProvider>(
                    builder: (context, bookmarkProvider, child) {
                      final documentId = widget.filePath!.hashCode.toString();
                      final isBookmarked = bookmarkProvider.isPageBookmarked(
                        viewerState.currentPage,
                      );

                      return IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        tooltip: isBookmarked
                            ? 'Remove Bookmark'
                            : 'Add Bookmark',
                        onPressed: () => bookmarkProvider.toggleBookmark(
                          documentId,
                          viewerState.currentPage,
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.bookmarks_outlined),
                      tooltip: 'View Bookmarks',
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ),
                ],
              ),
              body: Consumer<SearchProvider>(
                builder: (context, searchProvider, child) {
                  // Navigate to page when match changes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final currentMatch = searchProvider.state.currentMatch;
                    if (currentMatch != null && _pdfController != null) {
                      _pdfController!.jumpToPage(currentMatch.pageNumber);
                    }
                  });

                  return Stack(
                    children: [
                      // Main PDF viewer
                      GestureDetector(
                        onHorizontalDragEnd: (details) =>
                            _handleSwipe(details, notifier),
                        child: Stack(
                          children: [
                            PdfView(
                              controller: _pdfController!,
                              onPageChanged: (page) {
                                notifier.setCurrentPage(page);
                              },
                            ),

                            // Floating Search bar
                            if (_isSearchVisible)
                              Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top:
                                        MediaQuery.of(context).padding.top +
                                        kToolbarHeight +
                                        8,
                                  ),
                                  child: SearchBarWidget(
                                    onClose: () {
                                      setState(() {
                                        _isSearchVisible = false;
                                      });
                                    },
                                  ),
                                ),
                              ),

                            // Floating PDF Controls
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: PdfControls(controller: _pdfController!),
                            ),
                          ],
                        ),
                      ),

                      // Loading overlay - stacked on top when extracting text
                      if (_isExtractingText)
                        Container(
                          color: Colors.black.withValues(alpha: 0.8),
                          child: Center(
                            child: Card(
                              margin: const EdgeInsets.all(16.0),
                              elevation: 8,
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SpinKitCircle(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Extracting text from PDF...',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              endDrawer: BookmarksDrawerWidget(
                documentId: widget.filePath!.hashCode.toString(),
                onJumpToPage: (page) {
                  _pdfController?.jumpToPage(page);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
