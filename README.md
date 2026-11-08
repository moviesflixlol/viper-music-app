# Viper Music (Flutter UI)

A clean, minimalist music streaming application built in **Flutter**, featuring a **Netflix-inspired black and red aesthetic** and powered by the **NextViper** backend engine.

## Visual Design Palette (Netflix Theme)
- **Deep Black (`#000000` / `#121212`)**: Ultra-clean, battery-saving dark backgrounds.
- **Netflix Signature Red (`#E50914`)**: Ambient glow, primary play buttons, active equalizers, and scrubber tracks.
- **Muted Platinum (`#FFFFFF` / `#B3B3B3`)**: Clean high-contrast typography.

## Features

- **Personalized Music Feed**: Netflix-style spotlight hero banner, top trending ranked tracks (1-10 badges), and personalized quick picks.
- **Search**: Fast song, artist, and album queries powered by the NextViper InnerTube backend with genre chip filters.
- **Persistent Mini-Player**: Bottom docked player with top-edge progress indicator, quick play/pause, and track skip controls.
- **Full-Screen Player**: Ambient red aura, circular vinyl-like shadow cover, scrubber slider, shuffle/repeat toggles, and up-next queue drawer.
- **Background Playback**: Configured with Android `FOREGROUND_SERVICE_MEDIA_PLAYBACK` and iOS `AudioSession` for screen-off playback.
- **Offline Downloads Manager**: Save audio streams directly to local storage for airplane mode playback with progress indicators and swipe-to-delete.

## How to Run

1. Make sure your NextViper backend is running:
   ```bash
   nextviper run /path/to/server.nv
   ```

2. Run the Flutter app:
   ```bash
   cd viper_music_app
   flutter pub get
   flutter run
   ```

*Note: In the app, tap the Settings icon in the top right to configure your NextViper server address if running on a remote VPS or physical device.*
