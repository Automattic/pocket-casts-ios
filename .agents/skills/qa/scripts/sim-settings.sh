#!/bin/zsh
# System settings for QA passes on a simulator.
#
# usage: sim-settings.sh <udid> <command>
#   save <file>       record appearance, text size, Increase Contrast, Reduce Motion and Bold Text
#   restore <file>    put them back
#   dark | light
#   text <size>       e.g. large (the default), extra-extra-large, accessibility-extra-extra-extra-large
#   contrast on|off   Increase Contrast
#   motion on|off     Reduce Motion (relaunch the app to apply)
#   bold on|off       Bold Text (relaunch the app to apply)
#   reset             light, large text, everything else off
#
# RTL, locale and long strings are launch arguments: see launch.sh.

set -euo pipefail
U=${1:?usage: sim-settings.sh <udid> <command>}
CMD=${2:?usage: sim-settings.sh <udid> <command>}

a11y() {  # a11y <key> [on|off]
  if (( $# == 1 )); then
    xcrun simctl spawn $U defaults read com.apple.Accessibility $1 2>/dev/null || echo 0
  else
    xcrun simctl spawn $U defaults write com.apple.Accessibility $1 -bool $([[ $2 == on || $2 == 1 ]] && echo true || echo false)
  fi
}

case $CMD in
  save)
    FILE=${3:?usage: sim-settings.sh <udid> save <file>}
    {
      echo "appearance=$(xcrun simctl ui $U appearance)"
      echo "content_size=$(xcrun simctl ui $U content_size)"
      echo "increase_contrast=$(xcrun simctl ui $U increase_contrast)"
      echo "reduce_motion=$(a11y ReduceMotionEnabled)"
      echo "bold_text=$(a11y EnhancedTextLegibilityEnabled)"
    } > $FILE
    cat $FILE
    ;;
  restore)
    FILE=${3:?usage: sim-settings.sh <udid> restore <file>}
    source $FILE
    [[ $appearance == unsupported ]] || xcrun simctl ui $U appearance $appearance
    xcrun simctl ui $U content_size $content_size
    xcrun simctl ui $U increase_contrast $increase_contrast
    a11y ReduceMotionEnabled $reduce_motion
    a11y EnhancedTextLegibilityEnabled $bold_text
    ;;
  dark|light) xcrun simctl ui $U appearance $CMD ;;
  text) xcrun simctl ui $U content_size ${3:-large} ;;
  contrast) xcrun simctl ui $U increase_contrast $([[ ${3:-on} == on ]] && echo enabled || echo disabled) ;;
  motion) a11y ReduceMotionEnabled ${3:-on} ;;
  bold) a11y EnhancedTextLegibilityEnabled ${3:-on} ;;
  reset)
    xcrun simctl ui $U appearance light
    xcrun simctl ui $U content_size large
    xcrun simctl ui $U increase_contrast disabled
    a11y ReduceMotionEnabled off
    a11y EnhancedTextLegibilityEnabled off
    ;;
  *) echo "Unknown command $CMD" >&2; exit 2 ;;
esac
