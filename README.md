# QSL Card Generator Client

> **⚠️ Work in Progress**: This application is under active development. Some features may be incomplete or unstable.

Cross-platform offline QSL card generator for amateur radio operators.

## Features

- Generate QSL cards offline on any platform
- Real-time canvas preview
- Custom background images
- Station logo support
- Signature support (upload image or generate from typed name)
- Setup wizard for first-time configuration
- Export to high-resolution PNG
- Works on Windows, macOS, Linux, Android, and iOS

## Screenshots

*(Coming soon)*

## Installation

### Pre-built releases

Download from the [Releases](https://github.com/achildrenmile/qslcardgenerator-client/releases) page.

### Build from source

```bash
# Clone repository
git clone https://github.com/achildrenmile/qslcardgenerator-client.git
cd qslcardgenerator-client

# Get dependencies
flutter pub get

# Build for your platform
flutter build linux --release    # Linux
flutter build windows --release  # Windows
flutter build macos --release    # macOS
flutter build apk --release      # Android
flutter build ios --release      # iOS
```

## Development

```bash
# Run in development mode
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Related

- Web version: https://qsl.oeradio.at
- Web source: https://github.com/achildrenmile/qslcardgenerator

## License

MIT
