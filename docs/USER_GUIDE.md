# QSL Card Generator - User Guide

A cross-platform offline application for amateur radio operators to create professional QSL cards.

## Table of Contents

- [Installation](#installation)
- [Getting Started](#getting-started)
- [Creating QSL Cards](#creating-qsl-cards)
- [Managing Your Station](#managing-your-station)
- [Exporting Cards](#exporting-cards)
- [Features](#features)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## Installation

### Windows

1. Download `qsl-card-generator-windows.zip`
2. Extract the ZIP file to a folder of your choice
3. Run `qsl_card_generator.exe`

### Linux

1. Download `qsl-card-generator-linux.tar.gz`
2. Extract: `tar -xzvf qsl-card-generator-linux.tar.gz`
3. Run: `./qsl_card_generator`

**Note:** On some distributions, you may need to install GTK3:
```bash
# Ubuntu/Debian
sudo apt install libgtk-3-0

# Fedora
sudo dnf install gtk3
```

### macOS

1. Download `qsl-card-generator-macos.zip`
2. Extract the ZIP file
3. Move `QSL Card Generator.app` to your Applications folder
4. Right-click and select "Open" (first time only, to bypass Gatekeeper)

### Android

1. Download the appropriate APK for your device:
   - `app-arm64-v8a-release.apk` - Most modern phones (recommended)
   - `app-armeabi-v7a-release.apk` - Older 32-bit phones
   - `app-x86_64-release.apk` - Emulators and some tablets
2. Enable "Install from unknown sources" in Settings
3. Open the APK file to install

### iOS

The iOS build requires signing with an Apple Developer account. For testing:
1. Use Xcode to install the unsigned build on your device
2. Or wait for App Store release

---

## Getting Started

### First-Time Setup

When you first launch the app, a setup wizard will guide you through:

1. **Welcome Screen** - Introduction to the app
2. **Station Information** - Enter your details:
   - **Callsign** (required) - Your amateur radio callsign
   - **Operator Name** - Your name as you want it on the card
   - **Address** - Your QTH (location)
   - **Grid Locator** - Your Maidenhead grid square
   - **Station Logo** - Upload your station logo (optional)
   - **Signature** - Upload or create a signature image (optional)

3. **Complete Setup** - Review and finish

Your information is stored locally on your device - no internet connection required.

---

## Creating QSL Cards

### QSO Information

For each QSL card, enter the contact details:

| Field | Description | Example |
|-------|-------------|---------|
| **To Callsign** | The station you contacted | `W1ABC` |
| **Date** | Date of the QSO | `2024-01-15` |
| **Time (UTC)** | Time in UTC | `14:30` |
| **Frequency** | Band or frequency | `14.250 MHz` or `20m` |
| **Mode** | Operating mode | `SSB`, `CW`, `FT8`, `FM` |
| **RST Sent** | Signal report you sent | `59` |
| **RST Received** | Signal report received | `57` |

### Card Preview

The live preview shows how your card will look. The card includes:

- Your callsign (prominent display)
- Station information
- QSO details in a formatted table
- Your logo (if uploaded)
- Your signature (if added)
- Background image or template

---

## Managing Your Station

### Changing Your Callsign

If you get a new callsign:

1. Open the side menu
2. Find "My Callsign" section
3. Tap the edit button
4. Enter your new callsign
5. Confirm the change

**Note:** This will migrate all your associated files (logo, signature, templates) to the new callsign.

### Updating Station Information

To update your name, address, or grid locator:

1. Open the side menu
2. Find "Station Info" section
3. Tap "Edit"
4. Update your information
5. Save changes

Your card template will automatically regenerate with the new information.

### Managing Your Logo

**Adding a Logo:**
1. Open the side menu
2. Find "Station Logo" section
3. Tap "Add Logo"
4. Select an image from your device
5. Crop if needed

**Recommended logo format:**
- PNG with transparent background
- Square aspect ratio (1:1)
- Minimum 200x200 pixels

**Removing a Logo:**
1. Tap the delete button next to your current logo

### Managing Your Signature

**Option 1: Upload an Image**
1. Open the side menu
2. Find "Signature" section
3. Tap "Add Signature"
4. Choose "Upload Image"
5. Select your signature image
6. Crop to 6:1 aspect ratio

**Recommended signature format:**
- PNG with transparent background
- Wide aspect ratio (approximately 6:1)
- Dark color for visibility

**Option 2: Type Your Signature**
1. Tap "Add Signature"
2. Choose "Type Signature"
3. Enter your name
4. Select a handwriting font
5. Preview and save

### Additional Logos

You can add up to 6 additional logos (club logos, award logos, etc.):

1. Open the side menu
2. Find "Additional Logos" section
3. Tap "Add" to add a new logo
4. Select and crop the image

### Callsign Color

Customize the color of your callsign on the card:

1. Open the side menu
2. Find "Callsign Color" section
3. Tap the color swatch
4. Select your preferred color
5. The preview updates automatically

---

## Exporting Cards

### Export as PNG

1. Fill in the QSO information
2. Review the preview
3. Tap "Export PNG"
4. Choose a save location
5. The card is saved as a high-resolution PNG (4961 x 3189 pixels)

### Print-Ready Quality

Exported cards are optimized for printing:
- **Resolution:** 300 DPI at standard QSL card size (5.5" x 3.5")
- **Format:** PNG with full color
- **Size:** Approximately 4961 x 3189 pixels

---

## Features

### Offline Operation

The app works completely offline. All data is stored locally:
- Station configuration
- Images (logos, signatures, backgrounds)
- No internet connection required

### Background Images

Customize your card with background images:

1. Open the side menu
2. Find "Background" section
3. Select from built-in options or add your own

**Adding Custom Backgrounds:**
1. Tap "Add Background"
2. Select an image file
3. The image is saved for future use

### Card Templates

Templates overlay on top of your background:

1. Open the side menu
2. Find "Template" section
3. Select or upload a template

**Template Tips:**
- Use PNG with transparency
- Design around the text areas
- Match the card aspect ratio (1.57:1)

---

## Troubleshooting

### App Won't Start

**Windows:**
- Ensure you extracted all files from the ZIP
- Try running as administrator
- Check that Visual C++ Redistributable is installed

**Linux:**
- Ensure GTK3 is installed
- Check file permissions: `chmod +x qsl_card_generator`
- Run from terminal to see error messages

**macOS:**
- Right-click and select "Open" to bypass Gatekeeper
- Check System Preferences > Security & Privacy if blocked

### Images Not Loading

- Ensure image files are in supported formats (PNG, JPG, GIF, WebP)
- Check that files are not corrupted
- Try re-adding the image

### Export Fails

- Ensure you have write permission to the destination folder
- Check available disk space
- Try exporting to a different location

### Card Preview Looks Wrong

- Check that all required fields are filled
- Try restarting the app
- Verify image files are valid

### Lost Data After Update

- Data is stored in your user directory
- Check the application data folder:
  - **Windows:** `%APPDATA%\qsl_card_generator`
  - **Linux:** `~/.local/share/qsl_card_generator`
  - **macOS:** `~/Library/Application Support/qsl_card_generator`

---

## FAQ

### What is a QSL card?

A QSL card is a confirmation of a two-way radio contact between amateur radio operators. It's a tradition dating back to the early days of radio, serving as proof of communication and often collected by operators worldwide.

### What size are the exported cards?

Cards are exported at 4961 x 3189 pixels, which is 300 DPI at the standard QSL card size of 5.5" x 3.5" (140mm x 90mm).

### Can I use my own background images?

Yes! You can add custom background images in PNG, JPG, or other common formats. For best results, use images with a 1.57:1 aspect ratio.

### Is my data backed up?

Data is stored locally on your device. We recommend:
- Regularly backing up your application data folder
- Keeping copies of your logo and signature images

### Can I use this commercially?

The app is free for amateur radio use. Generated cards are yours to print and distribute as QSL cards.

### How do I report bugs or request features?

Visit our GitHub repository:
https://github.com/achildrenmile/qslcardgenerator-client/issues

---

## Keyboard Shortcuts (Desktop)

| Shortcut | Action |
|----------|--------|
| `Ctrl+S` / `Cmd+S` | Export current card |
| `Tab` | Move to next field |
| `Shift+Tab` | Move to previous field |

---

## Support

- **GitHub Issues:** https://github.com/achildrenmile/qslcardgenerator-client/issues
- **Web Version:** https://qsl.oeradio.at

---

## Version History

### v1.0.0-beta (January 2026)
- Initial beta release
- Support for Windows, Linux, macOS, Android, iOS
- Custom logo and signature support
- Background image customization
- Callsign color picker
- High-resolution PNG export
- Offline operation

---

73 de OE8YML
