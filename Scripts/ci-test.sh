#!/usr/bin/env bash
# Scripts/ci-test.sh
set -euo pipefail

###############################################################################
# 1.  Stub the plist files your build expects
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
# 2.  Choose a simulator that actually exists on whatever Xcode is installed
###############################################################################
if [[ -n "${CI_SIM_UDID:-}" ]]; then           # let callers override
  SIM_UDID="$CI_SIM_UDID"
else
  # first look for a booted device (makes local re-runs snappy)
  SIM_UDID=$(xcrun simctl list devices booted | grep -m1 -oE '[A-F0-9\-]{36}' || true)
  # otherwise grab the first available iOS device
  if [[ -z "$SIM_UDID" ]]; then
    SIM_UDID=$(xcrun simctl list devices available | awk '/iOS/{print $NF; exit}' | tr -d '()')
  fi
fi

echo "ℹ️  Using simulator UDID: $SIM_UDID"
xcrun simctl bootstatus "$SIM_UDID" -b >/dev/null

###############################################################################
# 3.  Run the tests (iOS slice only)
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
