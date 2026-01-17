# QSL Card Generator Client

Cross-platform offline QSL card generator for amateur radio operators.

## Features

- **Offline Operation** - No internet connection required
- **Cross-Platform** - Windows, macOS, Linux, Android, and iOS
- **Real-time Preview** - See your card as you build it
- **Custom Backgrounds** - Use your own images
- **Station Logo** - Add your personal or club logo
- **Signature Support** - Upload image or generate from typed name
- **Additional Logos** - Add up to 6 club/award logos
- **Callsign Color** - Customize your callsign color
- **High-Resolution Export** - Print-ready 300 DPI PNG output
- **Setup Wizard** - Easy first-time configuration

## Documentation

**[User Guide](docs/USER_GUIDE.md)** - Complete guide for using the application

## Installation

### Download Pre-built Releases

Download the latest release for your platform from the [Releases](https://github.com/achildrenmile/qslcardgenerator-client/releases) page:

| Platform | Download |
|----------|----------|
| Windows | `qsl-card-generator-windows.zip` |
| Linux | `qsl-card-generator-linux.tar.gz` |
| macOS | `qsl-card-generator-macos.zip` |
| Android | `app-arm64-v8a-release.apk` (most devices) |
| iOS | `qsl-card-generator-ios.zip` |

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
