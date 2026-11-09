#!/bin/zsh
# Relaunches Pocket Casts on a simulator, optionally signing in to a test account and applying
# fixtures through the DEBUG-only hooks in podcasts/Developer Menu/QALaunchHooks.swift.
#
# usage: launch.sh <udid> [options]
#   --account <profile>   sign in with the Keychain item pocketcasts-qa.<server>.<profile> (.agents/qa/accounts.md)
#   --signed-out          sign out (only an account the hooks signed in)
#   --fixture <list>      comma-separated, e.g. quiet,up-next:5 (see QALaunchHooks.swift)
#   --server <server>     staging or production (default: $QA_SERVER, else staging); must match the build
#   --rtl                 right-to-left layout
#   --locale <ll_RR>      e.g. de_DE
#   --double-strings      doubled localized strings
#   --timeout <seconds>   how long to wait for the hooks (default 240; the first sync can take up to 3 minutes)
#
# With --account, --signed-out or --fixture, it waits for "[QA] ready" in the app's log, then
# relaunches plainly so launch-time UI (onboarding, prompts) reflects the new state.
# The password goes to the app through the environment and is never printed.

set -euo pipefail
BUNDLE=au.com.shiftyjelly.podcasts
U=${1:?usage: launch.sh <udid> [options]}
shift
SERVER=${QA_SERVER:-staging}
ACCOUNT=""
TIMEOUT=240
FIXTURES=()
ARGS=()
while (( $# )); do
  case $1 in
    --account) ACCOUNT=$2; shift 2 ;;
    --signed-out) FIXTURES+=(sign-out); shift ;;
    --fixture) FIXTURES+=(${(s:,:)2}); shift 2 ;;
    --server) SERVER=$2; shift 2 ;;
    --rtl) ARGS+=(-AppleTextDirection YES -NSForceRightToLeftWritingDirection YES); shift ;;
    --locale) ARGS+=(-AppleLanguages "(${2%%_*})" -AppleLocale $2); shift 2 ;;
    --double-strings) ARGS+=(-NSDoubleLocalizedStrings YES); shift ;;
    --timeout) TIMEOUT=$2; shift 2 ;;
    *) echo "Unknown option $1" >&2; exit 2 ;;
  esac
done

xcrun simctl terminate $U $BUNDLE 2>/dev/null || true

if [[ -z $ACCOUNT && ${#FIXTURES} -eq 0 ]]; then
  xcrun simctl launch $U $BUNDLE "${ARGS[@]}"
  exit
fi

ENV=(SIMCTL_CHILD_PC_QA_SERVER=$SERVER)
if [[ -n $ACCOUNT ]]; then
  SERVICE="pocketcasts-qa.$SERVER.$ACCOUNT"
  EMAIL=$(security find-generic-password -s $SERVICE 2>/dev/null | sed -n 's/^ *"acct"<blob>="\(.*\)"$/\1/p' || true)
  PASSWORD=$(security find-generic-password -s $SERVICE -w 2>/dev/null || true)
  if [[ -z $EMAIL || -z $PASSWORD ]]; then
    echo "No Keychain item $SERVICE. Add it with:" >&2
    echo "  security add-generic-password -U -s $SERVICE -a <email> -w" >&2
    exit 3
  fi
  ENV+=(SIMCTL_CHILD_PC_QA_EMAIL=$EMAIL SIMCTL_CHILD_PC_QA_PASSWORD=$PASSWORD)
fi
(( ${#FIXTURES} )) && ENV+=(SIMCTL_CHILD_PC_QA_FIXTURES=${(j:,:)FIXTURES})

LOG=$(mktemp -t qa-launch)
xcrun simctl spawn $U log stream --style compact \
  --predicate 'subsystem == "au.com.shiftyjelly.podcasts" AND category == "QA"' > $LOG 2>/dev/null &
STREAM=$!
trap 'kill $STREAM 2>/dev/null; rm -f $LOG' EXIT
sleep 2
env "${ENV[@]}" xcrun simctl launch $U $BUNDLE "${ARGS[@]}" > /dev/null

for (( i = 0; i < TIMEOUT; i++ )); do
  grep -qE '\[QA\] (ready|failed)' $LOG && break
  sleep 1
done
grep -o '\[QA\].*' $LOG || true
if ! grep -q '\[QA\] ready' $LOG; then
  grep -q '\[QA\] failed' $LOG || echo "Timed out after ${TIMEOUT}s waiting for [QA] ready" >&2
  exit 1
fi

xcrun simctl terminate $U $BUNDLE 2>/dev/null || true
xcrun simctl launch $U $BUNDLE "${ARGS[@]}"
