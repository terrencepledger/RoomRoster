#!/usr/bin/env bash
# Scripts/ci-test.sh
# Purpose: Build + test the iOS slice of RoomRoster in CI.

set -euo pipefail

###############################################################################
# 1.  Stub the plist files the app expects at build time
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
# 2.  Build + test (iOS slice only)
###############################################################################
OTHER_FLAGS="${OTHER_SWIFT_FLAGS:-"-Xfrontend -enable-experimental-feature -Xfrontend AccessLevelOnImport -Xfrontend -enable-experimental-feature -Xfrontend TypedThrows"}"

echo "📦  Running tests on the first available iOS simulator (OS=latest)"
set -o pipefail
xcodebuild test \
  -project RoomRoster.xcodeproj \
  -scheme RoomRoster \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,OS=latest' \
  CODE_SIGNING_ALLOWED=NO \
  OTHER_SWIFT_FLAGS="$OTHER_FLAGS"
