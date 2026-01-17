import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_reader/core/router/app_router.dart';
import 'package:speed_reader/core/theme/app_theme.dart';
import 'package:speed_reader/features/library/providers/library_provider.dart';
import 'package:speed_reader/features/library/repositories/library_repository.dart';
import 'package:speed_reader/features/pdf_viewer/providers/pdf_viewer_provider.dart';
import 'package:speed_reader/features/pdf_viewer/providers/search_provider.dart';
import 'package:speed_reader/features/pdf_viewer/repositories/pdf_repository.dart';
import 'package:speed_reader/features/settings/providers/settings_provider.dart';
import 'package:speed_reader/features/settings/repositories/settings_repository.dart';
import 'package:speed_reader/features/speed_reader/providers/rsvp_provider.dart';
import 'package:speed_reader/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:speed_reader/features/bookmarks/providers/bookmark_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(MainApp(sharedPreferences: sharedPreferences));
}

class MainApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const MainApp({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositories
        Provider<PdfRepository>(
          create: (_) => PdfRepository(sharedPreferences),
        ),
        Provider<LibraryRepository>(
          create: (_) => LibraryRepository(sharedPreferences),
        ),
        Provider<SettingsRepository>(
          create: (_) => SettingsRepository(sharedPreferences),
        ),
        Provider<BookmarkRepository>(
          create: (_) => BookmarkRepository(sharedPreferences),
        ),

        // Notifiers
        ChangeNotifierProvider<PdfViewerNotifier>(
          create: (context) => PdfViewerNotifier(context.read<PdfRepository>()),
        ),
        ChangeNotifierProvider<LibraryNotifier>(
          create: (context) =>
              LibraryNotifier(context.read<LibraryRepository>()),
        ),
        ChangeNotifierProvider<SettingsNotifier>(
          create: (context) =>
              SettingsNotifier(context.read<SettingsRepository>()),
        ),
        ChangeNotifierProvider<RsvpProvider>(create: (_) => RsvpProvider()),
        ChangeNotifierProvider<SearchProvider>(create: (_) => SearchProvider()),
        ChangeNotifierProvider<BookmarkProvider>(
          create: (context) =>
              BookmarkProvider(context.read<BookmarkRepository>()),
        ),
      ],
      child: Consumer<SettingsNotifier>(
        builder: (context, settingsNotifier, child) {
          return MaterialApp.router(
            title: 'Speed Reader',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsNotifier.state.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
