# Architecture Documentation

Comprehensive technical documentation for Amal Syarafi's architecture and design patterns.

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Clean Architecture](#clean-architecture)
3. [Data Flow](#data-flow)
4. [State Management](#state-management)
5. [Service Layer](#service-layer)
6. [Data Persistence](#data-persistence)
7. [Security Model](#security-model)
8. [Error Handling](#error-handling)
9. [Performance Optimization](#performance-optimization)

---

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Frontend                        │
│  (UI Screens, Widgets, Navigation, Material Design 3)       │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   ┌─────────────┐ ┌─────────────┐ ┌──────────────┐
   │  Riverpod   │ │ Local Cache │ │  Location &  │
   │  Providers  │ │  (Hive)     │ │ Permissions  │
   └──────┬──────┘ └──────┬──────┘ └──────┬───────┘
          │                │               │
        ┌─┴────────────────┼───────────────┴─┐
        ▼                  ▼                 ▼
   ┌────────────────────────────────────────────────┐
   │        Business Logic & Services Layer         │
   │  ├─ SyncService (Cloud ↔ Local)               │
   │  ├─ GeminiService (AI Chat)                   │
   │  ├─ PrayerTimeService (Aladhan API)           │
   │  ├─ NotificationService (Local Alerts)        │
   │  └─ LocationService (Geocoding)               │
   └────┬───────────────────────────────────┬──────┘
        │                                   │
        ▼                                   ▼
   ┌───────────────────┐         ┌──────────────────┐
   │ Supabase Backend  │         │  External APIs   │
   │ ├─ PostgreSQL     │         │  ├─ Gemini API   │
   │ ├─ Auth           │         │  ├─ Aladhan API  │
   │ ├─ RLS Policies   │         │  └─ Geocoding    │
   │ └─ Real-time Sub  │         └──────────────────┘
   └───────────────────┘
```

### Key Design Principles

- **Separation of Concerns**: Each layer has specific responsibility
- **Dependency Injection**: Services injected via Riverpod providers
- **Reactive Programming**: Riverpod for state updates
- **Offline-First**: Local storage is primary, cloud is sync target
- **Type Safety**: Strong typing throughout the app
- **Immutability**: Dart final & immutable classes

---

## Clean Architecture

### Layered Structure

```
Feature Module:
├── presentation/          ← UI Layer
│   ├── screens/          (Page widgets)
│   ├── widgets/          (Reusable components)
│   └── providers.dart    (UI state)
├── domain/               ← Business Rules Layer
│   └── models.dart       (Business entities)
└── data/                 ← Data Layer
    └── services.dart     (Data access)
```

### Dependency Rule

```
Presentation → Domain ← Data
     ▲                    ▲
     └────────(Plugin)────┘
```

**Rule**: Inner layers don't depend on outer layers

### Example: Daily Logs Feature

```
features/dashboard/
├── presentation/
│   ├── screens/
│   │   └── dashboard_screen.dart      # Observes dailyLogsProvider
│   └── widgets/
│       ├── activity_card.dart         # Displays activity with status
│       ├── daily_summary_card.dart    # Shows daily stats
│       └── date_selector.dart         # Date picker
├── domain/
│   └── models/
│       └── daily_log_model.dart       # Freezed data class
└── data/
    └── repositories/
        └── daily_log_repository.dart  # CRUD operations
```

---

## Data Flow

### User Interacts with Activity (Check/Uncheck)

```
1. User taps activity card
        │
        ▼
2. Widget calls updateLog(activityId, value)
        │
        ▼
3. Provider: DailyLogsNotifier.updateLog()
   ├─ Create/update DailyLogModel
   ├─ Save to LocalStorageService (Hive)
   ├─ Update provider state
   └─ Trigger _syncInBackground()
        │
        ▼
4. SyncService.syncToSupabase()
   ├─ Check internet connection
   ├─ Ensure user exists in database
   ├─ Check if log already exists (upsert)
   └─ Insert or update in Supabase
        │
        ▼
5. Mark as synced in LocalStorageService
        │
        ▼
6. UI updates from Riverpod state
```

### Login Flow with Data Isolation

```
1. User enters email & password
        │
        ▼
2. AuthProvider.login()
   ├─ Call Supabase.auth.signInWithPassword()
   └─ Get user ID
        │
        ▼
3. _loadUserProfile(userId)
   ├─ Fetch user from Supabase
   ├─ Save to LocalStorageService
   ├─ Open user-specific Hive boxes
   │  └─ daily_logs_{userId}
   │  └─ weekly_summary_{userId}
   └─ Update auth state
        │
        ▼
4. DailyLogsProvider._initializeAndLoad()
   ├─ Call SyncService.fetchFromSupabase(userId)
   │  ├─ Clear local data (fresh start)
   │  └─ Fetch last 90 days from server
   ├─ Call SyncService.syncToSupabase()
   │  └─ Upload any unsynced logs
   └─ Load from local storage
        │
        ▼
5. Dashboard displays user's data only
```

### Logout Flow (Security)

```
1. User taps logout
        │
        ▼
2. AuthProvider.logout()
   ├─ Call Supabase.auth.signOut()
   └─ Call LocalStorageService.clearAll()
        │
        ▼
3. LocalStorageService.clearAll()
   ├─ clearCurrentUserData()
   │  ├─ Clear daily_logs_{userId}
   │  └─ Clear weekly_summary_{userId}
   ├─ closeUserBoxes()
   │  └─ Release Hive box handles
   ├─ Clear global user info
   └─ Clear pending sync queue
        │
        ▼
4. Update auth state → unauthenticated
        │
        ▼
5. Navigate to login screen
```

---

## State Management

### Riverpod Providers

#### 1. Authentication Provider
```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>
```
**Manages**: Login, signup, session, user profile

#### 2. Daily Logs Provider
```dart
final dailyLogsProvider = StateNotifierProvider<DailyLogsNotifier, DailyLogsState>
```
**Manages**: Activity logging, date selection, sync status

#### 3. AI Chat Provider
```dart
final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>
```
**Manages**: Chat messages, AI responses, conversation history

#### 4. Prayer Time Provider
```dart
final prayerTimeProvider = FutureProvider<PrayerTimes>
```
**Manages**: Prayer times fetching for current location

#### 5. Progress Provider
```dart
final progressProvider = StateNotifierProvider<ProgressNotifier, ProgressState>
```
**Manages**: Weekly/monthly statistics

### Selector Pattern for Optimization

```dart
// Watch only specific field instead of entire state
ref.watch(dailyLogsProvider.select((state) => state.achievementPercentage));

// Prevents unnecessary rebuilds
```

---

## Service Layer

### SyncService (Cloud ↔ Local Synchronization)

```
┌─ hasInternetConnection()
│  └─ Check Connectivity plugin status
│
├─ fetchFromSupabase(userId)
│  ├─ Check internet
│  ├─ Clear local cache (fresh start)
│  ├─ Query: last 90 days for user
│  ├─ Batch insert to Hive
│  └─ Return FetchResult
│
├─ syncToSupabase()
│  ├─ Get unsynced logs
│  ├─ For each log:
│  │  ├─ Check if exists (user_id, activity_id, date)
│  │  ├─ Insert or update
│  │  └─ Mark as synced
│  └─ Return SyncResult
│
└─ _ensureUserExists(userId)
   ├─ Query users table
   ├─ If not found:
   │  └─ Create from auth session
   └─ Return bool
```

### GeminiService (AI Mentoring)

```
├─ initialize()
│  └─ Set up Gemini client with API key
│
├─ generateWeeklySummary(userId, weekData)
│  ├─ Format achievement data
│  ├─ Call Gemini API
│  ├─ Parse response
│  └─ Save to Supabase
│
└─ sendMessage(context, userMessage)
   ├─ Add message to conversation
   ├─ Call Gemini API with history
   ├─ Stream response
   └─ Save to database
```

### LocalStorageService (Hive + Per-User Isolation)

```
├─ initialize()
│  ├─ Register adapters
│  └─ Open global boxes
│     ├─ user_settings
│     └─ pending_sync
│
├─ openUserBoxes(userId)
│  ├─ Open daily_logs_{userId}
│  ├─ Open weekly_summary_{userId}
│  └─ Set _currentUserId
│
├─ closeUserBoxes()
│  ├─ Close Hive boxes
│  └─ Clear references
│
├─ saveDailyLog(log)
│  ├─ Put to box
│  └─ Mark for sync if not synced
│
└─ clearCurrentUserData()
   ├─ Clear user's daily logs
   └─ Clear user's summaries
```

---

## Data Persistence

### Hive Local Storage

**Why Hive?**
- Type-safe (Dart objects, not JSON strings)
- Fast (binary format)
- Encrypted support
- Zero external dependencies for core
- Per-database boxes for organization

### Box Structure

```
Global Boxes:
├─ user_settings
│  └─ {
│      'current_user': UserModel,
│      'prefs': ...
│    }
└─ pending_sync
   └─ {
       'log_id_1': 'daily_log',
       'log_id_2': 'daily_log'
     }

User-Specific Boxes (opened on login):
├─ daily_logs_{userId}
│  └─ {
│      'log_uuid_1': DailyLogModel,
│      'log_uuid_2': DailyLogModel
│    }
└─ weekly_summary_{userId}
   └─ {
       'summary_uuid_1': WeeklySummaryModel
     }
```

### Supabase Tables

```sql
users (RLS: Only own profile)
├─ id (UUID, primary key)
├─ username (TEXT, unique)
├─ full_name (TEXT)
├─ gender (CHAR)
└─ created_at (TIMESTAMP)

daily_logs (RLS: Only own logs)
├─ id (UUID, primary key)
├─ user_id (FK → users)
├─ activity_id (FK → activities)
├─ date (DATE)
├─ value (INTEGER)
├─ status (CHAR: 'V' or 'X')
└─ UNIQUE(user_id, activity_id, date)

activities (RLS: Readable by all)
├─ id (INTEGER, primary key)
├─ name (TEXT)
├─ target (TEXT)
├─ evaluation_period (TEXT)
└─ threshold (INTEGER)

weekly_summary (RLS: Only own summaries)
├─ id (UUID, primary key)
├─ user_id (FK → users)
├─ week_start (DATE)
├─ ai_review (TEXT)
└─ created_at (TIMESTAMP)
```

---

## Security Model

### Row-Level Security (RLS)

All tables have policies:

```sql
CREATE POLICY "Users can view own X" 
  ON table_name FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own X" 
  ON table_name FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own X" 
  ON table_name FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own X" 
  ON table_name FOR DELETE 
  USING (auth.uid() = user_id);
```

### Per-User Local Storage

```
User A logs in:
├─ Opens daily_logs_uuid_a
├─ Opens weekly_summary_uuid_a
└─ Can't see User B's boxes

User B logs in (after logout):
├─ Closes User A's boxes
├─ Opens daily_logs_uuid_b
├─ Opens weekly_summary_uuid_b
└─ Can't see User A's boxes
```

### Authentication Flow

```
1. Signup: Email → Supabase Auth creates user
   ├─ Trigger: handle_new_user()
   └─ Creates entry in public.users table

2. Login: Credentials → Get session token
   ├─ Session valid for 24 hours
   ├─ Refresh token for renewal
   └─ Stored securely by Supabase

3. Request to API: Token sent in Authorization header
   ├─ Verified by Supabase
   ├─ RLS policies check auth.uid()
   └─ Only authorized data returned
```

---

## Error Handling

### Sync Error Handling

```dart
try {
  // Attempt sync
  await syncToSupabase();
} catch (e) {
  if (e.toString().contains('23503')) {
    // Foreign key error → user not in database
    await _ensureUserExists(userId);
  } else if (e.toString().contains('23505')) {
    // Unique constraint → already exists
    // Update instead of insert
  } else {
    // Generic error → queue for retry
    await LocalStorageService.addToPendingSync(log);
  }
}
```

### Network Error Recovery

```
1. Request fails
   ├─ Check if online
   ├─ If offline: Queue for later
   └─ If online: Retry with exponential backoff

2. Retry Logic
   ├─ Attempt 1: Immediate
   ├─ Attempt 2: +2s delay
   ├─ Attempt 3: +4s delay
   ├─ Attempt 4: +8s delay
   └─ Max 5 attempts, then manual sync

3. Success
   └─ Mark as synced
```

---

## Performance Optimization

### Rebuild Prevention

```dart
// ❌ Rebuilds entire state tree
ref.watch(dailyLogsProvider)

// ✅ Rebuilds only when achievementPercentage changes
ref.watch(dailyLogsProvider.select((state) => state.achievementPercentage))
```

### Lazy Loading

```dart
// Load 90 days on demand, not all time
SyncService.fetchFromSupabase(userId)
  → Query: WHERE date >= (NOW - 90 days)

// Pagination for large datasets (future feature)
```

### Memory Management

```dart
// Proper disposal
@override
void dispose() {
  _chatController.dispose();
  super.dispose();
}

// Limit history in AI chat
if (messages.length > 50) {
  messages.removeAt(0); // FIFO
}
```

### Database Indexing

```sql
-- Fast user queries
CREATE INDEX idx_users_id ON users(id);

-- Fast log queries by date range
CREATE INDEX idx_daily_logs_user_date ON daily_logs(user_id, date);

-- Fast activity lookup
CREATE INDEX idx_activities_id ON activities(id);
```

---

## Conclusion

This architecture provides:
- ✅ Scalability through modular design
- ✅ Security through RLS and encryption
- ✅ Reliability through error handling
- ✅ Performance through optimization
- ✅ Maintainability through clear separation

For questions, refer to code documentation or open an issue.
