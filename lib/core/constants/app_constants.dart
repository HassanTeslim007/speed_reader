/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Speed Reader';
  static const String appVersion = '1.0.0';

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;

  // Icon Sizes
  static const double iconSizeSm = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyRecentFiles = 'recent_files';
  static const String keyReadingProgress = 'reading_progress_';

  // Supported File Extensions
  static const List<String> supportedExtensions = ['pdf'];
}
