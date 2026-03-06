import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speed_reader/core/router/app_router.dart';
import 'package:speed_reader/core/widgets/common_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.speed),
            tooltip: 'Speed Reader (RSVP)',
            onPressed: () {
              if (_content.isNotEmpty) {
                context.push(AppRouter.rsvp, extra: _content);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No text available for RSVP.')),
                );
              }
            },
          ),
        ],
      ),
      body: Scrollbar(
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
    );
  }
}
