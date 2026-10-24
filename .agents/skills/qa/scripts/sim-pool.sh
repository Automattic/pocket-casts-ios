#!/bin/zsh
# Simulators for QA runs. Devices are named "QA <run> #<n>", and templates "QA Golden <profile>",
# so they're easy to find and delete. Other simulators are never touched.
#
# usage:
#   sim-pool.sh up <run> <count> [--from <profile>]  create (or clone "QA Golden <profile>") and boot; prints UDIDs
#   sim-pool.sh install <udid>... [--app <path>]     install the newest build of this checkout; prints its version
#   sim-pool.sh down <run>                           shut down and delete the run's devices
#   sim-pool.sh golden <profile>                     (re)create "QA Golden <profile>": install, sign in, sync, shut down
#   sim-pool.sh app                                  print the app `install` would use
#   sim-pool.sh list                                 QA devices
#
# Environment:
#   QA_DEVICE_TYPE  default "iPhone 17 Pro"
#   QA_RUNTIME      default: the newest iOS 27 runtime for the device type (DeviceInteraction needs iOS 27)
#   QA_CONFIG       default StagingDebug (staging servers); Debug talks to production
#   QA_SERVER       passed on to launch.sh; keep it in line with QA_CONFIG

set -euo pipefail
HERE=${0:A:h}
REPO=$(git -C $HERE rev-parse --show-toplevel)
BUNDLE=au.com.shiftyjelly.podcasts
DEVICE_TYPE=${QA_DEVICE_TYPE:-iPhone 17 Pro}
CONFIG=${QA_CONFIG:-StagingDebug}
APP=""

runtime() {
  if [[ -n ${QA_RUNTIME:-} ]]; then
    echo $QA_RUNTIME
    return
  fi
  xcrun simctl list runtimes -j | python3 -c '
import json, sys
device_type = sys.argv[1]
runtimes = [
    r for r in json.load(sys.stdin)["runtimes"]
    if r.get("isAvailable") and ".iOS-27-" in r["identifier"]
    and any(t["name"] == device_type for t in r.get("supportedDeviceTypes", []))
]
runtimes.sort(key=lambda r: [int(x) for x in r["version"].split(".")])
if not runtimes:
    sys.exit(f"No iOS 27 simulator runtime supports {device_type}; install one in Xcode > Settings > Components or set QA_DEVICE_TYPE")
print(runtimes[-1]["identifier"])' "$DEVICE_TYPE"
}

devices() {  # devices <name prefix> → "udid<TAB>state<TAB>name" per line
  xcrun simctl list devices -j | python3 -c '
import json, sys
for devices in json.load(sys.stdin)["devices"].values():
    for d in devices:
        if d["name"].startswith(sys.argv[1]):
            print(d["udid"], d["state"], d["name"], sep="\t")' "$1"
}

device_named() {
  devices "$1" | awk -F'\t' -v name="$1" '$3 == name { print $1 }'
}

boot() {
  for u in "$@"; do
    xcrun simctl bootstatus $u -b > /dev/null &
  done
  wait
}

app_path() {
  if [[ -n $APP ]]; then
    echo $APP
    return
  fi
  python3 - "$REPO" "$CONFIG" <<'EOF'
import glob, os, plistlib, sys
repo, config = sys.argv[1:]
best = None
for folder in glob.glob(os.path.expanduser("~/Library/Developer/Xcode/DerivedData/podcasts-*")):
    try:
        with open(os.path.join(folder, "info.plist"), "rb") as f:
            workspace = plistlib.load(f).get("WorkspacePath", "")
    except (OSError, plistlib.InvalidFileException):
        continue
    app = os.path.join(folder, "Build/Products", f"{config}-iphonesimulator", "podcasts.app")
    if os.path.dirname(workspace) == repo and os.path.isdir(app):
        if best is None or os.path.getmtime(app) > os.path.getmtime(best):
            best = app
if not best:
    sys.exit(f"No {config} simulator build of {repo}. Build it first (Xcode MCP BuildProject, or make build_staging) or pass --app.")
print(best)
EOF
}

install_app() {
  local app
  app=$(app_path)
  for u in "$@"; do
    xcrun simctl install $u "$app" &
  done
  wait
  local version build
  version=$(plutil -extract CFBundleShortVersionString raw "$app/Info.plist")
  build=$(plutil -extract CFBundleVersion raw "$app/Info.plist")
  echo "Installed $version ($build) $CONFIG, built $(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$app"), on $# device(s)"
}

case ${1:-} in
  up)
    RUN=${2:?usage: sim-pool.sh up <run> <count> [--from <profile>]}
    COUNT=${3:?usage: sim-pool.sh up <run> <count> [--from <profile>]}
    SOURCE=""
    if [[ ${4:-} == --from ]]; then
      SOURCE=$(device_named "QA Golden ${5:?missing profile}")
      [[ -n $SOURCE ]] || { echo "No \"QA Golden $5\". Create it with: sim-pool.sh golden $5" >&2; exit 1; }
      xcrun simctl shutdown $SOURCE 2>/dev/null || true
    fi
    EXISTING=$(devices "QA $RUN #" | wc -l | tr -d ' ')
    RT=$(runtime)
    UDIDS=()
    for (( i = 1; i <= COUNT; i++ )); do
      NAME="QA $RUN #$(( EXISTING + i ))"
      if [[ -n $SOURCE ]]; then
        UDIDS+=($(xcrun simctl clone $SOURCE "$NAME"))
      else
        UDIDS+=($(xcrun simctl create "$NAME" "$DEVICE_TYPE" "$RT"))
      fi
    done
    boot "${UDIDS[@]}"
    printf '%s\n' "${UDIDS[@]}"
    ;;
  install)
    shift
    TARGETS=()
    while (( $# )); do
      case $1 in
        --app) APP=$2; shift 2 ;;
        *) TARGETS+=($1); shift ;;
      esac
    done
    (( ${#TARGETS} )) || { echo "usage: sim-pool.sh install <udid>... [--app <path>]" >&2; exit 2; }
    install_app "${TARGETS[@]}"
    ;;
  down)
    RUN=${2:?usage: sim-pool.sh down <run>}
    devices "QA $RUN #" | while IFS=$'\t' read -r u state name; do
      xcrun simctl shutdown $u 2>/dev/null || true
      xcrun simctl delete $u
      echo "Deleted $name"
    done
    ;;
  golden)
    PROFILE=${2:?usage: sim-pool.sh golden <profile>}
    NAME="QA Golden $PROFILE"
    OLD=$(device_named "$NAME")
    if [[ -n $OLD ]]; then
      xcrun simctl shutdown $OLD 2>/dev/null || true
      xcrun simctl delete $OLD
    fi
    U=$(xcrun simctl create "$NAME" "$DEVICE_TYPE" "$(runtime)")
    boot $U
    install_app $U
    if [[ $PROFILE == signed-out ]]; then
      $HERE/launch.sh $U --fixture quiet > /dev/null
    else
      $HERE/launch.sh $U --account $PROFILE --fixture quiet > /dev/null
    fi
    xcrun simctl terminate $U $BUNDLE 2>/dev/null || true
    xcrun simctl shutdown $U
    echo "$U $NAME"
    ;;
  app)
    app_path
    ;;
  list)
    devices "QA " | column -t -s $'\t'
    ;;
  *)
    sed -n '2,19p' $0 | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac
