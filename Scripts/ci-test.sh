#!/usr/bin/env bash
# Scripts/ci-test.sh  —  Build & run RoomRoster tests in CI
set -euo pipefail

###############################################################################
# 0.  Make sure we’re at the repository root
###############################################################################
if [[ -n "${GITHUB_WORKSPACE:-}" && -d "$GITHUB_WORKSPACE" ]]; then
  cd "$GITHUB_WORKSPACE"
else
  cd "$(git rev-parse --show-toplevel)"
fi
echo "📂 Working directory: $PWD"

###############################################################################
# 1.  Stub the plist files the RoomRoster target expects
#     (They live one folder below the project root, *not* two.)
###############################################################################
mkdir -p RoomRoster/RoomRoster   # <- only TWO “RoomRoster” segments

cat > RoomRoster/RoomRoster/Secrets.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>API_KEY</key> <string>${CI_FAKE_API_KEY:-ci-fake-key}</string>
  <key>SHEET_ID</key><string>${CI_FAKE_SHEET_ID:-ci-fake-sheet-id}</string>
</dict></plist>
EOF

cat > RoomRoster/RoomRoster/GoogleService-Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>BUNDLE_ID</key><string>com.example.ci</string>
</dict></plist>
EOF

echo "📝 Stub plists created:"
ls -l RoomRoster/RoomRoster/*.plist

###############################################################################
# 2.  Choose a valid iOS-simulator UDID (robust across Xcode versions)
###############################################################################
if [[ -n "${CI_SIM_UDID:-}" ]]; then
  SIM_UDID="$CI_SIM_UDID"
else
  SIM_UDID=$(xcrun simctl list devices available \
             | grep -Eo '[0-9A-F-]{36}' | head -n1)
fi
echo "📱 Using simulator UDID: $SIM_UDID"

# Wait until the simulator is fully booted (returns immediately if already up)
xcrun simctl bootstatus "$SIM_UDID" -b >/dev/null

###############################################################################
# 3.  Build & test the iOS slice
###############################################################################
OTHER_FLAGS="${OTHER_SWIFT_FLAGS:-"-Xfrontend -enable-experimental-feature -Xfrontend AccessLevelOnImport -Xfrontend -enable-experimental-feature -Xfrontend TypedThrows"}"

set -o pipefail
echo "🚀 Running xcodebuild test…"
xcodebuild test \
  -project RoomRoster.xcodeproj \
  -scheme RoomRoster \
  -sdk iphonesimulator \
  -destination "id=$SIM_UDID" \
  CODE_SIGNING_ALLOWED=NO \
  OTHER_SWIFT_FLAGS="$OTHER_FLAGS"
