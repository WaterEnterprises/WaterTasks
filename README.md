# Water Tasks

A cross-platform gamified task management app that turns your to-do list into a focus-driven productivity system.

[![Build & Release](https://github.com/YOUR_USERNAME/water_tasks/actions/workflows/CI.yml/badge.svg)](https://github.com/YOUR_USERNAME/water_tasks/actions/workflows/CI.yml)

---

## Overview

Water Tasks helps you stay focused by combining task management with a check-in based focus timer. Create task lists, add tasks, and start a focus session. The screen becomes a full-screen colored overlay that pulses, and you must periodically tap to confirm you're still working. Miss a check-in and the app asks if you're still on task. All data is stored locally with SQLite.

**Supported platforms:** Windows, macOS, Linux, Android, iOS

---

## Features

- **Task Lists** — Create themed lists (Work, Study, Chores, etc.) with custom colors
- **Tasks** — Add tasks with titles and optional descriptions; check them off when done
- **Focus Overlay** — Start a task to enter full-screen focus mode with a pulsing colored overlay
- **Periodic Check-ins** — The overlay blinks and you must tap to confirm you're working; miss a check-in and the app prompts you
- **Dashboard** — View stats: current/longest streak, tasks completed, total focus time, sessions, daily focus chart (last 14 days), and task breakdown by list
- **SQLite Local Storage** — All data stays on-device, no account needed
- **Light & Dark Mode** — Follows system theme automatically
- **Material 3** — Modern Material Design 3 UI

---

## Screenshots

| Home | Task List | Focus Overlay | Dashboard |
|------|-----------|---------------|-----------|
| ![Home](screenshots/home.png) | ![Detail](screenshots/detail.png) | ![Overlay](screenshots/overlay.png) | ![Dashboard](screenshots/dashboard.png) |

*(Add actual screenshots to a `screenshots/` folder)*

---

## Architecture

```
lib/
├── main.dart                  # App entry point with Provider setup
├── models/
│   ├── task_list_model.dart   # TaskList data class
│   ├── task_model.dart        # Task data class
│   └── session_model.dart     # Session (focus session) data class
├── database/
│   └── database_helper.dart   # SQLite CRUD + stats queries
├── providers/
│   └── task_provider.dart     # ChangeNotifier state management
├── screens/
│   ├── home_screen.dart       # Task list overview
│   ├── task_list_detail_screen.dart  # Tasks within a list
│   ├── focus_overlay_widget.dart     # Draggable floating check-in button
│   └── dashboard_screen.dart  # Statistics dashboard
└── widgets/
    ├── task_list_card.dart    # List item widget
    ├── task_card.dart         # Task item widget
    └── stat_card.dart         # Dashboard stat card
```

### State Management

Uses `provider` package with `ChangeNotifier`. The `TaskProvider` holds the current task lists, tasks, and active focus session state.

### Database

SQLite via `sqflite` with three tables:

- **task_lists** — id, name, color, created_at
- **tasks** — id, list_id (FK), title, description, created_at, completed_at
- **sessions** — id, task_id (FK), start_time, end_time, duration_seconds, check_in_count

Foreign keys enforce cascade deletes.

---

## Getting Started

### Prerequisites

- Flutter SDK ^3.10.4 ([install guide](https://flutter.dev/docs/get-started/install))
- Platform-specific tooling:
  - **Windows** — Visual Studio 2022 with "Desktop development with C++"
  - **macOS** — Xcode 15+
  - **Linux** — `ninja-build`, `libgtk-3-dev`, `cmake`
  - **Android** — Android Studio, Android SDK 21+
  - **iOS** — Xcode, Apple Developer account for device deployment

### Setup

```bash
# Clone the repo
git clone https://github.com/WaterEnpterprises/water_tasks.git
cd water_tasks

# Get dependencies
flutter pub get

# Run for your platform
flutter run -d windows   # Windows
flutter run -d macos     # macOS
flutter run -d linux     # Linux
flutter run -d android   # Android (emulator or device)
flutter run -d ios       # iOS (simulator or device)

# Or use the ADB install script (Android device connected via USB)
.\scripts\install.ps1           # debug build
.\scripts\install.ps1 -BuildMode release  # release build
```

### Build for Release

```bash
flutter build windows --release   # Windows
flutter build macos --release     # macOS
flutter build linux --release     # Linux
flutter build apk --release       # Android
flutter build ios --release       # iOS
flutter build web --release       # Web
```

---

## CI/CD

The included GitHub Actions workflow (`.github/workflows/CI.yml`) builds for all platforms and creates a GitHub Release with artifacts on every push to `main`.

See `SETUP.md` for configuring signing secrets for Android and iOS releases.

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter 3.10+ |
| Language | Dart |
| State Management | Provider + ChangeNotifier |
| Database | sqflite (SQLite) |
| Charts | fl_chart |
| Date Formatting | intl |
| Design System | Material Design 3 |

---

## License

MIT
