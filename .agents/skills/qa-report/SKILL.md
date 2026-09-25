---
name: qa-report
description: File verified findings from a qa run (artifacts/qa-runs/<run>) as Linear issues with their screenshots, skipping duplicates already in Linear. Takes the labels to apply (default qa-agent), team (default Pocket Casts iOS), minimum severity, workflow state and project. Use after /qa, or when asked to report, file or push QA findings to Linear.
user-invocable: true
---

# QA report

Files findings from a `qa` run as Linear issues, and records each issue on its finding. Findings are Markdown files (`findings/<slug>/finding.md` plus screenshots) written by `.agents/skills/qa/scripts/findings.py`; see `.agents/skills/qa/reference/findings.md` for the format.

## Arguments

`/qa-report [run] [--labels "qa-agent,…"] [--team "Pocket Casts iOS"] [--min-severity minor] [--status verified] [--state Triage] [--project <name>] [--only <slug,…>] [--dry-run] [--yes]`

| Argument | Default | Notes |
|---|---|---|
| `run` | The newest folder in `artifacts/qa-runs/` | A path or a run name |
| `--labels` | `qa-agent` | Replaces the default. `Bug` is also added to `crash` and `bug` findings unless `--labels` already includes a Type label |
| `--team` | `Pocket Casts iOS` | |
| `--min-severity` | `minor` | Notes stay in the run unless you pass `note` |
| `--status` | `verified` | Pass `verified,candidate` to include findings that were never verified |
| `--state` | The team's triage state, else `Backlog` | |
| `--project` | none | |
| `--only` | every matching finding | Comma-separated finding slugs |
| `--dry-run` | off | Show the plan and stop |
| `--yes` | off | Skip the confirmation |

## 1. Collect

- Run `python3 .agents/skills/qa/scripts/findings.py list <run> --status <status> --min-severity <severity> --json`.
- Drop findings that already have `linear:` set, and apply `--only`.
- Read `<run>/run.md` for the build, the commit (its first word) and the run name.
- Stop if nothing is left.

## 2. Check the team and labels

- **States:** `list_issue_statuses` for the team. Use `--state` if given. Otherwise use the state whose type is `triage`, or `Backlog`.
- **Labels:** `list_issue_labels` with the team and each label's name.
  - If a label is missing, ask before creating it. For `qa-agent`, create it as a team label with color `#95A2B3` and the description "Found by agent QA (.agents/skills/qa)". Use `save_issue_label` or `create_issue_label`.
  - Never create a Type label.

## 3. Skip what Linear already has

For each finding:

1. Search the team for its fingerprint: `list_issues` with `team` and `query: "<fingerprint>"`. Every issue this skill files carries the fingerprint.
2. Search again with three to five distinctive words from the title, including closed issues. Read the likely matches.
3. Act on what you find:
   - **An open issue with the same root cause:** don't file. Run `findings.py set <folder> status=reported "linear=<ID> (existing)"`.
   - **A closed issue with the same root cause:** it may have regressed. File it anyway, add "Possible regression of <ID>" at the top of the description, and relate the two issues (`relatedTo`).

## 4. Confirm

Show a table with one row per finding:
- the title
- severity, and the priority it maps to
- labels
- state
- what the duplicate search found

Mention anything skipped and why. Stop here for `--dry-run`. Without `--yes`, ask once before creating anything.

## 5. File

For each finding, in severity order:

1. **Create the issue** with `save_issue`:
   - `team`, `title` (the finding's title as-is), `state`, `project`
   - `labels`: the resolved list
   - `priority`: `critical` → 2 (High), `major` → 3 (Medium), `minor` → 4 (Low), `note` → 0 (none)
   - `description`: the template below
2. **Upload the screenshots** one at a time. The signed URL expires after 60 seconds, so finish each file before starting the next:
   1. Call `prepare_attachment_upload` with the issue, the file name, `image/jpeg` and the size in bytes (`stat -f %z <file>`).
   2. Run `.agents/skills/qa-report/scripts/linear-put.sh <file> '<uploadRequest JSON>'`. It must print `HTTP 200`.
   3. Call `create_attachment_from_upload` with the issue, the `assetUrl` and the caption as the title.
3. **Embed the screenshots.** Call `save_issue` with the issue's `id` and a `patch` that replaces `<!-- screenshots -->` with one `![caption](assetUrl)` line per screenshot.
4. **Record the issue on the finding:** `findings.py set <folder> status=reported linear=<identifier>`. This also regenerates the run's README.

If a step fails, say which finding and step, and continue with the next finding.

### Description template

```markdown
**Severity:** <severity> · **Category:** <category> · **Area:** <area>
**Build:** <build> · `<commit>` · **Device:** <device> · **Settings:** <settings> · **Account:** <profile, e.g. plus>

## Steps to reproduce
<Steps>

## Actual
<Actual>

## Expected
<Expected>

## Screenshots
<!-- screenshots -->

## Likely cause
<Cause, with each path:line linked to https://github.com/Automattic/pocket-casts-ios/blob/<commit>/<path>#L<line>>

## Notes
<Notes, if any>

---
Found by agent QA run `<run name>`. QA fingerprint: `<fingerprint>`
```

- Leave out empty sections.
- Use the account profile (`plus`), never the account's email.

## 6. Report

List the issues you created (identifier, title, link), the findings skipped as duplicates and why, and any failures. Remind the user that the README now shows the Linear IDs.
