# Amal Syarafi - Islamic Daily Practice Tracking App

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Stars](https://img.shields.io/github/stars/AndrerezaMedya/amyau?style=social)](https://github.com/AndrerezaMedya/amyau)

A sophisticated Flutter application for tracking daily Islamic practices (_Mutabaah Yaumi_) with AI-powered mentoring and comprehensive progress analytics.

[Features](#-features) • [Tech Stack](#-tech-stack) • [Setup](#-setup) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## 📱 Overview

**Amal Syarafi** is a production-ready mobile app designed for Islamic mentoring groups to track 12 daily spiritual activities with:

- ✅ Real-time cloud synchronization via Supabase
- 🤖 AI mentoring assistant powered by Google Gemini 3.0 Flash (preview)
- 📊 Advanced analytics with weekly/monthly progress tracking
- 🔐 Secure per-user data isolation with RLS policies
- 🌐 Cross-platform support (Android, iOS, Web)
- 📴 Offline-first architecture with Hive storage

---

## ✨ Features

### Core Functionality

- **12-Activity Dashboard** - Structured Islamic practices (Quran, Tahajud, Infaq, etc.)
- **Smart Status Calculation** - Daily, Weekly, and Monthly evaluation periods
- **Real-time Synchronization** - Offline-capable with auto-sync when connected
- **Per-User Data Isolation** - Secure storage with RLS enforcement

### AI & Analytics

- **Syeikh Syarafi AI Assistant** - Interactive chat for guidance and motivation
- **Weekly Progress Reviews** - AI-generated summaries of achievements
- **Visual Analytics** - Progress cards and monthly statistics
- **Smart Notifications** - Context-aware prayer time reminders with WIB timezone

### Technical Features

- **Multi-Device Sync** - Seamless data consistency across devices
- **Secure Authentication** - Supabase Auth with email/password
- **Offline Support** - Complete functionality without internet
- **Production Grade** - Error handling, retry logic, and recovery mechanisms

---

## 🛠 Tech Stack

| Category             | Technology                                    |
| -------------------- | --------------------------------------------- |
| **Frontend**         | Flutter 3.x, Material Design 3, Riverpod 2.4+ |
| **Backend**          | Supabase (PostgreSQL, Auth, RLS)              |
| **AI**               | Google Gemini 2.0 Flash API                   |
| **Local Storage**    | Hive (encrypted, typed)                       |
| **State Management** | Riverpod (reactive, typesafe)                 |
| **APIs**             | Aladhan (Prayer Times), Geocoding             |
| **Notifications**    | flutter_local_notifications (Android 14+)     |

---

## 📋 Prerequisites

- **Flutter SDK** - v3.0.0 or higher
- **Dart SDK** - v3.0.0 or higher
- **Android SDK** - minSdk=23, targetSdk=34
- **Supabase Account** - [Create free account](https://supabase.com)
- **Google Gemini API Key** - [Get API key](https://aistudio.google.com)

---

## 🚀 Setup Instructions

### 1. Clone Repository

```bash
git clone https://github.com/AndrerezaMedya/amyau.git
cd amyau
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

#### a. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Copy **Project URL** and **Anon Key**

#### b. Run Database Schema

```bash
# Copy schema.sql content and run in Supabase SQL Editor
supabase/schema.sql
```

#### c. Update Constants

Create `lib/core/constants/supabase_constants.dart`:

```dart
class SupabaseConstants {
  SupabaseConstants._();

  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
  static const String usersTable = 'users';
  static const String activitiesTable = 'activities';
  static const String dailyLogsTable = 'daily_logs';
  static const String weeklySummaryTable = 'weekly_summary';
}
```

### 4. Configure Google Gemini API

Create `lib/core/constants/gemini_constants.dart`:

```dart
class GeminiConstants {
  GeminiConstants._();

  static const String apiKey = 'YOUR_GEMINI_API_KEY';
  static const String model = 'gemini-2.0-flash';
}
```

### 5. Run Application

```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

---

## 🏗 Architecture & Project Structure

```
lib/
├── main.dart                          # App entry point
│
├── core/
│   ├── constants/
│   │   ├── supabase_constants.dart    # Supabase config
│   │   ├── activity_constants.dart    # 12 activities definition
│   │   └── gemini_constants.dart      # AI config
│   │
│   ├── services/                      # Business logic
│   │   ├── local_storage_service.dart # Hive + per-user isolation
│   │   ├── sync_service.dart          # Cloud sync orchestration
│   │   ├── gemini_service.dart        # AI chat & analysis
│   │   ├── notification_service.dart  # Local notifications
│   │   ├── prayer_time_service.dart   # Aladhan API integration
│   │   ├── location_service.dart      # Geocoding & permissions
│   │   └── timezone_helper.dart       # WIB timezone utilities
│   │
│   ├── theme/
│   │   └── app_theme.dart            # Material Design 3 theme
│   │
│   └── utils/
│       └── status_calculator.dart    # Status evaluation logic
│
├── models/                            # Data classes
│   ├── user_model.dart
│   ├── activity_model.dart
│   ├── daily_log_model.dart
│   ├── weekly_summary_model.dart
│   └── ai_message_model.dart
│
├── providers/                         # Riverpod state management
│   ├── auth_provider.dart
│   ├── daily_logs_provider.dart
│   ├── progress_provider.dart
│   ├── prayer_time_provider.dart
│   └── ai_chat_provider.dart
│
├── features/                          # Feature modules (Clean Architecture)
│   ├── auth/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── signup_screen.dart
│   │       └── widgets/
│   │
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── screens/dashboard_screen.dart
│   │       └── widgets/
│   │           ├── activity_card.dart
│   │           ├── daily_summary_card.dart
│   │           ├── date_selector.dart
│   │           └── prayer_time_card.dart
│   │
│   ├── progress/
│   │   └── presentation/screens/progress_screen.dart
│   │
│   └── dashboard/ai_agent/
│       └── presentation/screens/ai_chat_screen.dart
│
└── shared/
    └── widgets/                       # Common widgets
```

### Data Flow Architecture

```
┌─────────────────┐
│   Flutter UI    │
└────────┬────────┘
         │
    ┌────v────────────────┐
    │ Riverpod Providers  │ ◄─── State Management
    └────┬────────────────┘
         │
    ┌────v──────────────┐
    │ Core Services    │
    │ ├─ Local Storage │ ◄─── Per-user Hive boxes
    │ ├─ Sync Service  │ ◄─── Cloud orchestration
    │ ├─ Gemini AI     │ ◄─── AI analysis
    │ └─ Notifications │ ◄─── Local alerts
    └────┬──────────────┘
         │
    ┌────v──────────────────┐
    │   Supabase Backend    │
    │ ├─ PostgreSQL DB      │
    │ ├─ RLS Policies       │
    │ └─ Real-time Sub      │
    └───────────────────────┘
```

---

## 🔐 Security Features

### Data Isolation

- **Per-User Hive Boxes**: Each user has isolated local storage with box names like `daily_logs_{userId}`
- **RLS Policies**: Row-Level Security on all Supabase tables
- **Auth Guards**: User verification before operations

### Synchronization

- **Source of Truth**: Supabase is authoritative source
- **Check-Then-Insert**: Prevents 409 conflicts
- **Clean on Login**: Fresh fetch and local cache clearing
- **Clear on Logout**: Complete data wipe for privacy

---

## 📊 Database Schema

### Tables

| Table            | Purpose                          | RLS |
| ---------------- | -------------------------------- | --- |
| `users`          | User profiles & metadata         | ✅  |
| `activities`     | 12 Islamic practices definition  | ✅  |
| `daily_logs`     | Activity status per user per day | ✅  |
| `weekly_summary` | AI-generated weekly reviews      | ✅  |

### Key Constraints

```sql
-- Unique daily log per user per activity per day
UNIQUE(user_id, activity_id, date)

-- Foreign key enforcement
daily_logs.user_id → users.id

-- Auto-trigger for profile creation
TRIGGER on_auth_user_created
```

---

## 🚢 Building & Deployment

### Build APK (Android Release)

```bash
export JAVA_HOME="$ANDROID_STUDIO_HOME/jbr"
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build AAB (Google Play)

```bash
flutter build appbundle --release
```

### Build Web

```bash
flutter build web --release
```

---

## 🐛 Debugging & Troubleshooting

### Common Issues

**Foreign Key Constraint Error**

```
PostgrestException: Key is not present in table "users"
```

✅ _Solution_: App auto-creates user profile. Check trigger `handle_new_user()` is enabled.

**Data Not Syncing**

```
Check connectivity → Clear app cache → Restart
```

**Notifications Not Working (Android 14+)**

```
Verify android/app/build.gradle.kts has:
- targetSdk >= 33
- POST_NOTIFICATIONS permission in manifest
```

---

## 📈 Features Roadmap

- [x] Core activity tracking
- [x] Per-user data isolation
- [x] Cloud synchronization
- [x] AI mentoring assistant
- [x] Prayer times integration
- [ ] Group statistics & leaderboards
- [ ] Custom activity templates
- [ ] Offline-first conflict resolution
- [ ] Export reports (PDF/CSV)
- [ ] Dark mode theme

---

## 📚 Documentation

- [Flutter Docs](https://flutter.dev/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Gemini API Docs](https://ai.google.dev/docs)
- [Riverpod Guide](https://riverpod.dev)

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** changes (`git commit -m 'Add amazing feature'`)
4. **Push** to branch (`git push origin feature/amazing-feature`)
5. **Open** Pull Request

### Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Run `dart format` before commit
- Use `flutter analyze` for linting

---

## 📄 License

This project is licensed under the **MIT License** - see [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Andrez Medya**

- GitHub: [@AndrerezaMedya](https://github.com/AndrerezaMedya)
- Email: andrez@example.com

---

## 🙏 Acknowledgments

- Flutter & Dart team for amazing framework
- Supabase for backend infrastructure
- Google Gemini for AI capabilities
- Islamic mentoring community for inspiration

---

<div align="center">

**Built with ❤️ using Flutter & Supabase**

[⬆ back to top](#amal-syarafi---islamic-daily-practice-tracking-app)

</div>

│ │ └── ai_agent/
│ │ └── presentation/screens/ai_chat_screen.dart
│ └── progress/
│ └── presentation/screens/progress_screen.dart
└── shared/
└── utils/
└── status_calculator.dart

````

## 📋 12 Aktivitas Yaumi

| No | Aktivitas | Target | Evaluasi |
|----|-----------|--------|----------|
| 1 | Membaca Al-Qur'an | 1 juz/hari | ≥50% = V |
| 2 | Membaca Al-Ma'tsurat | Pagi/Petang | ≥50% = V |
| 3 | Tahajud | Setiap hari | ≥50% = V |
| 4 | Puasa Sunnah | 2-3 hari/bulan | Dilaksanakan = V |
| 5 | Memperbanyak Istighfar | Setiap hari | ≥50% = V |
| 6 | Memperbanyak Sholawat | Setiap hari | ≥50% = V |
| 7 | Mendoakan kebaikan | Setiap hari | ≥50% = V |
| 8 | Shalat berjamaah | 3 kali/hari | ≥50% = V |
| 9 | Persiapan pertemuan pekanan | 2 kali/bulan | Dilaksanakan = V |
| 10 | Infaq mingguan | Setiap anggota | ≥50% = V |
| 11 | Membaca artikel/video dakwah | 1 kali/minggu | Dilaksanakan = V |
| 12 | Mengikuti MABIT | 1 kali | Dilaksanakan = V |

## 🚀 Setup

### 1. Prerequisites

- Flutter SDK 3.0+
- Akun Supabase
- API Key Gemini

### 2. Clone & Install

```bash
git clone <repo-url>
cd mutabaah-yaumi
flutter pub get
````

### 3. Konfigurasi Supabase

1. Buat project di [Supabase](https://supabase.com)
2. Jalankan SQL di `supabase/schema.sql`
3. Update `lib/core/constants/supabase_constants.dart`:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### 4. Konfigurasi Gemini AI

1. Dapatkan API key dari [Google AI Studio](https://makersuite.google.com)
2. Update `lib/core/constants/gemini_constants.dart`:

```dart
static const String apiKey = 'YOUR_GEMINI_API_KEY';
```

### 5. Generate Hive Adapters

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 6. Run

```bash
flutter run
```

## 👥 Menambahkan User

Karena registrasi private, admin perlu menambahkan user via Supabase Dashboard:

1. Buka Supabase Dashboard → Authentication → Users
2. Klik "Add user" → Masukkan email & password
3. User profile akan otomatis dibuat via trigger

## 🔔 Jadwal Notifikasi

| Waktu | Reminder                    |
| ----- | --------------------------- |
| 05:00 | Pengingat Tahajud & Tilawah |
| 15:30 | Pengingat Al-Ma'tsurat Sore |
| 21:00 | Evaluasi Harian & AI Review |

## 🤖 AI Agent Features

- **Analisis Harian** - Ringkasan pencapaian hari ini
- **Analisis Mingguan** - Pola dan tren ibadah
- **Chat Interaktif** - Tanya jawab seputar ibadah
- **Motivasi** - Pesan semangat dalam Bahasa Indonesia

## 📱 Screenshots

_Coming soon_

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.x
- **State Management**: Riverpod
- **Backend**: Supabase (Auth + PostgreSQL)
- **Local Storage**: Hive
- **AI**: Google Gemini (gemini-2.0-flash)
- **Notifications**: flutter_local_notifications

## 📄 License

Private - Untuk kelompok mentoring internal.
