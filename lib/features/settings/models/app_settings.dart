import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// App settings model
class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final bool autoSaveProgress;
  final bool showPageNumbers;
  final double defaultZoom;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.autoSaveProgress = true,
    this.showPageNumbers = true,
    this.defaultZoom = 1.0,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? autoSaveProgress,
    bool? showPageNumbers,
    double? defaultZoom,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      autoSaveProgress: autoSaveProgress ?? this.autoSaveProgress,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      defaultZoom: defaultZoom ?? this.defaultZoom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'autoSaveProgress': autoSaveProgress,
      'showPageNumbers': showPageNumbers,
      'defaultZoom': defaultZoom,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
      autoSaveProgress: json['autoSaveProgress'] as bool? ?? true,
      showPageNumbers: json['showPageNumbers'] as bool? ?? true,
      defaultZoom: (json['defaultZoom'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    autoSaveProgress,
    showPageNumbers,
    defaultZoom,
  ];
}
