# QSL Card Generator Client - Claude Context

## Project Overview

Cross-platform offline QSL card generator for amateur radio operators. Desktop and mobile app version of the web-based qslcardgenerator.

- **Repository:** https://github.com/achildrenmile/qslcardgenerator-client
- **Related Web Version:** https://qsl.oeradio.at

## Tech Stack

- **Framework:** Flutter 3.38+
- **Language:** Dart
- **Platforms:** Windows, macOS, Linux, Android, iOS
- **Storage:** SharedPreferences (config), File system (images)

## Project Structure

```
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   │   ├── card_config.dart   # Card configuration
│   │   ├── qso_data.dart      # QSO form data
│   │   └── text_position.dart # Text positioning
│   ├── screens/               # UI screens
│   │   └── generator_screen.dart
│   ├── services/              # Business logic
│   │   ├── storage_service.dart
│   │   └── export_service.dart
│   └── widgets/               # Reusable widgets
│       ├── qsl_card_painter.dart
│       └── qsl_card_preview.dart
├── assets/
│   ├── backgrounds/           # Background images
│   ├── templates/             # Card templates
│   └── fonts/                 # Custom fonts
├── pubspec.yaml               # Dependencies
└── test/                      # Unit tests
```

## Development

### Prerequisites

- Flutter SDK 3.38+
- For desktop: platform-specific requirements
  - Linux: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`
  - Windows: Visual Studio 2022
  - macOS: Xcode
- For mobile: Android Studio / Xcode

### Setup

```bash
# Get dependencies
flutter pub get

# Run on current platform
flutter run

# Run on specific platform
flutter run -d linux
flutter run -d windows
flutter run -d macos
flutter run -d chrome  # web (if enabled)
```

### Build

```bash
# Linux
flutter build linux --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## Features

- **Offline operation**: No internet required after installation
- **Canvas-based rendering**: Real-time QSL card preview
- **Custom backgrounds**: Import your own background images
- **Card templates**: Support for PNG overlay templates
- **Export to PNG**: Save cards in high resolution
- **Multi-platform**: Same app on desktop and mobile

## Data Storage

User data is stored locally:
- **Config**: SharedPreferences (callsign settings, text positions)
- **Images**: Application documents directory
  - `qsl_backgrounds/` - Background images
  - `qsl_templates/` - Card templates

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `path_provider` | Platform-specific directories |
| `shared_preferences` | Persistent key-value storage |
| `image_picker` | Image selection |
| `file_picker` | Save file dialog |
| `image` | Image processing |

## Architecture

The app follows a simple service-based architecture:
- **Models**: Plain Dart classes with JSON serialization
- **Services**: Business logic (storage, export)
- **Widgets**: Reusable UI components
- **Screens**: Full page views

## Related Projects

- [qslcardgenerator](https://github.com/achildrenmile/qslcardgenerator) - Web version
