# Verifying findings

Verification turns a candidate into something a developer can act on, or rejects it with a reason. Work from the finding, its screenshots and the code. Don't drive a simulator unless you were given one. Record everything with `.agents/skills/qa/scripts/findings.py`.

For each candidate:

1. **Read** `finding.md` and look at every screenshot. Does the evidence actually show the claim?
2. **Find the cause.**
   - Grep for the strings on screen, then follow the view controller or view model to the code path.
   - Cite `path:line` and explain the mechanism in one to three sentences: `findings.py section <folder> Cause "…"`.
3. **Check whether it's intended.**
   - Look at feature flags (`Modules/Sources/PocketCastsUtils/Feature Flags/FeatureFlag.swift`), comments, and the history: `git log -5 --format='%h %s' -- <file>` and `gh pr list --state merged --search "<keywords>" --limit 5`.
   - Reject only when the intent is clear, and quote it.
4. **Check trunk.** The build under test can predate a fix: run `git fetch origin trunk -q && git log --oneline HEAD..origin/trunk -- <file>`. If it's fixed, reject with "Fixed in <sha or PR>".
5. **Check the known non-bugs** in `checks.md`. If it's one of them, reject.
6. **Correct the fields.** Fix `severity` and `category` to match the definitions in `findings.md`, and sharpen the title if it's vague: `findings.py set <folder> severity=minor "title=…"`.
7. **Decide.**
   - Run `findings.py set <folder> status=verified` or `status=rejected`.
   - Then write `findings.py section <folder> Verdict "…"`.
     - **Verified:** one line on what you checked and how confident you are.
     - **Rejected:** start with the reason: "Duplicate of <slug>", "Intended: …", "Fixed in …", or "Not supported by the evidence: …".

**Keep it verified when the code confirms the mechanism.** That holds even if you couldn't reproduce it; say so in the Verdict. A finding with its cause is worth far more than a symptom.

## Duplicates

- **Within a run.** Duplicates share a root cause, even when they come from different screens or shards.
  - Keep the clearest finding.
  - Move the others' evidence into it: `findings.py shot`, plus the extra screens in Notes.
  - Reject the rest as "Duplicate of <slug>".
- **Across runs.** Earlier runs sit next to this one. Search them with `grep -ril "<key words>" <runs folder>/*/findings/*/finding.md`.
  - If an earlier finding with the same cause was reported (its `linear:` is set), run `findings.py set <folder> status=reported linear=<same issue>`, and add "Still reproduces in <build>" to Notes. That stops `qa-report` from filing it again.
