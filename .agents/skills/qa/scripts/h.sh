#!/bin/zsh
# usage: h.sh [hierarchy-file | session name] — compact view of a DeviceInteraction hierarchy dump.
# Pass the `hierarchyPath` from a Synthesize result, or your session name for its newest dump.
# With no argument it uses the newest dump overall, which can belong to another agent's session.
# Prints "Type ... label ... [x,y wxh] @hitX,hitY" for labelled/interactive elements only.
D="$(getconf DARWIN_USER_TEMP_DIR)ActionArtifacts/default/DeviceInteractionSynthesize"
if [[ -f "${1:-}" ]]; then
  F=$1
else
  F=("$D/${1:+$1-}"*-hierarchy.txt(N.om[1]))
  F=${F[1]:-}
fi
[[ -f "$F" ]] || { echo "No hierarchy dump found for '${1:-}'; pass hierarchyPath or your session name." >&2; exit 1; }
grep -E "label:|identifier:|value:|placeholderValue:|Alert|Sheet|Keyboard|Switch|Slider" "$F" \
  | grep -vE "^\s*(Other|Window), \{" \
  | sed -E 's/\{\{([0-9.]+), ([0-9.]+)\}, \{([0-9.]+), ([0-9.]+)\}\}/[\1,\2 \3x\4]/; s/, hitPoint: \{([0-9.]+), ([0-9.]+)\}/ @\1,\2/' \
  | sed -E 's/^ +/ /'
