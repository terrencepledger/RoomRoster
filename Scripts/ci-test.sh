#!/bin/bash
set -eo pipefail

# Create dummy configuration plists
cp RoomRoster/Secrets-Example.plist RoomRoster/Secrets.plist
cp RoomRoster/GoogleService-Info-Example.plist RoomRoster/GoogleService-Info.plist

# Resolve Swift package dependencies
xcodebuild -resolvePackageDependencies -project RoomRoster.xcodeproj -scheme RoomRoster

# Run unit tests
xcodebuild test \
  -project RoomRoster.xcodeproj \
  -scheme RoomRoster \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  CODE_SIGNING_ALLOWED=NO \
  OTHER_SWIFT_FLAGS="-Xfrontend -enable-experimental-feature -Xfrontend AccessLevelOnImport -Xfrontend -enable-experimental-feature -Xfrontend TypedThrows"

