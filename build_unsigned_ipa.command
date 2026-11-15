#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
rm -rf build Payload AudiBridge-unsigned.ipa
xcodebuild \
  -project AudiBridge.xcodeproj \
  -target AudiBridge \
  -configuration Release \
  -sdk iphoneos \
  SYMROOT="$PWD/build" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build
APP="$PWD/build/Release-iphoneos/AudiBridge.app"
if [[ ! -d "$APP" ]]; then
  echo "AudiBridge.app not found: $APP"
  exit 1
fi
mkdir Payload
cp -R "$APP" Payload/
/usr/bin/zip -qry AudiBridge-unsigned.ipa Payload
/usr/bin/unzip -t AudiBridge-unsigned.ipa
echo ""
echo "READY: $PWD/AudiBridge-unsigned.ipa"
