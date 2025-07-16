#!/usr/bin/env bash
# Scripts/ci-test.sh  –  Build & run RoomRoster tests in CI.
set -euo pipefail

###############################################################################
# 1.  Stub the plist files the app expects
###############################################################################
mkdir -p RoomRoster/RoomRoster/RoomRoster

cat > RoomRoster/RoomRoster/RoomRoster/Secrets.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>API_KEY</key> <string>${CI_FAKE_API_KEY:-ci-fake-key}</string>
  <key>SHEET_ID</key><string>${CI_FAKE_SHEET_ID:-ci-fake-sheet-id}</string>
</dict></plist>
EOF

cat > RoomRoster/RoomRoster/RoomRoster/GoogleService-Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>BUNDLE_ID</key><string>com.example.ci</string>
</dict></plist>
EOF

###############################################################################
# 2.  Select a valid simulator UDID (robust across Xcode versions)
###############################################################################
if [[ -n "${CI_SIM_UDID:-}" ]]; then
  SIM_UDID="$CI_SIM_UDID"               # let callers pin a specific device
else
  # Grab the first 36-char UUID from the “available” list (skips header lines)
  SIM_UDID=$(xcrun simctl list devices available \
             | grep -Eo '[0-9A-F-]{36}' \
             | head -n1)
fi

echo "ℹ️  Using simulator UDID: $SIM_UDID"
xcrun simctl bootstatus "$SIM_UDID" -b >/dev/null   # wait until it’s ready

###############################################################################
# 3.  Build & test (iOS slice only)
###############################################################################
OTHER_FLAGS="${OTHER_SWIFT_FLAGS:-"-Xfrontend -enable-experimental-feature -Xfrontend AccessLevelOnImport -Xfrontend -enable-experimental-feature -Xfrontend TypedThrows"}"

set -o pipefail
xcodebuild test \
  -project RoomRoster.xcodeproj \
  -scheme RoomRoster \
  -sdk iphonesimulator \
  -destination "id=$SIM_UDID" \
  CODE_SIGNING_ALLOWED=NO \
  OTHER_SWIFT_FLAGS="$OTHER_FLAGS"
