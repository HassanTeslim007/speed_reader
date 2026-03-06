import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// RSVP (Rapid Serial Visual Presentation) settings
class RsvpSettings extends Equatable {
  final int wordsPerMinute;
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final Color highlightColor;
  final bool showFocusGuide;
  final bool highlightORP; // Optimal Recognition Point
  final int chunkSize; // Number of words to display at once

  const RsvpSettings({
    this.wordsPerMinute = 300,
    this.fontSize = 48.0,
    this.textColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.highlightColor = Colors.red,
    this.showFocusGuide = true,
    this.highlightORP = true,
    this.chunkSize = 1,
  });

  RsvpSettings copyWith({
    int? wordsPerMinute,
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    Color? highlightColor,
    bool? showFocusGuide,
    bool? highlightORP,
    int? chunkSize,
  }) {
    return RsvpSettings(
      wordsPerMinute: wordsPerMinute ?? this.wordsPerMinute,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      highlightColor: highlightColor ?? this.highlightColor,
      showFocusGuide: showFocusGuide ?? this.showFocusGuide,
      highlightORP: highlightORP ?? this.highlightORP,
      chunkSize: chunkSize ?? this.chunkSize,
    );
  }

  /// Get delay between chunks in milliseconds
  int get delayMs => (60000 / (wordsPerMinute / chunkSize)).round();

  @override
  List<Object?> get props => [
    wordsPerMinute,
    fontSize,
    textColor,
    backgroundColor,
    highlightColor,
    showFocusGuide,
    highlightORP,
    chunkSize,
  ];
}
