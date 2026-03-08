import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
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

/// TTS playback state
enum TtsState { stopped, loading, playing, paused }

/// Isolate function for extracting text from PDF
/// Must be top-level or static to work with compute
Map<String, dynamic> _extractPdfTextIsolate(Map<String, dynamic> params) {
  try {
    final bytes = params['bytes'] as List<int>;
    final currentPage = params['currentPage'] as int;
    final endPage = params['endPage'] as int?;

    final pdfDocument = syncfusion_pdf.PdfDocument(inputBytes: bytes);
    final totalPages = pdfDocument.pages.count;

    // Use current page as end page if endPage is null (for single page extraction)
    // or clamp it to total pages.
    final finalEndPage = (endPage ?? totalPages).clamp(1, totalPages);

    final StringBuffer extractedText = StringBuffer();

    // Start from current page (pages are 0-indexed in syncfusion)
    for (int i = currentPage - 1; i < finalEndPage; i++) {
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

  // TTS
  final FlutterTts _tts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  bool _isFabExpanded = false;
  int _currentWordOffset = 0;
  String _lastExtractedText = '';

  @override
  void initState() {
    super.initState();
    _initTts();
    _initializePdf();
  }

  Future<void> _initTts() async {
    // Basic settings
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Audio category for iOS/Android to play nicely with other apps
    if (!kIsWeb) {
      if (Platform.isIOS) {
        await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ]);
      }
    }

    _tts.setStartHandler(() {
      if (mounted) setState(() => _ttsState = TtsState.playing);
    });

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _ttsState = TtsState.stopped;
          _currentWordOffset = 0;
        });
      }
    });

    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _ttsState = TtsState.stopped;
          _currentWordOffset = 0;
        });
      }
    });

    _tts.setPauseHandler(() {
      if (mounted) setState(() => _ttsState = TtsState.paused);
    });

    _tts.setContinueHandler(() {
      if (mounted) setState(() => _ttsState = TtsState.playing);
    });

    _tts.setProgressHandler((text, start, end, word) {
      _currentWordOffset = start;
    });

    _tts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _ttsState = TtsState.stopped;
          _currentWordOffset = 0;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('TTS error: $msg')));
      }
    });
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
      final file = File(widget.filePath!);
      if (!await file.exists()) {
        setState(() {
          _error =
              'The file could not be found. It may have been moved or deleted.';
          _isLoading = false;
        });
        return;
      }

      // Open the document once and reuse the future
      final documentFuture = PdfDocument.openFile(widget.filePath!);

      final controller = PdfController(document: documentFuture);

      // Wait for the same future to get metadata
      final document = await documentFuture;

      setState(() {
        _pdfController = controller;
        _isLoading = false;
      });

      // Initialize the provider with document info and get saved page
      if (mounted) {
        // Use the filename (stable GUID in library) as the document ID
        // instead of the absolute path hash, which changes on iOS/macOS.
        final documentId = p.basename(widget.filePath!);
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
    _tts.stop();
    super.dispose();
  }

  /// Toggle or start TTS for the current page
  Future<void> _toggleTts() async {
    switch (_ttsState) {
      case TtsState.playing:
        await _pauseTts();
        break;
      case TtsState.paused:
        await _resumeSpeak();
        break;
      case TtsState.stopped:
        await _startSpeak();
        break;
      case TtsState.loading:
        // Do nothing if already loading
        break;
    }
  }

  Future<void> _startSpeak() async {
    setState(() {
      _ttsState = TtsState.loading;
      _currentWordOffset = 0;
    });

    try {
      final bytes = await File(widget.filePath!).readAsBytes();
      if (!mounted) return;

      final currentPage = context.read<PdfViewerNotifier>().state.currentPage;

      // Extract only the current page for TTS
      final result = await compute(_extractPdfTextIsolate, {
        'bytes': bytes,
        'currentPage': currentPage,
        'endPage': currentPage,
      });

      if (!mounted) return;

      if (result['success'] != true || (result['text'] as String).isEmpty) {
        setState(() => _ttsState = TtsState.stopped);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No readable text found on this page.')),
        );
        return;
      }

      _lastExtractedText = result['text'] as String;
      final speakResult = await _tts.speak(_lastExtractedText);
      if (speakResult == 1) {
        setState(() => _ttsState = TtsState.playing);
      } else {
        setState(() => _ttsState = TtsState.stopped);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _ttsState = TtsState.stopped);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _resumeSpeak() async {
    if (_lastExtractedText.isEmpty) {
      await _startSpeak();
      return;
    }

    if (Platform.isIOS) {
      // iOS has native continueSpeak
      final result = await _tts.speak(
        _lastExtractedText,
      ); // or use internal state
      if (result == 1) setState(() => _ttsState = TtsState.playing);
    } else {
      // Android: resume by speaking the remaining text
      final remainingText = _lastExtractedText.substring(_currentWordOffset);
      final result = await _tts.speak(remainingText);
      if (result == 1) setState(() => _ttsState = TtsState.playing);
    }
  }

  Future<void> _stopTts() async {
    await _tts.stop();
    if (mounted) {
      setState(() {
        _ttsState = TtsState.stopped;
        _currentWordOffset = 0;
      });
    }
  }

  Future<void> _pauseTts() async {
    await _tts.pause();
    if (mounted) setState(() => _ttsState = TtsState.paused);
  }

  // Obsolete helper removed

  void _showJumpToPageDialog(
    BuildContext context,
    int currentPage,
    int totalPages,
  ) {
    final controller = TextEditingController(text: currentPage.toString());
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Go to page'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '1 – $totalPages',
              border: const OutlineInputBorder(),
              suffixText: '/ $totalPages',
            ),
            onSubmitted: (_) =>
                _submitJump(dialogContext, controller, totalPages),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  _submitJump(dialogContext, controller, totalPages),
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  void _submitJump(
    BuildContext dialogContext,
    TextEditingController controller,
    int totalPages,
  ) {
    final page = int.tryParse(controller.text.trim());
    if (page == null || page < 1 || page > totalPages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a page number between 1 and $totalPages'),
        ),
      );
      return;
    }
    Navigator.pop(dialogContext);
    _pdfController?.jumpToPage(page);
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
      _ttsState = TtsState.stopped;
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

                  // Page indicator overlay (tap to jump)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _showJumpToPageDialog(
                          context,
                          viewerState.currentPage,
                          viewerState.totalPages,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${viewerState.currentPage} / ${viewerState.totalPages}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.edit,
                                color: Colors.white70,
                                size: 14,
                              ),
                            ],
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
                title: GestureDetector(
                  onTap: () => _showJumpToPageDialog(
                    context,
                    viewerState.currentPage,
                    viewerState.totalPages,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Page ${viewerState.currentPage} of ${viewerState.totalPages}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 14),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () =>
                        setState(() => _isSearchVisible = !_isSearchVisible),
                  ),
                  Consumer<BookmarkProvider>(
                    builder: (context, bookmarkProvider, child) {
                      final documentId = p.basename(widget.filePath!);
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

                            // Media Center Controls for TTS
                            if (_ttsState != TtsState.stopped)
                              _buildMediaControls(context),

                            // Floating PDF Controls (Only if TTS is not taking over the space)
                            if (_ttsState == TtsState.stopped)
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
                documentId: p.basename(widget.filePath!),
                onJumpToPage: (page) {
                  _pdfController?.jumpToPage(page);
                },
              ),
              floatingActionButton: _buildExpandableFab(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpandableFab(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isFabExpanded) ...[
          FloatingActionButton.small(
            heroTag: 'tts_fab',
            onPressed: () {
              setState(() => _isFabExpanded = false);
              _toggleTts();
            },
            child: Icon(
              _ttsState == TtsState.playing ? Icons.pause : Icons.volume_up,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'rsvp_fab',
            onPressed: () {
              setState(() => _isFabExpanded = false);
              _launchRsvpMode(context);
            },
            child: const Icon(Icons.speed),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 300),
            turns: _isFabExpanded ? 0.375 : 0, // Rotate like an 'x'
            child: const Icon(Icons.extension, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaControls(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.stop_rounded),
              onPressed: _stopTts,
              color: Colors.redAccent,
              tooltip: 'Stop Reading',
            ),
            const SizedBox(width: 12),
            if (_ttsState == TtsState.loading)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              IconButton(
                iconSize: 36,
                icon: Icon(
                  _ttsState == TtsState.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                onPressed: _toggleTts,
                color: Theme.of(context).colorScheme.primary,
                tooltip: _ttsState == TtsState.playing ? 'Pause' : 'Resume',
              ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ttsState == TtsState.playing ? 'Reading Aloud' : 'Paused',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Page ${context.read<PdfViewerNotifier>().state.currentPage}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: _stopTts,
              tooltip: 'Dismiss Controls',
            ),
          ],
        ),
      ),
    );
  }
}
