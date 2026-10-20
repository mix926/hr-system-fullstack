# HR System Frontend

Enterprise HR mobile app built with Flutter.

## Tech Stack
- **Flutter** — Cross-platform UI framework
- **flutter_bloc** — State management
- **Dio** — HTTP client
- **GetIt** — Dependency injection
- **shared_preferences** — Local storage

## Features
- Employee directory with search
- Leave request management
- Attendance tracking
- Performance reviews
- Role-based UI (ADMIN, MANAGER, STAFF)

## Setup
```bash
cd hr_frontend
flutter pub get
flutter run
```

## Architecture
Clean architecture with feature-based folder structure:
- `core/` — Shared utilities, theme, DI
- `features/` — Feature modules (auth, employee, leave, attendance, performance)
