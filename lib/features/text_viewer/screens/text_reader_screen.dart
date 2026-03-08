import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speed_reader/core/router/app_router.dart';
import 'package:speed_reader/core/widgets/common_widgets.dart';

/// TTS playback state
enum TtsState { stopped, loading, playing, paused }

class TextReaderScreen extends StatefulWidget {
  final String? filePath;

  const TextReaderScreen({super.key, this.filePath});

  @override
  State<TextReaderScreen> createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends State<TextReaderScreen> {
  String _content = '';
  bool _isLoading = true;
  String? _error;

  final ScrollController _scrollController = ScrollController();

  // TTS
  final FlutterTts _tts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  bool _isFabExpanded = false;
  int _currentWordOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadFile();
    _initTts();
  }

  Future<void> _initTts() async {
    // Basic settings
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Audio category for iOS/Android
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

  @override
  void dispose() {
    _scrollController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadFile() async {
    if (widget.filePath == null) {
      setState(() {
        _error = 'No file provided.';
        _isLoading = false;
      });
      return;
    }

    try {
      final file = File(widget.filePath!);
      if (!await file.exists()) {
        setState(() {
          _error = 'File not found.';
          _isLoading = false;
        });
        return;
      }

      String text = await file.readAsString();
      final ext = widget.filePath!.split('.').last.toLowerCase();
      if (ext == 'html') {
        text = text.replaceAll(RegExp(r'<[^>]*>', multiLine: true), ' ');
        text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      }

      setState(() {
        _content = text;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading file: $e';
        _isLoading = false;
      });
    }
  }

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
        break;
    }
  }

  Future<void> _startSpeak() async {
    if (_content.isEmpty) return;
    setState(() {
      _ttsState = TtsState.loading;
      _currentWordOffset = 0;
    });

    try {
      final result = await _tts.speak(_content);
      if (result == 1) {
        setState(() => _ttsState = TtsState.playing);
      } else {
        setState(() => _ttsState = TtsState.stopped);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _ttsState = TtsState.stopped);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start TTS: $e')));
      }
    }
  }

  Future<void> _resumeSpeak() async {
    if (Platform.isIOS) {
      final result = await _tts.speak(_content);
      if (result == 1) setState(() => _ttsState = TtsState.playing);
    } else {
      final remainingText = _content.substring(_currentWordOffset);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget(message: 'Loading text...'));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Text Reader')),
        body: AppErrorWidget(
          message: _error!,
          onRetry: () {
            setState(() {
              _isLoading = true;
              _error = null;
            });
            _loadFile();
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.filePath!
              .split('/')
              .last
              .replaceAll(RegExp(r'\.(txt|html)$'), '')
              .replaceAll('_', ' '),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Use the FAB below for reading controls.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Scrollbar(
            controller: _scrollController,
            interactive: true,
            thumbVisibility: true,
            thickness: 8.0,
            radius: const Radius.circular(4),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _content,
                style: const TextStyle(fontSize: 16.0, height: 1.5),
              ),
            ),
          ),
          if (_ttsState != TtsState.stopped) _buildMediaControls(context),
        ],
      ),
      floatingActionButton: _buildExpandableFab(context),
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
              if (_content.isNotEmpty) {
                context.push(AppRouter.rsvp, extra: _content);
              }
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
            turns: _isFabExpanded ? 0.375 : 0,
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _ttsState == TtsState.playing ? 'Reading Aloud' : 'Paused',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
