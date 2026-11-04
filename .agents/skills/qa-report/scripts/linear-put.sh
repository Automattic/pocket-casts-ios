#!/bin/zsh
# Uploads a file to the signed URL from Linear's prepare_attachment_upload, sending its headers verbatim.
# The URL expires 60 seconds after it's issued.
#
# usage: linear-put.sh <file> '<uploadRequest JSON>'   (the object with "url" and "headers")

set -euo pipefail
FILE=${1:?usage: linear-put.sh <file> '<uploadRequest JSON>'}
REQUEST=${2:?usage: linear-put.sh <file> '<uploadRequest JSON>'}
LINES=("${(@f)$(python3 - "$REQUEST" <<'PY'
import json, sys
request = json.loads(sys.argv[1])
request = request.get("uploadRequest", request)
headers = request.get("headers") or {}
if isinstance(headers, list):
    headers = {h.get("key") or h.get("name"): h["value"] for h in headers}
print(request["url"])
for key, value in headers.items():
    print(f"{key}: {value}")
PY
)}")
HEADERS=()
for header in "${(@)LINES[2,-1]}"; do
  HEADERS+=(-H "$header")
done
curl -sS -f -X PUT --data-binary @"$FILE" "${HEADERS[@]}" "${LINES[1]}" -o /dev/null -w 'HTTP %{http_code}\n'
