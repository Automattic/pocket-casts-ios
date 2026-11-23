#!/usr/bin/env bash

# Throwaway: runs the release build and dSYM upload lanes on the CI image, without uploading to App Store Connect.

set -euo pipefail

LOG_DIR=artifacts/validation
mkdir -p "$LOG_DIR"

fail() {
  echo "^^^ +++ ASSERTION FAILED: $*"
  exit 1
}

echo "--- :mag: Environment"
xcodebuild -version
ruby -v
rbenv versions || true
# The VM name is only visible in the agent's "Booted xcode-…" line; Ruby 3.4.13 is what v3 adds.
ruby -v | grep -q '^ruby 3\.4\.13' || fail "expected Ruby 3.4.13 from the v3 image"

echo "--- :beer: brew upgrade getsentry/tools/sentry-cli (informational, as in prototype-build.sh)"
echo "which -a sentry-cli:"; which -a sentry-cli || echo "(none on PATH)"
sentry-cli --version || true
set +e
perl -e 'alarm 300; exec @ARGV' brew upgrade getsentry/tools/sentry-cli </dev/null 2>&1 | tee "$LOG_DIR/brew-upgrade.log"
brew_status=${PIPESTATUS[0]}
set -e
echo "BREW_UPGRADE_EXIT_STATUS=$brew_status"

"$(dirname "${BASH_SOURCE[0]}")/shared_setup.sh"

echo "--- :hammer_and_wrench: Building iOS (same lane as release-build.sh)"
bundle exec fastlane build_app_store_connect 2>&1 | tee "$LOG_DIR/build.log"

echo "--- :white_check_mark: Asserting archive and export"
ARCHIVE=artifacts/pocket-casts.xcarchive
IPA=artifacts/pocket-casts.ipa
DSYM_ZIP=artifacts/pocket-casts.app.dSYM.zip
for f in "$ARCHIVE" "$IPA" "$DSYM_ZIP" artifacts/pocket-casts.xcarchive.zip; do
  [[ -e "$f" ]] || fail "missing $f"
  du -sh "$f"
done
grep -E 'ARCHIVE SUCCEEDED|Successfully exported and signed the ipa file|Successfully exported and compressed dSYM' "$LOG_DIR/build.log" \
  || fail "no archive/export success line in the build log"

echo "--- :lock: Asserting App Store signing"
WORK=$(mktemp -d)
unzip -q "$IPA" -d "$WORK/ipa"
APP=$(find "$WORK/ipa/Payload" -maxdepth 1 -name '*.app' | head -1)
[[ -n "$APP" ]] || fail "no .app inside the ipa"
codesign --verify --deep --strict --verbose=2 "$APP" 2>&1
CODESIGN_INFO=$(codesign -dvv "$APP" 2>&1)
echo "$CODESIGN_INFO" | grep -E '^(Identifier|Authority|TeamIdentifier)='
echo "$CODESIGN_INFO" | grep -q '^Authority=Apple Distribution' || fail "app is not signed with an Apple Distribution certificate"
echo "$CODESIGN_INFO" | grep -q '^TeamIdentifier=PZYM8XX95Q' || fail "app is not signed by team PZYM8XX95Q"
security cms -D -i "$APP/embedded.mobileprovision" > "$WORK/profile.plist"
echo "Profile: $(plutil -extract Name raw "$WORK/profile.plist")"
plutil -extract ProvisionedDevices raw "$WORK/profile.plist" >/dev/null 2>&1 && fail "profile lists devices: not an App Store profile"
[[ "$(plutil -extract Entitlements.get-task-allow raw "$WORK/profile.plist")" == "false" ]] || fail "get-task-allow is not false"
echo "Embedded profile has no device list and get-task-allow=false: App Store distribution profile"

echo "--- :bug: dSYM UUIDs"
unzip -q "$DSYM_ZIP" -d "$WORK/dsym"
APP_DSYM=$(find "$WORK/dsym" -maxdepth 2 -name "$(basename "$APP").dSYM" | head -1)
[[ -n "$APP_DSYM" ]] || fail "no $(basename "$APP").dSYM in $DSYM_ZIP"
dwarfdump --uuid "$APP_DSYM" | tee "$LOG_DIR/dsym-uuids.txt"
UUID=$(awk '/UUID:/ {print $2; exit}' "$LOG_DIR/dsym-uuids.txt")
[[ -n "$UUID" ]] || fail "could not read a UUID from $APP_DSYM"

echo "--- :sentry: Uploading dSYM to Sentry (same lane as release-upload.sh, without its soft-fail)"
bundle exec fastlane symbols_upload "dsym_path:$DSYM_ZIP" 2>&1 | tee "$LOG_DIR/sentry.log"
grep -E 'Using sentry-cli' "$LOG_DIR/sentry.log" || fail "the Sentry plugin did not report which sentry-cli it used"
grep -E 'Uploaded|Nothing to upload|missing debug information' "$LOG_DIR/sentry.log" \
  || fail "no sentry-cli upload summary in the log"
grep -q 'Nothing to upload' "$LOG_DIR/sentry.log" && fail "sentry-cli uploaded nothing: this run proves no upload"

echo "--- :sentry: Asserting Sentry has dSYM $UUID"
http_code=$(curl -sS -o "$WORK/dsyms.json" -w '%{http_code}' \
  -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "https://sentry.io/api/0/projects/a8c/pocket-casts-ios/files/dsyms/?query=$UUID")
echo "Sentry API HTTP $http_code"
if [[ "$http_code" == "200" ]]; then
  grep -qi "$UUID" "$WORK/dsyms.json" || fail "Sentry does not list $UUID"
  echo "Sentry lists debug file $UUID"
else
  echo "Could not query Sentry (HTTP $http_code); relying on the sentry-cli upload summary above"
fi
