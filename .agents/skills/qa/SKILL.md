---
name: qa
description: Agent-driven QA of the Pocket Casts iOS app on iOS 27 simulators through the Xcode MCP DeviceInteraction tools. Runs regression scenarios from .agents/qa/scenarios, explores or verifies a feature from a spec, Linear issue or PR, or sweeps screens across dark mode, Dynamic Type, RTL and other settings, using test accounts and parallel simulators. Logs findings as Markdown with screenshots under artifacts/qa-runs/. Use when asked to QA, regression-test, exploratory-test, smoke-test or verify a feature or PR on a simulator. File the findings with the qa-report skill.
user-invocable: true
---

# QA

Drive the app on simulators, find real issues, and log them as Markdown with screenshots. Scenarios and account profiles live in `.agents/qa/` (start with its README). Scripts are in `.agents/skills/qa/scripts/`, referred to below as `scripts/`.

## Modes

| Command | What it does | Devices |
|---|---|---|
| `/qa smoke` | Scenarios tagged `smoke` | 1 |
| `/qa regression [tags or areas]` | The scenario library, `regression` tag by default | 3 |
| `/qa explore <spec>` | Plans scenarios for a feature from a Markdown file, Linear issue, PR number or a sentence, then runs them | 1–2 |
| `/qa verify <PR or branch>` | `explore` limited to what a diff touches, plus its neighbours | 1–2 |
| `/qa sweep [settings]` | Visits the screens in `.agents/qa/sweep.md` under each setting pass and reviews the screenshots | one per setting, up to 4 |
| `/qa continue <run>` | Another round into an existing run folder | as before |

Options: `--devices N`, `--account <profile>` (use one profile for everything), `--real <udid>` (drive an existing simulator signed in to your own account, with strict rules and one device), `--no-verify`, `--production` (Debug build and production accounts instead of StagingDebug and staging).

## 1. Plan

1. Create the run folder: `python3 scripts/findings.py new <mode> --slug <feature> --scope "<tags, spec or PR>" [--rules real]`. It prints the path; everything for the run goes there.
2. Choose scenarios:
   - **smoke, regression:** `python3 scripts/scenarios.py shards --tags <tags>` (or `--area up-next,player` when the arguments name scenario files; add `--exclude destructive` when there are no test accounts) gives ready-made shards (one area and account each, ~20 minutes). `scenarios.py list` shows what matched.
   - **explore, verify:** read the source. Linear: `get_issue`. PR: `gh pr view <n> --json title,body,files` and `gh pr diff <n>`. Then read the code it touches: screens, view models, feature flags, strings. Write scenarios in the library format (`.agents/qa/README.md`) into `run.md` under `## Plan`: happy paths, edge cases, states (signed out, free, Plus, empty and heavy libraries), settings that matter to the change, and neighbouring features that share its code. Give each an account profile. Only include what can be checked on screen. Group them into shards yourself.
   - **sweep:** one shard per setting, with the screen list from `.agents/qa/sweep.md` as the brief.
3. Fill `scope` and `accounts` in `run.md` and show the plan in a few lines. Don't wait for approval unless the user asked to review it.

## 2. Build and devices

1. Build the "Pocket Casts Staging" scheme (StagingDebug, staging servers) with the Xcode MCP `BuildProject` (or `make build_staging`). The MCP's scheme selection doesn't always stick: call `XcodeSwitchScheme` right before `BuildProject` and check the scheme in the log header. With `--production`: the `pocketcasts` scheme (Debug), and prefix the scripts with `QA_CONFIG=Debug QA_SERVER=production`.
2. List the test accounts: `scripts/accounts.sh` prints them as JSON, e.g. `{"plus": ["plus", "plus.2"], "free": ["free"]}`. Shards that change account data run on one simulator per account, so a profile with several accounts parallelizes; pick the device count accordingly.
3. Create devices: `scripts/sim-pool.sh up <run> <n>`, or `... --from <profile>` to clone a signed-in template (`sim-pool.sh list` shows the `QA Golden <profile>` devices; create one with `sim-pool.sh golden <profile>`). Then `scripts/sim-pool.sh install <udid>...`. Record the printed version in `run.md` `build:` and the devices in `devices:`.
4. Sign in each device to the account of its first shard: `scripts/launch.sh <udid> --account <profile> --fixture quiet,no-tips` (or `--signed-out`). It must print `[QA] ready`. If a Keychain item is missing, it prints the command to add it: tell the user and continue with the profiles that exist.
5. **Real mode:** skip all of this. Use the given UDID, record its settings with `scripts/sim-settings.sh <udid> save <run>/settings-baseline.txt`, and follow the real-account rules in `reference/safety.md`.

## 3. Run

Tell the user the run's README.md path first: it updates as findings come in.

- **One device** (smoke, most explore/verify, real mode): drive it yourself. Read `reference/safety.md`, `reference/driving.md`, `reference/checks.md` and `reference/findings.md`, then work through the shards. Afterwards verify the candidates yourself with `reference/verifying.md`.
- **Several devices:** run the saved workflow: `Workflow` with `name: "qa-run"` and args
  ```json
  {"runDir": "<abs path>", "repo": "<abs repo path>", "rules": "test",
   "devices": [{"udid": "…", "name": "QA <run> #1", "account": "plus"}],
   "shards": [<from scenarios.py shards, or your own: {"id", "title", "account", "settings", "minutes", "destructive", "brief"}>],
   "accounts": <accounts.sh output>}
  ```
  It spreads each profile's shards over that profile's accounts, keeps an account's shards that change data on one simulator, drives the simulators in parallel, verifies each shard's findings as soon as the shard is done, and dedupes at the end. The drivers switch a simulator's account themselves when its next shard needs another one. Add `"dryRun": true` to see the schedule only. Optional: `driverModel`, `driverEffort`, `verifierModel`, `verifierEffort`, `"verify": false`.
- If DeviceInteraction can't run sessions on several simulators at once, rerun with one device and say so in the report.

## 4. Finish

1. Write coverage into `run.md` `## Coverage` (one row per scenario: device, account, pass/fail/partial/blocked/skipped, note), gaps into `## Not covered`, unrestored state into `## State changes`, and set `status: complete`.
2. `python3 scripts/findings.py check <run>`; fix what it reports.
3. Devices: `scripts/sim-pool.sh down <run>` unless the user wants to keep them. Real mode: restore the baseline (`sim-settings.sh <udid> restore …`), undo the change log, relaunch plainly.
4. Report: the README path, counts by severity and status, the top findings (title, severity, one line on the cause), what wasn't covered and why, tooling problems, and how long the run took. Suggest `/qa-report <run>` to file the verified findings.
5. **explore, verify:** offer to add the scenarios worth keeping to `.agents/qa/scenarios/`, so the regression suite grows with each feature.
