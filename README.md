# SoakSafeFlutter

Cross-platform **pool maintenance tracker** for **Android** and **iOS**, migrated from the native Android app.

- **Repo:** [github.com/rainbow82/SoakSafeFlutter](https://github.com/rainbow82/SoakSafeFlutter)
- **Local-first** SQLite storage (same schema as the Room app)
- **Compatible password hashes** with the Android app (`SS1$` PBKDF2)
- **Package / bundle ID:** `com.shannonbeach.soaksafe`

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable, 3.16+)
- Xcode (iOS builds, macOS only)
- Android Studio / SDK (Android builds)

### Make `adb` available on your PATH (macOS / zsh)

The Android SDK ships `adb`, but it is not on the shell PATH by default. Add the
SDK's `platform-tools` directory to your shell profile so the build scripts and
commands below can find it:

```bash
echo 'export ANDROID_HOME="$HOME/Library/Android/sdk"' >> ~/.zshrc
echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"' >> ~/.zshrc
source ~/.zshrc
adb version   # verify
```

## Getting started

```bash
cd ~/Documents/repos/SoakSafeFlutter
flutter pub get
```

> **Note on `flutter run`:** the standard `flutter run` command **does not work**
> for this app — see [Running on a device or emulator](#running-on-a-device-or-emulator).
> Use `tool/run_dev.sh` instead.

## Project structure

```
lib/
  core/          # theme, database, security, codecs
  data/          # repositories
  screens/       # UI (home, maintenance, reports, profile)
  widgets/       # pool background, frosted cards, buttons
  router/        # go_router navigation
tool/
  run_dev.sh     # build + install + launch helper (see below)
```

## Running on a device or emulator

### Why not plain `flutter run`?

This app uses **Duolingo-style dynamic launcher icons** (the pool icon turns
happy / sad / stormy depending on how overdue maintenance is). The
`MAIN`/`LAUNCHER` intent filters live only on the activity-aliases
(`LauncherHappy` / `LauncherSad` / `LauncherStorm`) in
`android/app/src/main/AndroidManifest.xml`, **not** on `MainActivity`.

`aapt` does not report activity-aliases as a launchable activity, so Flutter's
tooling cannot auto-detect what to start and fails with:

```
package identifier or launch activity not found.
No application found for TargetPlatform.android_arm64.
```

This is expected — it is the cost of keeping the dynamic icons. There is no hot
reload via `flutter run`; instead, use the helper script below (an incremental
debug rebuild is only a few seconds).

### Helper script: `tool/run_dev.sh`

Builds, installs, and launches `MainActivity` directly (it is `exported`), which
works no matter which icon alias is currently enabled:

```bash
./tool/run_dev.sh                    # debug build, first connected device
./tool/run_dev.sh -d emulator-5554   # target a specific device
./tool/run_dev.sh --release          # release build
```

The script auto-locates `adb` via `PATH`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`, or
the default macOS SDK path.

### Launch an emulator

```bash
flutter emulators                       # list available emulators
flutter emulators --launch <emulator_id>
# then:
./tool/run_dev.sh
```

### Manual equivalent (what the script does)

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.shannonbeach.soaksafe/.MainActivity
```

## Android builds

Key config in `android/app/build.gradle.kts`: `applicationId` =
`com.shannonbeach.soaksafe`, `minSdk` = 26, `compileSdk` = 36, Java/Kotlin 17.

### Debug APK (test on a physical device)

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

Install on a USB-connected device (enable **Developer options → USB debugging**
first):

```bash
adb devices                                                   # confirm device shows
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.shannonbeach.soaksafe/.MainActivity
```

View logs while testing:

```bash
adb logcat | grep -i soaksafe
```

### Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> The release build currently signs with the **debug keystore**
> (`signingConfig = signingConfigs.getByName("debug")` in `build.gradle.kts`),
> so a release APK installs and runs without extra setup. Replace this with a
> real signing config before any production / Play Store upload (see below).

### Release App Bundle (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Production signing config

1. Create (or reuse) a keystore:

   ```bash
   keytool -genkey -v -keystore ~/soaksafe-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties` (do **not** commit it):

   ```properties
   storePassword=********
   keyPassword=********
   keyAlias=upload
   storeFile=/absolute/path/to/soaksafe-upload.jks
   ```

3. Wire it into `android/app/build.gradle.kts` (`signingConfigs { create("release") { ... } }`)
   and point the `release` build type at it instead of the debug config.

## iOS builds

Bundle ID: `com.shannonbeach.soaksafe` (Xcode → Runner target). Signing team and
`CODE_SIGN_STYLE = Automatic` are set in `ios/Runner.xcodeproj/project.pbxproj`.

```bash
cd ios && pod install && cd ..   # first time / after dependency changes
```

### Run on a connected iPhone

1. Open `ios/Runner.xcworkspace` in Xcode once and set your **Signing &
   Capabilities → Team** (a free Apple ID works for on-device testing).
2. On the iPhone: enable **Settings → Privacy & Security → Developer Mode**.
3. Build and install:

   ```bash
   flutter build ios --debug
   # or deploy straight to the device:
   xcrun devicectl device install app --device <udid> \
     build/ios/iphoneos/Runner.app
   ```

4. First launch only: on the iPhone go to **Settings → General → VPN & Device
   Management** and **trust** your developer certificate, otherwise iOS blocks
   the app with an "untrusted developer" / "invalid code signature" error.

### Release IPA (App Store / TestFlight)

```bash
flutter build ipa --release
# Output: build/ios/ipa/*.ipa
```

- Requires a **paid** Apple Developer Program membership ($99/yr) for
  distribution (ad hoc or TestFlight).
- Add `NSFaceIDUsageDescription` / photo permissions in `Info.plist` as needed.

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

**Not yet ported (follow-up):** full parity with every Android dialog.

## Original repo

The native Android app lives in [SoakSafe](https://github.com/rainbow82/SoakSafe) (`working` branch). The WGU capstone copy is at `d424-software-engineering-capstone`.
