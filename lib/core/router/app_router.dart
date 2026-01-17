import 'package:go_router/go_router.dart';
import 'package:speed_reader/features/library/screens/library_screen.dart';
import 'package:speed_reader/features/pdf_viewer/screens/pdf_viewer_screen.dart';
import 'package:speed_reader/features/settings/screens/settings_screen.dart';
import 'package:speed_reader/features/speed_reader/screens/rsvp_screen.dart';

/// App routing configuration
class AppRouter {
  AppRouter._();

  // Route paths
  static const String library = '/';
  static const String pdfViewer = '/pdf-viewer';
  static const String settings = '/settings';
  static const String rsvp = '/rsvp';

  // Router configuration
  static final router = GoRouter(
    initialLocation: library,
    routes: [
      GoRoute(
        path: library,
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: pdfViewer,
        name: 'pdf-viewer',
        builder: (context, state) {
          final filePath = state.extra as String?;
          return PdfViewerScreen(filePath: filePath);
        },
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: rsvp,
        name: 'rsvp',
        builder: (context, state) {
          final text = state.extra as String?;
          return RsvpScreen(initialText: text);
        },
      ),
    ],
  );
}
