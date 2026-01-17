# QSL Card Generator Client

Cross-platform offline QSL card generator for amateur radio operators.

[![Latest Release](https://img.shields.io/github/v/release/achildrenmile/qslcardgenerator-client?include_prereleases)](https://github.com/achildrenmile/qslcardgenerator-client/releases)
[![License](https://img.shields.io/github/license/achildrenmile/qslcardgenerator-client)](LICENSE)

## Features

- **Offline Operation** - No internet connection required
- **Cross-Platform** - Windows, macOS, Linux, Android, and iOS
- **Real-time Preview** - See your card as you build it
- **Default Mountain Background** - Beautiful royalty-free landscape included
- **Custom Backgrounds** - Use your own images
- **Station Logo** - Add your personal or club logo
- **Signature Support** - Upload image or generate from typed name
- **Additional Logos** - Add up to 6 club/award logos
- **Callsign Color** - Customize your callsign color
- **Auto-Save Export** - Cards saved with callsign filename (e.g., `OE8CDC.png`)
- **Smart Duplicates** - Automatic numbering for multiple QSOs (`OE8CDC(1).png`, `OE8CDC(2).png`)
- **Quick Access** - Folder opens automatically after export
- **High-Resolution Export** - Print-ready 300 DPI PNG output
- **Setup Wizard** - Easy first-time configuration

## Beta Status

**Current version: v1.0.0-beta.5**

| Platform | Status |
|----------|--------|
| Ubuntu 24.04 LTS | ✅ Tested |
| Windows 11 | ✅ Tested |
| macOS | 🧪 Needs testing |
| Android | 🧪 Needs testing |
| iOS | 🧪 Needs testing |

### We Need Testers!

Help us improve by testing on your platform and reporting issues:
- **GitHub Issues:** https://github.com/achildrenmile/qslcardgenerator-client/issues
- **Email:** oe8yml@rednil.at

73 de OE8YML

## Documentation

**[User Guide](docs/USER_GUIDE.md)** - Complete guide for using the application

## Installation

Download the latest release for your platform from the [Releases](https://github.com/achildrenmile/qslcardgenerator-client/releases) page.

### Windows

1. Download `qsl-card-generator-windows.zip`
2. Right-click the ZIP file and select **Extract All...**
3. Open the extracted folder
4. Double-click `qsl_card_generator.exe` to run

**Note:** If Windows SmartScreen appears, click "More info" then "Run anyway".

### Linux

1. Download `qsl-card-generator-linux.tar.gz`
2. Extract the archive:
   ```bash
   tar -xzvf qsl-card-generator-linux.tar.gz
   ```
3. Run the application:
   ```bash
   ./qsl_card_generator
   ```

**Dependencies:** On some distributions, install GTK3 if not present:
```bash
# Ubuntu/Debian
sudo apt install libgtk-3-0

# Fedora
sudo dnf install gtk3

# Arch
sudo pacman -S gtk3
```

### macOS

1. Download `qsl-card-generator-macos.zip`
2. Double-click to extract
3. Drag `QSL Card Generator.app` to your **Applications** folder
4. First launch: Right-click the app and select **Open** (required to bypass Gatekeeper)
5. Click **Open** in the confirmation dialog

**Note:** macOS may show "unidentified developer" warning on first launch. Use right-click → Open to allow it.

### Android

1. Download the APK for your device:
   - `app-arm64-v8a-release.apk` - Most modern phones (2016+)
   - `app-armeabi-v7a-release.apk` - Older 32-bit phones
   - `app-x86_64-release.apk` - Emulators and some tablets
2. On your phone, go to **Settings → Security** and enable **Install from unknown sources**
3. Open the downloaded APK file
4. Tap **Install** when prompted
5. Tap **Open** to launch the app

**Tip:** If unsure which APK to use, try `app-arm64-v8a-release.apk` first.

### iOS

The iOS build is unsigned and requires manual installation:

**Option 1: Using Xcode (requires Mac)**
1. Download `qsl-card-generator-ios.zip`
2. Extract the ZIP file
3. Connect your iPhone to your Mac
4. Open Xcode and select **Window → Devices and Simulators**
5. Drag `Runner.app` onto your device

**Option 2: Using AltStore**
1. Install [AltStore](https://altstore.io/) on your iPhone
2. Convert the .app to .ipa or wait for official App Store release

**Note:** iOS apps installed this way expire after 7 days (free developer account) or 1 year (paid account).

---

### Build from Source

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
