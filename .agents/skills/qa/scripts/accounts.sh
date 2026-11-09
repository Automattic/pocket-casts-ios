#!/bin/zsh
# Lists the QA test accounts in your Keychain for a server, as JSON for the qa-run workflow's
# `accounts` argument: {"plus": ["plus", "plus.2"], "free": ["free"]}. Nothing secret is read.
#
# usage: accounts.sh [server]   (default: $QA_SERVER, else staging)
#
# Add one with: security add-generic-password -U -s pocketcasts-qa.<server>.<profile>[.<n>] -a <email> -w

SERVER=${1:-${QA_SERVER:-staging}}
security dump-keychain 2>/dev/null \
  | sed -n "s/^ *\"svce\"<blob>=\"pocketcasts-qa\.$SERVER\.\(.*\)\"$/\1/p" \
  | sort -u \
  | python3 -c '
import json, sys
accounts = {}
for name in sys.stdin.read().split():
    accounts.setdefault(name.split(".")[0], []).append(name)
print(json.dumps({profile: sorted(names, key=lambda n: (len(n), n)) for profile, names in sorted(accounts.items())}))'
