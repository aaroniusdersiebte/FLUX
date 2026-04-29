# FLUX — Terminal-style RSVP speed reading app

![FLUX Logo](../logo.af) *(Placeholder for Logo)*

**FLUX** is a high-performance, minimalist Android application built with Flutter, designed for Rapid Serial Visual Presentation (RSVP) speed reading. It features a distinct "Terminal" aesthetic with deep blacks, sharp white text, and striking amber accents.

## ⚡ Features

- **RSVP Reading Engine**: Customizable WPM (Words Per Minute) with an adaptive engine that handles punctuation and sentence structure.
- **ORP Highlighting**: Optimal Recognition Point (ORP) focal point hardcoded at 40% for maximum reading efficiency.
- **Format Support**: Import and read `.epub` and `.txt` files directly into your terminal library.
- **Terminal Aesthetic**: 
  - **Colors**: Deep Black (#000000), White, and Amber (#FFBF00).
  - **Typography**: JetBrains Mono for that authentic terminal feel.
  - **Animations**: "Matrix" style decrypt animations for a high-tech UI experience.
- **Analytics**: Track your daily word counts and total reading progress with integrated bar charts.
- **Library Management**: Persistent storage of your book collection and per-book reading progress.

## 🛠️ Architecture

FLUX follows a clean, service-oriented architecture using the **Provider** pattern for state management.

- **AppState**: The single source of truth for library state, playback control, and user settings.
- **RsvpService**: Pure business logic for ORP calculations, timing (WPM to ms conversion), and adaptive pauses.
- **StorageService**: Handles persistence using `SharedPreferences` and local file I/O for book content.
- **Parsers**: Dedicated `EpubParser` and `TxtParser` for converting raw files into readable word streams.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android SDK (API 26+ required)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```bash
   cd read/flux
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```

### Development Commands

```bash
flutter analyze          # Run linter (keep it clean!)
flutter test             # Run widget and unit tests
flutter run              # Run on a connected device
flutter build apk --debug   # Build debug APK
```

## 🎨 Theme Guidelines

FLUX uses a custom `TerminalTheme`. 
- **Font**: Always use `GoogleFonts.jetBrainsMono()`.
- **Colors**: Reference `TerminalColors` for all UI elements.
- **Constraint**: The `RsvpDisplay` is capped at 440px width to ensure readability on larger screens/landscape mode.

## 📊 Technical Details

- **Min SDK**: 26 (Android 8.0)
- **State Management**: Provider
- **Persistence**: `shared_preferences` for metadata and `path_provider` for file storage.
- **Parsing**: `epubx` for EPUB structure handling.

---

*“Information wants to be free. Speed makes it accessible.”*
