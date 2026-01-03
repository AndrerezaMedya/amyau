# Development Setup Guide

Complete step-by-step guide to set up Amal Syarafi development environment.

## Prerequisites

### Required
- **Flutter SDK** 3.x - [Download](https://flutter.dev/docs/get-started/install)
- **Dart SDK** 3.x - (Included with Flutter)
- **Git** - [Download](https://git-scm.com)
- **Android Studio** - [Download](https://developer.android.com/studio) (for Android development)
- **Supabase Account** - [Free tier](https://supabase.com)
- **Google Gemini API Key** - [Get key](https://aistudio.google.com)

### Optional
- **Xcode** - For iOS development (macOS only)
- **Visual Studio Code** - Code editor
- **Android Emulator** or physical device
- **Chrome** - For web development

---

## 1. Install Flutter

### Windows / macOS / Linux

```bash
# Extract Flutter SDK to desired location
# Add to PATH

# Verify installation
flutter --version
dart --version

# Check dependencies
flutter doctor
```

### Expected Output
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, version 3.x.x)
[✓] Android toolchain
[✓] Chrome
[✓] Visual Studio Code
[✓] Connected device
```

---

## 2. Clone Repository

```bash
# Clone the repository
git clone https://github.com/AndrerezaMedya/amyau.git
cd amyau

# Set main branch (if not already)
git branch -M main

# Add upstream for syncing
git remote add upstream https://github.com/AndrerezaMedya/amyau.git
```

---

## 3. Install Dependencies

```bash
# Get all packages
flutter pub get

# Get packages in subdirectories
flutter pub get --recursive

# Upgrade packages to latest versions (optional)
flutter pub upgrade
```

### Generated Files
This will generate:
- `.dart_tool/` - Dart compilation files
- `.packages` - Package references
- `pubspec.lock` - Locked dependency versions

---

## 4. Configure Supabase

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Enter:
   - **Name**: `amal-syarafi` (or your preference)
   - **Password**: Strong password
   - **Region**: Closest to you (e.g., Singapore)
4. Wait for project to initialize (2-3 minutes)

### Step 2: Get Credentials

```
Project Settings → API
├─ Project URL      → Copy to supabaseUrl
├─ Anon Key (PUBLIC) → Copy to supabaseAnonKey
└─ Service Role Key  → Keep private
```

### Step 3: Create Constants File

Create `lib/core/constants/supabase_constants.dart`:

```dart
/// Konfigurasi Supabase
/// ⚠️ Ganti dengan kredensial Supabase Anda
class SupabaseConstants {
  SupabaseConstants._();

  /// URL Supabase project Anda
  static const String supabaseUrl = 'https://your-project.supabase.co';

  /// Anon key Supabase project Anda
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

  /// Nama tabel di Supabase
  static const String usersTable = 'users';
  static const String activitiesTable = 'activities';
  static const String dailyLogsTable = 'daily_logs';
  static const String weeklySummaryTable = 'weekly_summary';
}
```

### Step 4: Run Database Schema

1. Go to Supabase Dashboard → SQL Editor
2. Click "New Query"
3. Copy entire content from `supabase/schema.sql`
4. Paste into SQL Editor
5. Click "Run"

Expected output:
```
✓ execute success
```

### Step 5: Verify Setup

```bash
# Test Supabase connection in your app
# Run app and try to login - should show authentication screens
```

---

## 5. Configure Google Gemini API

### Step 1: Get API Key

1. Go to [aistudio.google.com](https://aistudio.google.com)
2. Click "Get API Key"
3. Click "Create API key in new Google Cloud project"
4. Copy the API key

### Step 2: Create Constants File

Create `lib/core/constants/gemini_constants.dart`:

```dart
/// Konfigurasi Google Gemini API
/// ⚠️ Ganti dengan API key Anda
class GeminiConstants {
  GeminiConstants._();

  /// Google Gemini API Key
  /// Get from: https://aistudio.google.com/app/apikey
  static const String apiKey = 'AIza...(your key)...';

  /// Model yang digunakan
  static const String model = 'gemini-2.0-flash';

  /// System prompt untuk Syeikh Syarafi
  static const String systemPrompt = '''
Anda adalah Syeikh Syarafi, seorang mentor spiritual yang berpengalaman...
  ''';
}
```

### Step 3: Enable API (Optional)

If you get quota errors:
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project
3. Enable "Google Generative AI API"
4. Check quota limits

---

## 6. Setup Android Development (Optional)

### Prerequisites
- Android Studio installed
- Android SDK (API 34 for targetSdk)
- Android SDK cmdline-tools

### Configuration

Open `android/app/build.gradle.kts`:

```gradle
android {
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.amalsyarafi.app"
        minSdk = 23
        targetSdk = 34
    }
}
```

### Create Emulator

```bash
# List available devices
flutter emulators

# Create new device
flutter emulators create --name pixel-5

# Launch emulator
flutter emulators launch pixel-5
```

### Build APK (Debug)

```bash
# Build debug APK
flutter build apk

# Install on device
flutter install

# Or run directly
flutter run
```

---

## 7. Setup iOS Development (macOS Only)

### Prerequisites
- Xcode installed
- Cocoapods

### Installation

```bash
# Get iOS dependencies
cd ios
pod install
cd ..

# Run on iOS simulator
flutter run -d ios
```

---

## 8. Run Application

### Web (Easiest to start)

```bash
flutter run -d chrome
```

### Android

```bash
# Ensure Android device/emulator is connected
flutter devices  # List devices

# Run
flutter run -d android  # or device ID
```

### iOS (macOS)

```bash
flutter run -d ios
```

---

## 9. Code Quality Setup

### Run Analysis

```bash
# Check for issues
flutter analyze

# Fix common issues automatically
dart fix --apply
```

### Code Formatting

```bash
# Format all Dart files
dart format lib/

# Format specific file
dart format lib/main.dart
```

### Build Checks

```bash
# Check if app builds
flutter build apk --debug  # Android
flutter build web --debug  # Web
flutter build ios --debug  # iOS (macOS only)
```

---

## 10. Git Workflow

### Create Feature Branch

```bash
# Update main
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature

# Or fix branch
git checkout -b fix/bug-name
```

### Make Changes & Commit

```bash
# See what changed
git status

# Stage changes
git add lib/

# Commit with message
git commit -m "feat: add new feature description"

# Push to your fork
git push origin feature/your-feature
```

### Create Pull Request

1. Go to [GitHub](https://github.com/AndrerezaMedya/amyau)
2. You should see "Compare & pull request" button
3. Fill in PR template
4. Submit

---

## 11. Troubleshooting

### Issue: `Flutter SDK not found`

```bash
# Add Flutter to PATH

# Windows (PowerShell):
$env:Path += ";C:\path\to\flutter\bin"

# macOS/Linux:
export PATH="$PATH:~/path/to/flutter/bin"
```

### Issue: `Supabase connection failed`

- Check URL and key in `supabase_constants.dart`
- Verify Supabase project is running
- Check internet connection
- Check firewall/VPN blocking

### Issue: `Gemini API quota exceeded`

- Check quota at [Google Cloud Console](https://console.cloud.google.com)
- Wait for quota reset (usually monthly)
- Upgrade to paid plan if needed

### Issue: `Android build fails`

```bash
# Clean gradle cache
cd android
./gradlew clean
cd ..

# Rebuild
flutter clean
flutter pub get
flutter build apk --debug
```

### Issue: `Pod install fails (iOS)`

```bash
# Update pods
cd ios
rm Podfile.lock
pod install
cd ..

# Or clean and reinstall
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

---

## 12. Environment Variables (Advanced)

### Using .env file (Optional)

1. Create `.env` file in project root:

```
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=eyJ...
GEMINI_API_KEY=AIza...
```

2. Add to `.gitignore`

3. Load in main.dart:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}
```

---

## 13. Development Tools

### Recommended Extensions (VS Code)

```
Dart
Flutter
Supabase
Thunder Client (API testing)
SQLTools (Database management)
```

### DevTools

```bash
# Launch DevTools
flutter pub global activate devtools
devtools

# Connect to running app
# Follow on-screen instructions
```

---

## 14. Performance Testing

### Profile App

```bash
# Profile with --profile flag
flutter run --profile

# Track performance
# Use DevTools → Performance tab
```

### Benchmark

```bash
# Run benchmarks (if available)
flutter test --profile
```

---

## Final Verification

```bash
# Run all checks
flutter doctor          # Dependencies
flutter analyze        # Code issues
dart format lib/ -n   # Check formatting

# Build all platforms
flutter build apk      # Android
flutter build web      # Web
flutter build ios      # iOS (macOS only)
```

If everything shows ✓, you're ready to develop!

---

## Next Steps

1. Read [README.md](README.md) for feature overview
2. Study [ARCHITECTURE.md](ARCHITECTURE.md) for system design
3. Review [CONTRIBUTING.md](CONTRIBUTING.md) for code guidelines
4. Start with small feature or bug fix

Happy coding! 🚀

---

## Support

Having issues? 
- 📋 Check [Troubleshooting](#11-troubleshooting) section
- 🐛 [Open an issue](https://github.com/AndrerezaMedya/amyau/issues)
- 💬 [Start a discussion](https://github.com/AndrerezaMedya/amyau/discussions)
