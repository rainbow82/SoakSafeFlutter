#!/usr/bin/env bash
#
# run_dev.sh — build, install, and launch SoakSafe on an Android device/emulator.
#
# Why this exists: the app uses Duolingo-style dynamic launcher icons, where the
# MAIN/LAUNCHER intent filters live only on the activity-aliases (LauncherHappy/
# Sad/Storm), not on MainActivity. `aapt` doesn't report aliases as a launchable
# activity, so `flutter run` can't auto-detect what to start and bails out with
# "package identifier or launch activity not found". This script does the build +
# install + launch manually, starting MainActivity directly (it's exported), which
# works no matter which icon alias is currently enabled.
#
# Usage:
#   tool/run_dev.sh                 # debug build on the first connected device
#   tool/run_dev.sh --release       # release build
#   tool/run_dev.sh -d emulator-5554  # target a specific device
#
set -euo pipefail

APP_ID="com.shannonbeach.soaksafe"
ACTIVITY="${APP_ID}/.MainActivity"

# Resolve adb: prefer PATH, fall back to the standard SDK location.
if command -v adb >/dev/null 2>&1; then
  ADB="adb"
elif [[ -x "${ANDROID_HOME:-}/platform-tools/adb" ]]; then
  ADB="${ANDROID_HOME}/platform-tools/adb"
elif [[ -x "${ANDROID_SDK_ROOT:-}/platform-tools/adb" ]]; then
  ADB="${ANDROID_SDK_ROOT}/platform-tools/adb"
elif [[ -x "$HOME/Library/Android/sdk/platform-tools/adb" ]]; then
  ADB="$HOME/Library/Android/sdk/platform-tools/adb"
else
  echo "error: adb not found. Set ANDROID_HOME or add platform-tools to PATH." >&2
  exit 1
fi

BUILD_MODE="debug"
DEVICE_ARG=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release) BUILD_MODE="release"; shift ;;
    --debug)   BUILD_MODE="debug"; shift ;;
    -d|--device) DEVICE_ARG=(-s "$2"); shift 2 ;;
    *) echo "error: unknown argument: $1" >&2; exit 1 ;;
  esac
done

# Move to the Flutter project root (parent of this script's tool/ dir).
cd "$(dirname "$0")/.."

echo "==> Building $BUILD_MODE APK..."
flutter build apk "--$BUILD_MODE"

APK="build/app/outputs/flutter-apk/app-${BUILD_MODE}.apk"
if [[ ! -f "$APK" ]]; then
  echo "error: expected APK not found at $APK" >&2
  exit 1
fi

echo "==> Installing $APK ..."
"$ADB" "${DEVICE_ARG[@]}" install -r "$APK"

echo "==> Launching $ACTIVITY ..."
"$ADB" "${DEVICE_ARG[@]}" shell am start -n "$ACTIVITY"

echo "==> Done. SoakSafe ($BUILD_MODE) is running."
