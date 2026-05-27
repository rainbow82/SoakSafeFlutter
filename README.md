# SoakSafe (Flutter)

Cross-platform **pool maintenance tracker** for **Android** and **iOS**, migrated from the native Android capstone app.

- **Single repo** for Play Store + App Store
- **Local-first** SQLite storage (same schema as the Room app)
- **Compatible password hashes** with the Android app (`SS1$` PBKDF2)
- **Package / bundle ID:** `com.shannonbeach.soaksafe`

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable, 3.16+)
- Xcode (iOS builds, macOS only)
- Android Studio / SDK (Android builds)

## Getting started

```bash
cd ~/Documents/repos/SoakSafe
flutter pub get
flutter run
```

## Project structure

```
lib/
  core/          # theme, database, security, codecs
  data/          # repositories
  screens/       # UI (home, maintenance, reports, profile)
  widgets/       # pool background, frosted cards, buttons
  router/        # go_router navigation
```

## Store release

### Android (Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

- `applicationId`: `com.shannonbeach.soaksafe` (in `android/app/build.gradle.kts`)
- Add your signing config before production upload
- `android/app/google-services.json` is included for Firebase App Distribution

### iOS (App Store)

```bash
flutter build ipa --release
```

- Bundle ID: `com.shannonbeach.soaksafe` (Xcode → Runner target)
- Configure signing team in Xcode
- Add `NSFaceIDUsageDescription` / photo permissions in `Info.plist` as needed

## Firebase CI

Workflow: `.github/workflows/firebase-app-distribution.yml`

GitHub Actions secrets:

- `FIREBASE_SERVICE_ACCOUNT_JSON` — service account key (not `google-services.json`)
- Optional: `FIREBASE_APP_ID`, `FIREBASE_TESTER_GROUPS`, `FIREBASE_TESTER_EMAILS`

Runs on push to `main` or `working`, builds `flutter build apk --debug`, and distributes via Firebase App Distribution.

## Migration notes

| Native Android | Flutter |
|----------------|---------|
| Room `soaksafe.db` | sqflite same table/column names |
| `PasswordHasher.java` | `lib/core/security/password_hasher.dart` |
| Activities + ViewBinding | Screens + Material widgets |
| `bg_home_pool.jpg` | `assets/images/bg_home_pool.jpg` |

**Not yet ported (follow-up):** profile photo upload, dynamic launcher icons, full parity with every Android dialog.

## Original repo

The native Android capstone lives at `d424-software-engineering-capstone`. This repo replaces it for ongoing store releases.
