# Agent QA

Claude Code tests the app like a person would. It drives Pocket Casts on iOS 27 simulators through the DeviceInteraction tools in Xcode 27's MCP server, following scenarios written as expectations, or a spec it turns into a test plan.

Findings are Markdown files with screenshots, and each one is checked against the code before it counts. A second skill files them in Linear.

- [Set up](#set-up)
- [Run QA](#run-qa)
- [Read the results](#read-the-results)
- [File in Linear](#file-in-linear)
- [Write scenarios](#write-scenarios)
- [Safety](#safety)
- [Make runs faster](#make-runs-faster)
- [Troubleshooting](#troubleshooting)
- [How it works](#how-it-works)
- [Limitations](#limitations)

## Set up

You only do this once.

1. **Connect Xcode 27's MCP server to Claude Code:**

   ```bash
   claude mcp add xcode -- xcrun mcpbridge
   ```

   Then check that `/mcp` in Claude Code lists `xcode` as connected.

2. **Install an iOS 27 simulator runtime** in Xcode > Settings > Components. DeviceInteraction only works with iOS 27 simulators. Runs use an iPhone 17 Pro by default; see [Environment variables](#environment-variables).

3. **Add test accounts to your Keychain.** Each account is a real account on the server the build talks to. The default is the staging build, so these are staging accounts. The command prompts for the password:

   ```bash
   security add-generic-password -U -s pocketcasts-qa.staging.plus -a <email> -w
   security add-generic-password -U -s pocketcasts-qa.staging.free -a <email> -w
   ```

   | Profile | What it's for |
   |---|---|
   | `plus` | Most scenarios: a Plus account with folders, Up Next, bookmarks, playlists and files |
   | `free` | Discover, upsells, free-tier limits |
   | `patron` | Patron badge and icons |
   | `empty` | Empty states: nothing followed |
   | `heavy` | Long lists and performance: 150+ podcasts |
   | `signed-out` | Needs no account |

   - **What each account needs:** [accounts.md](accounts.md) describes the data each profile should have.
   - **Parallel runs:** add a second and third Plus account (`pocketcasts-qa.staging.plus.2`, `.plus.3`) to run more simulators at once; see [Make runs faster](#make-runs-faster).
   - **Check what you have:** `.agents/skills/qa/scripts/accounts.sh`.
   - **Without accounts:** only `signed-out` scenarios run, or you can test on your own simulator with `--real`.
   - **Keychain prompt:** the first time a script reads an item, macOS asks whether `security` may access it. Choose Always Allow.

4. **Optional: create signed-in templates.** Runs can clone these instead of signing in and syncing each time:

   ```bash
   .agents/skills/qa/scripts/sim-pool.sh golden plus
   ```

5. **Optional: install Pillow** for contrast checks: `pip3 install pillow`.

## Run QA

Run these in Claude Code from the repo root:

```text
/qa smoke                                  critical path on one simulator, about 15 minutes
/qa regression                             the whole scenario library, before a code freeze
/qa regression up-next,player              some areas (scenario file names) or tags
/qa explore PCIOS-123                      plan and test a feature from its Linear issue
/qa explore path/to/spec.md                … or from a spec file, or "a sentence describing it"
/qa verify 5270                            test what a PR changes, plus the features around it
/qa sweep dark,rtl                         visit key screens under settings, review the screenshots
/qa continue 2026-09-25-regression         another round into an existing run
```

| Option | Effect |
|---|---|
| `--devices N` | How many simulators to use. Defaults: 1 for smoke, 1–2 for explore and verify, 3 for regression, one per setting (up to 4) for sweep |
| `--account <profile>` | Use one account profile for everything |
| `--real <udid>` | Test on an existing simulator signed in to your own account. It's one device only, with strict rules: no destructive actions, no playback, everything undone |
| `--no-verify` | Skip the verification pass. Faster, but findings stay unconfirmed |
| `--production` | Use the Debug build and production accounts (`pocketcasts-qa.production.<profile>`) instead of staging |

### What happens

1. **Plan.** The agent creates a run folder and prints the path of its `README.md`. Open that file; it fills in as findings are logged.
   - It picks scenarios by tag or area, or, for `explore` and `verify`, writes a plan from the spec and the code into the run's `run.md`.
   - It groups the scenarios into shards of about 20 minutes, one account each.
2. **Set up.**
   - Builds the "Pocket Casts Staging" scheme.
   - Creates simulators named `QA <run> #1`, `#2` and so on, installs the build, and signs each simulator in.
3. **Drive.** Each simulator gets one agent at a time, working through its shards. With more than one simulator, the `qa-run` workflow runs them in parallel; follow it in `/workflows`.
4. **Verify.** As each shard finishes, another agent checks its findings against the code. It cites the cause, checks whether trunk already fixed it, and verifies or rejects each one.
5. **Dedupe.** A final pass merges duplicates within the run and against earlier runs.
6. **Finish.** You get a summary: counts by severity, the top findings, and what wasn't covered. The simulators are deleted unless you ask to keep them.

### How long it takes

- **Setup:** two simulators boot in about 30 seconds, and the install takes about 15. Signing in waits for the account's first sync, which can take a few minutes for a big library.
- **Driving:** every screen interaction costs about 4 seconds plus the agent's thinking. That's why scenarios name a fixture or deep link to jump straight to the right state.
- **Runs:** from the scheduler's estimates, smoke is about 70 agent-minutes. The full regression set is about 340 agent-minutes, which takes about 3¼ hours on 4 simulators with one Plus account, or about 1½ hours with three.
- **Tokens:** every shard is a separate agent. A full regression run is about 15 driving agents, plus a verifier for each shard that found something, plus the dedupe pass.

## Read the results

```text
artifacts/qa-runs/2026-09-25-regression/     gitignored; set QA_RUNS_DIR to keep runs elsewhere
├── README.md      the index: counts and a table of findings with thumbnails, regenerated as they come in
├── run.md         the plan, coverage per scenario, state changes, and what wasn't covered
└── findings/
    └── discover-search-with-no-matches-shows-a-blank-screen/
        ├── finding.md
        ├── 1.jpg
        └── 2.jpg
```

A finding looks like this:

```markdown
---
title: Search with no matches shows a blank screen
status: verified
severity: major
category: bug
area: Discover › Search
account: free
device: QA 2026-09-25-regression #2
settings: default
build: 8.21 (8.21.0.2) StagingDebug, built 2026-09-25 11:34
fingerprint: discover-search/search-with-no-matches-shows-a-blank-screen
linear:
---

## Steps
1. Open Discover and tap Search
2. Search for zzqqxxnomatch

## Actual
The results area stays blank.

## Expected
An empty state saying nothing matched, like the library search shows.

## Screenshots
![Blank results for zzqqxxnomatch](1.jpg)

## Cause
`podcasts/New Search/…swift:88` renders nothing when both result lists are empty.

## Verdict
Confirmed in code on trunk; no empty-state branch exists.
```

- **Statuses:** `candidate`, logged by the driving agent, becomes `verified` or `rejected` (with a Verdict saying why), then `reported` once it's in Linear.
- **Severities:**
  - `critical`: a crash, data loss, or a blocked core flow
  - `major`: a broken feature or wrong result
  - `minor`: cosmetic, or an edge case
  - `note`: a UX suggestion
- **Editing:** edit any `finding.md` by hand, or use the script:

```bash
S=.agents/skills/qa/scripts
python3 $S/findings.py list <run> --status verified      # --json for everything
python3 $S/findings.py set <finding folder> status=rejected severity=minor
python3 $S/findings.py check <run>                       # missing sections, screenshots, verdicts
python3 $S/findings.py index <run>                       # refresh README.md after editing by hand
```

## File in Linear

```text
/qa-report                                            the newest run: verified findings, minor and up
/qa-report 2026-09-25-regression --dry-run            preview what would be filed
/qa-report --labels "qa-agent,8.22" --min-severity major
/qa-report --only discover-search-with-no-matches-shows-a-blank-screen --yes
```

| Option | Default |
|---|---|
| `--labels` | `qa-agent`. `Bug` is added to `bug` and `crash` findings |
| `--team` | Pocket Casts iOS |
| `--state` | The team's triage state, else Backlog |
| `--min-severity` | `minor` (notes stay in the run) |
| `--status` | `verified` (add `candidate` to include unverified findings) |
| `--project` | none |
| `--only` | every matching finding (otherwise a comma-separated list of finding folder names) |
| `--dry-run`, `--yes` | Preview only; or skip the confirmation |

It never files anything without showing you the list first, unless you pass `--yes`.

What it does:
1. Skips findings that are already reported.
2. Searches Linear by each finding's fingerprint and title, so it doesn't file duplicates. A match with a closed issue is filed as a possible regression.
3. Creates the issues with the steps, build, device and likely cause. Code references link to GitHub at the tested commit.
4. Uploads the screenshots.
5. Writes each issue ID back to its finding. The run's README then shows it.

The `qa-agent` label doesn't exist yet. The first report asks before creating it.

## Write scenarios

`scenarios/` has one file per area. Each `##` section is a scenario: what must be true, not the steps to check it. The agent works out the steps, and reports anything else it notices on the way.

```markdown
---
area: Up Next
account: plus
tags: regression
---

# Up Next

Where it lives in the code, how to get there, anything the tester should know.

## Clear from the mini player
tags: smoke, destructive
setup: `--fixture up-next:3`

- Asks for confirmation, like the Up Next screen's Clear button
- The cleared queue stays cleared after relaunch
```

- **Frontmatter** sets defaults for the file: `area`, `account` and `tags`.
- **Lines right under a heading** can:
  - set `account:`
  - add `tags:`
  - give `setup:`: a fixture, deep link or precondition
  - give `settings:`: a setting pass from `.agents/skills/qa/reference/checks.md`
- **Make expectations specific enough to fail.** "Search works" can't fail. "No matches shows an explicit empty state, not a blank screen" can.
- **Use `setup:` to skip navigation.**
  - Fixtures: `--fixture up-next:5`, `clear-up-next`, `subscribe:<podcast uuid>`.
  - Deep links: [deep-links.md](scenarios/deep-links.md).
- **When a bug is fixed,** add its expectation to the matching scenario so it stays fixed.
- **After `explore` or `verify`,** the agent offers to add the scenarios worth keeping, so the library grows with each feature.

| Tag | Meaning |
|---|---|
| `regression` | The default set. Every file has it |
| `smoke` | The critical path, about 15 minutes |
| `destructive` | Changes account data: library, Up Next, playlists, synced settings. Test accounts only, and one simulator per account |
| `plus` | Needs Plus |

See what a run would pick up, and how it would be split into shards:

```bash
python3 .agents/skills/qa/scripts/scenarios.py list --tags smoke
python3 .agents/skills/qa/scripts/scenarios.py shards --tags regression
```

[sweep.md](sweep.md) lists the screens `/qa sweep` visits.

## Safety

Every run follows the rules in [safety.md](../skills/qa/reference/safety.md). In short:

- **It never pays,** and never sends anything out of the app: no feedback, ratings, shares or exports. It never changes an account's email or password, and never deletes an account.
- **On test accounts,** destructive actions are allowed (clearing Up Next, unfollowing, signing out) because they're part of what needs testing. The agent puts back what it changes, and names throwaway objects "QA Temp …".
- **On your own account** (`--real`), nothing destructive, no playback, and every change is undone.
- **Built-in guards:**
  - The launch hooks refuse to change data on an account they didn't sign in to.
  - They refuse to sign in when the build and the account are for different servers.
  - When a simulator switches accounts, they delete the previous account's local data first, so it doesn't merge into the next one.
- **Sound:** playback on test accounts is audible through the Mac's speakers.

## Make runs faster

- **Add accounts.** A profile's data-changing shards run on one simulator per account. More accounts let more simulators work at once: `plus`, `plus.2` and `plus.3` cut the regression estimate from about 3¼ hours to about 1½.
- **Clone templates.** `sim-pool.sh golden <profile>` saves the sign-in and first sync on every run. Rebuild a template after big changes to its account.
- **Narrow the scope.** `/qa smoke`, `/qa regression <areas>`, and `/qa verify <PR>` for a single change.
- **Try faster drivers.** The `qa-run` workflow accepts `driverModel` and `driverEffort`, e.g. "run /qa regression with sonnet drivers". Verification stays on the default model.

## Troubleshooting

| Problem | Fix |
|---|---|
| `No Keychain item pocketcasts-qa.staging.plus` | Add it with the `security add-generic-password` command it prints |
| `[QA] failed: this build talks to production, but the account is for staging` | Build the "Pocket Casts Staging" scheme, or use `--production` with production accounts |
| `[QA] failed: … only runs when signed out or signed in by the QA hooks` | The simulator is signed in to an account the hooks didn't sign in to, such as yours. Use a pool simulator, or sign out by hand |
| `[QA] failed: the first sync didn't finish in 3 minutes` | The account is large or the server is slow. Retry, or use a `QA Golden` template |
| `Timed out … waiting for [QA] ready` | Watch the hooks: `xcrun simctl spawn <udid> log stream --predicate 'category == "QA"'` |
| `No iOS 27 simulator runtime supports …` | Install an iOS 27 runtime, or set `QA_DEVICE_TYPE` to a device it supports |
| `No StagingDebug simulator build of …` | Build the Staging scheme first (or `make build_staging`) |
| The MCP builds the wrong scheme | Its scheme selection can reset. The skill calls `XcodeSwitchScheme` right before `BuildProject`; check the log header |
| `Session not found` | DeviceInteraction sessions expire after about 20 minutes. The agent starts a new one with a new name |
| Leftover `QA …` simulators | `sim-pool.sh list`, then `sim-pool.sh down <run>` |

## How it works

| Part | What it does |
|---|---|
| `.agents/skills/qa/SKILL.md` | The `/qa` skill: modes, planning, setup, running, finishing |
| `.agents/skills/qa/reference/` | What the driving and verifying agents read:<br>`safety.md`: rules<br>`driving.md`: DeviceInteraction commands and speed tips<br>`checks.md`: setting passes, what to look for, known non-bugs<br>`findings.md`: how to log<br>`verifying.md`: how to confirm or reject |
| `.claude/workflows/qa-run.js` | Runs several simulators in parallel:<br>- spreads shards over accounts and simulators<br>- drives each simulator's queue<br>- verifies each shard as it finishes<br>- dedupes at the end<br>`dryRun: true` prints the schedule only |
| `.agents/skills/qa-report/` | The `/qa-report` skill, plus `linear-put.sh` for screenshot uploads |
| `podcasts/Developer Menu/QALaunchHooks.swift` | DEBUG-only launch hooks: sign-in and fixtures, driven by environment variables |
| `.agents/qa/` | This guide, the scenarios, account profiles and the sweep list |

Scripts in `.agents/skills/qa/scripts/`:

| Script | Use |
|---|---|
| `sim-pool.sh` | `up <run> <n> [--from <profile>]`, `install <udid>…`, `down <run>`, `golden <profile>`, `list` |
| `launch.sh` | `launch.sh <udid> [--account <profile> \| --signed-out] [--fixture …] [--rtl] [--locale de_DE] [--double-strings]` |
| `sim-settings.sh` | `dark`, `light`, `text <size>`, `contrast on`, `bold on`, `motion on`, `save <file>`, `restore <file>`, `reset` |
| `findings.py` | Run folders and findings: `new`, `add`, `shot`, `section`, `set`, `list`, `check`, `index` |
| `scenarios.py` | `list`, `show`, `shards` |
| `accounts.sh` | The test accounts in your Keychain, as JSON |
| `h.sh` | The UI hierarchy, filtered to labelled elements with tap points |
| `contrast.py` | WCAG contrast of regions in a screenshot |

### Launch hooks

`launch.sh` works as follows:

1. It relaunches the app with `SIMCTL_CHILD_` environment variables. The app sees them as:
   - `PC_QA_EMAIL` and `PC_QA_PASSWORD`, read from the Keychain
   - `PC_QA_SERVER`
   - `PC_QA_FIXTURES`
2. The DEBUG-only `QALaunchHooks` signs in with `AuthenticationHelper` and waits for the first sync.
3. It applies the fixtures in order and logs `[QA] ready`, or `[QA] failed: …`, to the unified log (category `QA`).
4. `launch.sh` waits for that line, then relaunches the app plainly so launch-time UI reflects the new state.

The password never appears in commands, output or transcripts.

| Fixture | Effect |
|---|---|
| `quiet` | No onboarding, account prompt, What's New, End of Year or review prompts |
| `no-tips` | No tips, banners or upsell popovers |
| `up-next:<n>` | Up Next gets `n` episodes after the current one, taken from followed podcasts |
| `clear-up-next` | Empties Up Next, including the current episode |
| `subscribe:<uuid>` | Follows a podcast |
| `sign-out` | Signs out and deletes local data |

### Extending

- **A fixture:**
  - Add a `case` to `QALaunchHooks.apply(_:)`.
  - Call `requireManagedAccount` if it changes account data.
  - List it in the type's doc comment and in `reference/driving.md`.
- **A setting pass:** add a row to `reference/checks.md`, and a command to `sim-settings.sh` if it needs one.
- **An account profile:** add a row to [accounts.md](accounts.md), create the Keychain item, and use it in scenario frontmatter.
- **An area:** add a file to `scenarios/`.

### Environment variables

| Variable | Default | Meaning |
|---|---|---|
| `QA_RUNS_DIR` | `artifacts/qa-runs` in the repo | Where run folders go |
| `QA_DEVICE_TYPE` | `iPhone 17 Pro` | Simulator model for new devices |
| `QA_RUNTIME` | The newest iOS 27 runtime that supports the device | Simulator runtime |
| `QA_CONFIG` | `StagingDebug` | Which build `sim-pool.sh install` picks from DerivedData |
| `QA_SERVER` | `staging` | Which Keychain accounts `launch.sh` uses: `pocketcasts-qa.<server>.<profile>` |

## Limitations

- **Simulators only.** The scripts manage simulators, and DeviceInteraction needs iOS 27.
- **Sign-in through the UI isn't tested with real credentials.** The agent never sees passwords, so the login form is only tested with invalid credentials.
- **Purchases aren't tested.** Paywalls are only checked visually.
- **No network conditions.** Offline or slow networks aren't simulated.
- **Universal links** (`https://pca.st/…`) can open Safari on a simulator that hasn't linked the domain.
- **Staging content differs from production.** Discover and artwork in particular.
- **Review before filing.** The verifier makes judgment calls, so check the list `/qa-report` shows before confirming.
