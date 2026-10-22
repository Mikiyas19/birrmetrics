# BirrMetrics

> Understand your Birr.

Adaptive budgeting & expense tracker for Ethiopian students and young professionals.
Offline-first, rule-based insights, no bank integration required.

## Monorepo layout


## Stack

| Layer     | Tech |
|-----------|------|
| Mobile    | Flutter 3.22+, Riverpod, go_router, sqflite, Dio |
| Backend   | Go 1.22+, chi, pgx/v5, JWT |
| Data      | SQLite (mobile), PostgreSQL (server) |
| CI        | GitHub Actions (path-filtered per app) |

## Quickstart

### Mobile
```powershell
cd mobile
Copy-Item .env.example .env
flutter pub get
flutter run