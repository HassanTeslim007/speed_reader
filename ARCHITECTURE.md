# Speed Reader - Architecture Documentation

## Overview

Speed Reader is a Flutter PDF reader application built with a **minimalist, feature-first architecture**. The architecture emphasizes clean separation of concerns, scalability, and maintainability while keeping the codebase simple and easy to understand.

## Architecture Principles

### 1. Feature-First Organization
- Code is organized by features rather than technical layers
- Each feature is self-contained with its own models, repositories, providers, screens, and widgets
- Makes it easy to locate and modify feature-specific code

### 2. Separation of Concerns
- **Models**: Data structures and business entities
- **Repositories**: Data access and persistence logic
- **Providers**: State management and business logic
- **Screens**: Full-page UI components
- **Widgets**: Reusable UI components

### 3. Dependency Inversion
- Core business logic is independent of frameworks
- Repositories define interfaces that can be easily swapped
- Makes testing and maintenance easier

### 4. Minimalist Approach
- Only add what's needed
- Avoid over-engineering
- Keep dependencies minimal
- Prioritize readability and simplicity

## Project Structure

```
lib/
├── core/                          # Shared utilities and configuration
│   ├── constants/
│   │   └── app_constants.dart    # App-wide constants
│   ├── theme/
│   │   └── app_theme.dart        # Theme configuration
│   ├── router/
│   │   └── app_router.dart       # Navigation setup
│   ├── utils/
│   │   └── file_utils.dart       # File utilities
│   └── widgets/
│       └── common_widgets.dart   # Reusable widgets
│
├── features/                      # Feature modules
│   ├── pdf_viewer/               # PDF viewing feature
│   │   ├── models/
│   │   │   ├── pdf_document.dart
│   │   │   └── reading_progress.dart
│   │   ├── repositories/
│   │   │   └── pdf_repository.dart
│   │   ├── providers/
│   │   │   └── pdf_viewer_provider.dart
│   │   ├── screens/
│   │   │   └── pdf_viewer_screen.dart
│   │   └── widgets/
│   │       └── pdf_controls.dart
│   │
│   ├── library/                  # Library/bookshelf feature
│   │   ├── models/
│   │   │   └── library_item.dart
│   │   ├── repositories/
│   │   │   └── library_repository.dart
│   │   ├── providers/
│   │   │   └── library_provider.dart
│   │   ├── screens/
│   │   │   └── library_screen.dart
│   │   └── widgets/
│   │       └── library_grid.dart
│   │
│   └── settings/                 # Settings feature
│       ├── models/
│       │   └── app_settings.dart
│       ├── repositories/
│       │   └── settings_repository.dart
│       ├── providers/
│       │   └── settings_provider.dart
│       └── screens/
│           └── settings_screen.dart
│
└── main.dart                     # App entry point
```

## Technology Stack

### Core Dependencies
- **flutter_riverpod** (^2.6.1) - State management
  - Lightweight and powerful
  - Compile-time safety
  - Easy testing
  - Automatic disposal

- **go_router** (^14.6.2) - Navigation
  - Declarative routing
  - Deep linking support
  - Type-safe navigation

- **pdfx** (^2.7.0) - PDF rendering
  - Fast rendering
  - Page navigation
  - Zoom support

- **file_picker** (^8.1.4) - File selection
  - Cross-platform file picking
  - Type filtering

- **shared_preferences** (^2.3.3) - Local storage
  - Simple key-value storage
  - Perfect for settings and metadata

- **equatable** (^2.0.7) - Value equality
  - Simplifies model comparison
  - Reduces boilerplate

## Key Features

### Current Features

1. **PDF Library Management**
   - Add PDFs from device storage
   - View all PDFs in a grid layout
   - Remove PDFs from library
   - Automatic metadata extraction

2. **PDF Viewing**
   - Smooth page navigation
   - Page controls (next, previous, jump to page)
   - Reading progress tracking
   - Auto-save last read position

3. **Settings**
   - Theme selection (Light/Dark/System)
   - Auto-save progress toggle
   - Page number display toggle
   - Settings persistence

### Planned Advanced Features

The architecture is designed to easily support:

1. **Bookmarks & Annotations**
   - Add bookmarks to important pages
   - Create text annotations
   - Highlight text

2. **Text Search**
   - Search within PDF documents
   - Navigate between search results

3. **Speed Reading Mode**
   - RSVP (Rapid Serial Visual Presentation)
   - Adjustable reading speed
   - Focus mode

4. **Text-to-Speech**
   - Audio narration of PDF content
   - Playback controls

5. **Collections/Categories**
   - Organize PDFs into custom collections
   - Tag-based organization

6. **Cloud Sync**
   - Sync library across devices
   - Cloud backup of reading progress

## State Management

### Riverpod Architecture

The app uses Riverpod for state management with the following pattern:

```dart
// 1. Repository Provider (data access)
final repositoryProvider = Provider<Repository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return Repository(prefs);
});

// 2. State Notifier (business logic)
class FeatureNotifier extends StateNotifier<FeatureState> {
  final Repository _repository;
  
  FeatureNotifier(this._repository) : super(initialState);
  
  // Business logic methods
}

// 3. State Notifier Provider (exposed to UI)
final featureProvider = 
    StateNotifierProvider<FeatureNotifier, FeatureState>((ref) {
  final repository = ref.watch(repositoryProvider);
  return FeatureNotifier(repository);
});
```

### Benefits
- Clear separation between data access and business logic
- Automatic dependency injection
- Easy testing (mock repositories)
- Automatic disposal of resources

## Navigation

### go_router Configuration

Routes are defined in `core/router/app_router.dart`:

```dart
static final router = GoRouter(
  initialLocation: library,
  routes: [
    GoRoute(path: '/', builder: (context, state) => LibraryScreen()),
    GoRoute(path: '/pdf-viewer', builder: (context, state) => PdfViewerScreen()),
    GoRoute(path: '/settings', builder: (context, state) => SettingsScreen()),
  ],
);
```

### Navigation Usage

```dart
// Navigate to a route
context.push('/pdf-viewer', extra: filePath);

// Go back
context.pop();
```

## Data Persistence

### SharedPreferences Strategy

The app uses SharedPreferences for:
- App settings (theme, preferences)
- Library metadata (file paths, page counts)
- Reading progress (current page per document)

### Data Models

All models implement:
- `toJson()` - Serialize to JSON
- `fromJson()` - Deserialize from JSON
- `copyWith()` - Create modified copies
- `Equatable` - Value equality

Example:
```dart
class PdfDocument extends Equatable {
  final String id;
  final String filePath;
  // ... other fields
  
  Map<String, dynamic> toJson() { /* ... */ }
  factory PdfDocument.fromJson(Map<String, dynamic> json) { /* ... */ }
  PdfDocument copyWith({ /* ... */ }) { /* ... */ }
  
  @override
  List<Object?> get props => [id, filePath, /* ... */];
}
```

## Adding New Features

To add a new feature:

1. **Create feature directory** under `lib/features/`
2. **Add models** in `models/` subdirectory
3. **Create repository** in `repositories/` for data access
4. **Add providers** in `providers/` for state management
5. **Build screens** in `screens/` for full-page UI
6. **Create widgets** in `widgets/` for reusable components
7. **Update router** to add navigation routes

Example structure:
```
lib/features/bookmarks/
├── models/
│   └── bookmark.dart
├── repositories/
│   └── bookmark_repository.dart
├── providers/
│   └── bookmark_provider.dart
├── screens/
│   └── bookmarks_screen.dart
└── widgets/
    └── bookmark_list.dart
```

## Testing Strategy

### Unit Tests
- Test models (serialization, equality)
- Test repositories (data access logic)
- Test state notifiers (business logic)

### Widget Tests
- Test individual widgets
- Test screen layouts
- Test user interactions

### Integration Tests
- Test complete user flows
- Test navigation
- Test data persistence

## Performance Considerations

1. **Lazy Loading**: PDFs are loaded only when needed
2. **Auto Disposal**: Riverpod automatically disposes unused providers
3. **Efficient Rendering**: pdfx package uses native rendering
4. **Minimal Rebuilds**: Riverpod only rebuilds affected widgets

## Security & Privacy

- All data stored locally on device
- No network requests (currently)
- No analytics or tracking
- User data never leaves the device

## Future Enhancements

1. **Database Migration**: Move from SharedPreferences to SQLite/Hive for better performance
2. **Cloud Sync**: Add Firebase/Supabase integration
3. **Advanced Search**: Full-text search with indexing
4. **Offline ML**: On-device text extraction and summarization
5. **Accessibility**: Screen reader support, high contrast themes

## Contributing Guidelines

When contributing to this project:

1. Follow the existing architecture patterns
2. Keep features self-contained
3. Write tests for new features
4. Update documentation
5. Use meaningful commit messages
6. Keep dependencies minimal

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [go_router Documentation](https://pub.dev/packages/go_router)
- [Material Design 3](https://m3.material.io)
