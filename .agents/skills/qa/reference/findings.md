# Logging findings

A finding is a Markdown file with its screenshots next to it:

    artifacts/qa-runs/<run>/findings/<slug>/finding.md, 1.jpg, 2.jpg

`findings.py` (in `.agents/skills/qa/scripts/`) writes the files and regenerates the run's `README.md`, the index the user watches. Log each finding as soon as it's confirmed on screen, not at the end.

## Add one

```bash
python3 .agents/skills/qa/scripts/findings.py add <run> "Search with no matches shows a blank screen" \
  --severity major --category bug --area "Discover › Search" \
  --account free --device "QA <run> #2" --settings default --scenario discover#search \
  --step "Open Discover and tap Search" --step "Search for zzqqxxnomatch" \
  --actual "The results area stays blank" \
  --expected "An empty state saying nothing matched" \
  --shot "<screenshotPath>::Blank results for zzqqxxnomatch"
```

- **Output:** it prints the finding's folder and converts each screenshot to a JPEG in that folder.
- **More screenshots:** `findings.py shot <folder> <png> "caption"`.
- **Replace a section:** `findings.py section <folder> Notes "…"` (add `--append` to add to it instead).
- **Frontmatter:** `findings.py set <folder> severity=minor`.

## Write it so a developer can act on it

- **The title is the claim**, specific and falsifiable. Write "Clear Up Next in the mini player skips the confirmation", not "Up Next issue".
- **Steps start from a state anyone can reach**: a tab, a deep link or a fixture. Then say exactly what was tapped and typed, in order.
- **Screenshots**
  - Include the screen that shows the problem, plus the one before it when the transition matters.
  - Caption every one.
  - Always pass your own `screenshotPath`.
- **One finding per root problem.** If the same issue shows up on three screens, log one finding that lists all three.
- **Actual vs. expected**: say what happened and what should have happened. For "expected", cite the app's own behaviour elsewhere when there is one.
- **Leave the root cause to the verifier.** Add `--cause path:line` only if you already know it.

## Fields

| Field | Values |
|---|---|
| `severity` | `critical`: crash, data loss or a blocked core flow<br>`major`: broken feature or wrong result<br>`minor`: cosmetic issue or edge case<br>`note`: UX suggestion |
| `category` | `crash`, `bug`, `ux`, `a11y`, `visual`, `copy`, `perf` |
| `status` | `candidate` (logged by the driver)<br>`verified` or `rejected` (set by the verifier)<br>`reported` (set by qa-report, with `linear:`) |
| `fingerprint` | Set automatically as `<area>/<claim>`. `qa-report` uses it to find duplicates in Linear |

`findings.py check <run>` validates every finding. `findings.py list <run> [--status verified] [--json]` lists them.
