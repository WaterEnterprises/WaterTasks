# Water Tasks

[![Build & Release](https://github.com/WaterEnterprises/WaterTasks/actions/workflows/CI.yml/badge.svg)](https://github.com/WaterEnterprises/WaterTasks/actions/workflows/CI.yml)

Water Tasks is a cross-platform desktop and mobile app built for knowledge workers, students, and anyone who struggles with sustained focus. It combines the structure of task management with a check-in-based accountability system that runs during your work session — turning the abstract goal of "staying focused" into a concrete, measurable practice.

## Executive Summary

**Concept.** Water Tasks is built on a simple premise: planning what to do and proving you're doing it are two different things. Most productivity apps handle the first (to-do lists, calendars) but ignore the second. Water Tasks bridges this gap with a focus session system that periodically asks you to confirm you're still working — and tracks whether you do.

**How it works.** You create task lists (e.g., Work, Study, Chores), add tasks under them, and start a focus session on any task. The app enters a full-screen overlay that pulses at a configurable interval. When a check-in is due, the overlay flashes, a notification fires, and you must tap to confirm you're working. Miss the check-in and the app prompts you to refocus. All sessions, completions, and streaks are logged locally.

**Why it's different.**
- **Accountability as a feature, not an afterthought.** The check-in mechanism creates lightweight, recurring commitment points throughout a work session. It's harder to drift into distraction when you know the next check-in is seconds away.
- **Gamified progress.** Streaks, focus time totals, and completion stats turn deep work into a measurable game. The dashboard shows daily trends, task breakdowns, and personal records.
- **Private by default.** Everything is stored in a local SQLite database. No accounts, no servers, no data collection.
- **Cross-platform, native feel.** Built with Flutter and Material Design 3, it runs on Windows, macOS, Linux, Android, and iOS with a consistent experience.

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
