#!/bin/zsh
# usage: h.sh [hierarchy-file] — compact view of the latest (or given) DeviceInteraction hierarchy dump.
# Prints "Type ... label ... [x,y wxh] @hitX,hitY" for labelled/interactive elements only.
D="$(getconf DARWIN_USER_TEMP_DIR)ActionArtifacts/default/DeviceInteractionSynthesize"
F="${1:-$(ls -t "$D"/*-hierarchy.txt | head -1)}"
grep -E "label:|identifier:|value:|placeholderValue:|Alert|Sheet|Keyboard|Switch|Slider" "$F" \
  | grep -vE "^\s*(Other|Window), \{" \
  | sed -E 's/\{\{([0-9.]+), ([0-9.]+)\}, \{([0-9.]+), ([0-9.]+)\}\}/[\1,\2 \3x\4]/; s/, hitPoint: \{([0-9.]+), ([0-9.]+)\}/ @\1,\2/' \
  | sed -E 's/^ +/ /'
