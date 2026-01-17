import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speed_reader/features/speed_reader/models/rsvp_settings.dart';

/// RSVP playback state
enum RsvpPlaybackState { stopped, playing, paused }

/// RSVP provider for managing speed reading mode
class RsvpProvider extends ChangeNotifier {
  RsvpSettings _settings = const RsvpSettings();
  RsvpPlaybackState _playbackState = RsvpPlaybackState.stopped;
  List<String> _words = [];
  int _currentWordIndex = 0;
  Timer? _timer;

  RsvpSettings get settings => _settings;
  RsvpPlaybackState get playbackState => _playbackState;
  List<String> get words => _words;
  int get currentWordIndex => _currentWordIndex;
  String get currentWord => _words.isEmpty ? '' : _words[_currentWordIndex];
  int get totalWords => _words.length;
  double get progress =>
      _words.isEmpty ? 0.0 : _currentWordIndex / _words.length;

  /// Load text for RSVP reading
  void loadText(String text) {
    stop();
    _words = _splitIntoWords(text);
    _currentWordIndex = 0;
    notifyListeners();
  }

  /// Split text into words
  List<String> _splitIntoWords(String text) {
    // Remove extra whitespace and split by spaces
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Start or resume playback
  void play() {
    if (_words.isEmpty) return;

    _playbackState = RsvpPlaybackState.playing;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: _settings.delayMs),
      (_) => _nextWord(),
    );
  }

  /// Pause playback
  void pause() {
    _timer?.cancel();
    _playbackState = RsvpPlaybackState.paused;
    notifyListeners();
  }

  /// Stop playback and reset
  void stop() {
    _timer?.cancel();
    _playbackState = RsvpPlaybackState.stopped;
    _currentWordIndex = 0;
    notifyListeners();
  }

  /// Move to next word
  void _nextWord() {
    if (_currentWordIndex < _words.length - 1) {
      _currentWordIndex++;
      notifyListeners();
    } else {
      // Reached end
      stop();
    }
  }

  /// Jump to specific word index
  void jumpToWord(int index) {
    if (index >= 0 && index < _words.length) {
      _currentWordIndex = index;
      notifyListeners();
    }
  }

  /// Update settings
  void updateSettings(RsvpSettings newSettings) {
    final wasPlaying = _playbackState == RsvpPlaybackState.playing;

    if (wasPlaying) {
      pause();
    }

    _settings = newSettings;
    notifyListeners();

    if (wasPlaying) {
      play();
    }
  }

  /// Update WPM
  void updateWpm(int wpm) {
    updateSettings(_settings.copyWith(wordsPerMinute: wpm));
  }

  /// Update font size
  void updateFontSize(double size) {
    updateSettings(_settings.copyWith(fontSize: size));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
