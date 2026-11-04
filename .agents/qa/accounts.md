# Test accounts

Each scenario names an account profile. A profile is a real account on the server the build talks to:
- **StagingDebug** (the default) talks to staging.
- **Debug** talks to production.

Accounts live in your login Keychain, never in the repo.

| Profile | Subscription | What the account needs |
|---|---|---|
| `signed-out` | – | Nothing. It has no Keychain item |
| `free` | none | ~10 followed podcasts, a few played and starred episodes, one manual playlist |
| `plus` | Plus | ~20 podcasts including two folders; 5+ episodes in Up Next; bookmarks on 2–3 episodes; a file in Files; a smart and a manual playlist; podcasts with chapters and transcripts |
| `patron` | Patron | A few podcasts |
| `empty` | none | Nothing followed or played. Used for empty states |
| `heavy` | Plus | 150+ podcasts, 100+ episodes in Up Next, 10+ playlists, long listening history. Used for performance and long lists |

Keep each account close to this description. Destructive scenarios put back what they change. If an account drifts, restore it by hand. `launch.sh <udid> --account plus --fixture up-next:5` refills Up Next.

## Add an account

```bash
security add-generic-password -U -s pocketcasts-qa.staging.plus -a <email> -w
```

- **The password:** the command prompts for it.
- **Production accounts:** use `pocketcasts-qa.production.<profile>`, and run with `QA_CONFIG=Debug QA_SERVER=production`.
- **Keychain prompt:** the first time a script reads an item, macOS asks whether `security` may access it. Choose Always Allow.

## More accounts, more parallel simulators

Shards that change account data run on one simulator per account, so parallel agents don't clear the same Up Next under each other. With a single `plus` account, most of a regression run queues on one simulator. For each extra simulator you want busy, add another account for the profile: `pocketcasts-qa.staging.plus.2`, `plus.3`, and so on. Give each one the same data as the profile describes. `.agents/skills/qa/scripts/accounts.sh` lists what's in your Keychain. By the scheduler's estimate, the regression set takes about 195 minutes on 4 simulators with one Plus account, and about 90 with three.

## How sign-in works

1. `launch.sh <udid> --account plus` reads the Keychain item.
2. It passes the email and password to the app as launch environment variables (`SIMCTL_CHILD_PC_QA_*`).
3. The DEBUG-only `QALaunchHooks` signs in with `AuthenticationHelper` and waits for the first sync, then logs `[QA] ready`.
4. `launch.sh` waits for that line and relaunches the app plainly.

The password never shows up in commands, output or transcripts. The email does show up in the app's UI and in screenshots.

Some safeguards are built in:

- **Wrong server.** The hooks refuse to sign in when the build talks to a different server than the account is for.
- **Switching accounts.** When a simulator moves to another account, the hooks delete the previous account's local data first, so it doesn't merge into the next account.
- **Your own account.** Fixtures that change account data (`up-next`, `clear-up-next`, `subscribe`, `sign-out`) refuse to run on an account the hooks didn't sign in to, such as your own.

## Sharing accounts

- **Runs overlap.** Everyone running QA against the same accounts shares their state. A `destructive` scenario on `plus` changes Up Next for anyone else on `plus` at that moment.
- **Within one run**, destructive shards for an account stay on one simulator.
- **Across people**, either give each person their own set (the Keychain item can point at any email), or avoid running destructive scenarios at the same time.

## Templates

`sim-pool.sh golden <profile>` builds a signed-in, synced template simulator named `QA Golden <profile>`. `sim-pool.sh up <run> <n> --from <profile>` clones it, which skips the sign-in and first sync. Rebuild the template after big changes to the account.
