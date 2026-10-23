# RentKeeper Flutter Client Data Layer & Offline Sync

This package provides the Flutter-side database, models, and offline-first repository to connect the RentKeeper mobile/tablet UI to the Dart backend server.

---

## 🏗 Architecture

```
Flutter UI (code.html / Flutter Widgets)
          │
          ▼
   RentKeeperRepository (Offline-First)
     ├── Read/Write directly to Local SQLite
     └── Appends mutations to Sync Queue
          │
     ┌────┴──────────────────────────┐
     ▼                               ▼
(When Offline)                 (When Online)
Stay in SQLite                 RentKeeperApiClient
Queue count increases          POST /api/v1/sync/push
                               GET  /api/v1/sync/pull
                                     │
                                     ▼
                        Dart Backend (bin/server.dart)
```

---

## 📂 Contents

1. **`lib/database/sqlite_schema.dart`**: Complete SQLite DDL table schemas (`items`, `customers`, `challans`, `sync_queue`).
2. **`lib/services/rentkeeper_api_client.dart`**: HTTP REST client connecting to the Dart backend.
3. **`lib/repository/rentkeeper_repository.dart`**: Offline-first repository coordinating local SQLite cache and remote synchronization.
