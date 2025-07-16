#!/bin/bash
set -euo pipefail

# Create dummy plist files expected by the build
mkdir -p RoomRoster/RoomRoster/RoomRoster
cat > RoomRoster/RoomRoster/RoomRoster/Secrets.plist <<'EOP'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>API_KEY</key><string>${CI_FAKE_API_KEY:-ci-fake-key}</string>
    <key>SHEET_ID</key><string>${CI_FAKE_SHEET_ID:-ci-fake-sheet-id}</string>
</dict></plist>
EOP

cat > RoomRoster/RoomRoster/RoomRoster/GoogleService-Info.plist <<'EOP'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>BUNDLE_ID</key><string>com.example.ci</string>
</dict></plist>
EOP

OTHER_FLAGS="${OTHER_SWIFT_FLAGS:-"-Xfrontend -enable-experimental-feature -Xfrontend AccessLevelOnImport -Xfrontend -enable-experimental-feature -Xfrontend TypedThrows"}"

xcodebuild test \
    -project RoomRoster.xcodeproj \
    -scheme RoomRoster \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 14,OS=latest' \
    CODE_SIGNING_ALLOWED=NO \
    OTHER_SWIFT_FLAGS="$OTHER_FLAGS"
