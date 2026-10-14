#!/bin/bash
# Captures App Store-style screenshots of a Debug simulator build into docs/screenshots.
# Usage: scripts/screenshots.sh path/to/Minimal.app
set -euo pipefail

APP="$1"
OUT="docs/screenshots"
mkdir -p "$OUT"

UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
best = None
for runtime, entries in devices.items():
    if ".iOS-" not in runtime:
        continue
    version = tuple(int(x) for x in runtime.split(".iOS-")[1].split("-"))
    for device in entries:
        name = device["name"]
        if name.startswith("iPhone") and name.endswith("Pro"):
            key = (version, name)
            if best is None or key > best[0]:
                best = (key, device["udid"], name)
print(best[1])
print(best[2], best[0][0], file=sys.stderr)
')

BUNDLE=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")

xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl ui "$UDID" appearance dark
xcrun simctl status_bar "$UDID" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
xcrun simctl install "$UDID" "$APP"

shot() {
  sleep "${2:-2}"
  xcrun simctl io "$UDID" screenshot --type=png "$OUT/$1.png" >/dev/null
  sips --resampleWidth 600 "$OUT/$1.png" >/dev/null
  echo "captured $1"
}

relaunch() {
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  xcrun simctl launch "$UDID" "$BUNDLE" "$@" >/dev/null
}

for step in 0 1 2 3; do
  relaunch -pref.onboarded NO -debug.onboardingStep "$step"
  shot "onboarding-$step" 4
done

relaunch -pref.onboarded YES
shot home 4

xcrun simctl openurl "$UDID" "minimal://search"
shot search 3

xcrun simctl openurl "$UDID" "minimal://home"
sleep 1
xcrun simctl openurl "$UDID" "minimal://debug-pause"
shot pause 3

relaunch -pref.onboarded YES
sleep 2
xcrun simctl openurl "$UDID" "minimal://shield"
shot shield 4

relaunch -pref.onboarded YES
sleep 2
xcrun simctl openurl "$UDID" "minimal://settings"
shot settings 3
