# Water Tasks — AGENTS.md

Instructions for AI coding agents working on this project.

---

## Project Identity

- **App Name:** Water Tasks
- **Package Name:** `water_tasks`
- **Flutter SDK:** ^3.10.4
- **Platforms:** Windows, macOS, Linux, Android, iOS, Web

---

## Code Conventions

### General
- No comments in code unless absolutely necessary for clarity
- Use `camelCase` for variables, methods, and parameters
- Use `PascalCase` for classes, enums, and type definitions
- Use `snake_case` for file names
- Always specify `const` on constructors where possible
- Use `super.parameter` shorthand (Dart 3+) for constructor parameters
- Mimic existing code style when adding files

### Imports
- Order: dart: → package: → relative (separated by blank line)
- Use relative imports for project files (e.g., `'../models/task_model.dart'`)
- Avoid barrel files — import specific files directly

### State Management
- All state goes through `TaskProvider` (extends `ChangeNotifier`) in `lib/providers/task_provider.dart`
- Use `Provider.of<T>(context)` or `context.watch<T>()` / `context.read<T>()` for access
- UI reads state with `context.watch<TaskProvider>()`
- Mutations happen through `context.read<TaskProvider>().method()`

### Models
- Every model class has: constructor, `toMap()`, `factory fromMap()`, `copyWith()`
- Models are immutable — `copyWith` is the only mutation path
- Store dates as ISO 8601 strings in DB, parse to `DateTime` in memory

### Database
- All queries go through `DatabaseHelper` singleton in `lib/database/database_helper.dart`
- Use raw SQL for complex queries (stats, aggregations)
- Use the query builder for simple CRUD
- Foreign keys cascade on delete
- Add new migrations by incrementing the DB version and adding a migration callback

### Navigation
- Use imperative `Navigator.push` / `Navigator.pop` (no GoRouter for this app)
- Push new routes with `MaterialPageRoute`
- Pass required data as constructor parameters

### Directory Structure
```
lib/
  main.dart                       # Entry point, Provider setup
  models/                         # Data classes (immutable, with fromMap/toMap/copyWith)
  database/                       # SQLite helper (singleton)
  providers/                      # ChangeNotifier providers
  services/                       # Utility services (notification sound)
  screens/                        # Full-page widgets
  widgets/                        # Reusable smaller widgets
test/
  widget_test.dart
```

### Testing
- Run tests with: `flutter test`
- Run analysis with: `flutter analyze`
- Widget tests go in `test/` mirroring `lib/` structure
- No test framework is pre-configured beyond `flutter_test`

---

## Adding Features

### Adding a new screen

1. Create the file in `lib/screens/`
2. If it needs state, inject `TaskProvider` via `context.watch<TaskProvider>()`
3. Navigate to it using `Navigator.push(context, MaterialPageRoute(...))`
4. Import only what's needed — avoid barrel imports

### Adding a new model

1. Create file in `lib/models/`
2. Follow the existing pattern: named constructor, `toMap()`, `factory fromMap()`, `copyWith()`
3. Add table creation SQL in `DatabaseHelper._onCreate()`
4. Add CRUD methods in `DatabaseHelper`
5. Add state management in `TaskProvider`

### Adding a new query/stats

1. Add SQL method to `DatabaseHelper`
2. Expose through `TaskProvider` if the UI needs reactive access
3. Call directly from screen if it's a one-off (e.g., dashboard which reloads on visit)

---

## Workflow Commands

```bash
# Get dependencies
flutter pub get

# Run on platform
flutter run -d <windows|macos|linux|android|ios>

# Analyze
flutter analyze

# Format
dart format lib/

# Test
flutter test

# Build
flutter build <windows|macos|linux|apk|ios|web> --release
```

---

## CI/CD

- Workflow: `.github/workflows/CI.yml`
- Triggered on push to `main` / `master`
- Builds all 6 platforms (Android, iOS, macOS, Linux, Windows, Web) and creates a GitHub Release
- Android signs with Play Store keystore (set `KEYSTORE_*` secrets)
- iOS signs with App Store certificate (set `P12_*` + `PROVISIONING_PROFILE_*` secrets)
- See `SETUP.md` for configuring signing secrets

---

## Conventions to Preserve

- **No generated files** — no code generation (json_serializable, freezed, etc.)
- **No state management package beyond `provider`** — no Riverpod, BLoC, etc.
- **No Firebase/Auth** — this is a local-only app
- **Material 3** (`useMaterial3: true`) — keep using M3 components
- **Dark mode** — support both light/dark via `ThemeMode.system`
- **Comments** — do NOT add comments (the instruction "no comments" takes priority)

---

## Common Tasks

### "Add a new database column"

1. Add the field to the model class
2. Add the column to `toMap()` and `fromMap()`
3. Increment DB version in `DatabaseHelper._initDatabase()`
4. Add an `onUpgrade` callback with `ALTER TABLE` SQL

### "Add a new screen with a form"

1. Create the screen file in `lib/screens/`
2. Use a `StatefulWidget` if the form needs local state
3. For dialogs, use `showDialog` with `AlertDialog`
4. For bottom sheets, use `showModalBottomSheet`
5. Read/write data through `TaskProvider`

### "Add a new chart to the dashboard"

1. Add the data query method to `DatabaseHelper`
2. Call it in `DashboardScreen._loadStats()`
3. Render with `fl_chart` (existing dependency)
4. Follow the existing bar chart pattern in `dashboard_screen.dart`

### "Rename / refactor"

- Update the model first, then `toMap()` / `fromMap()`, then DB column if applicable
- Use the Edit tool's `replaceAll: true` for renaming across files

---

## Notes

- This project started from a Flutter template with CI/CD pre-configured
- The template's CI builds for all 6 platforms (Windows, macOS, Linux, Android, iOS, Web)
- The focus overlay simulates a "gamified focus" experience — it's not a real Pomodoro timer
- Check-in interval is configurable per task list (30s to 30min) via `TaskListModel.checkInIntervalSeconds`
- Notification sound is generated programmatically (880Hz sine wave WAV) in `lib/services/notification_service.dart` — no audio assets needed
- The check-in button pulses and the device vibrates when a check-in is due; if the user doesn't tap within 5 seconds, a "missed check-in" dialog appears
