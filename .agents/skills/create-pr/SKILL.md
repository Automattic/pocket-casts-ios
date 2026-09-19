---
name: create-pr
description: Create a pull request using the repository template and current branch changes
user-invocable: true
---

# Create Pull Request

1. Build the project. If it fails, fix it before going on.
2. Read `git diff trunk...HEAD` and `git log trunk..HEAD --oneline`.
3. Create the PR with `gh pr create`, using `.github/PULL_REQUEST_TEMPLATE.md` as the body:
   - Replace the summary placeholder with what changed and why.
   - Fill in "To test" with concrete numbered steps.
   - Fill in the `PCIOS-` issue and project numbers; ask the user if you don't know them.
   - Leave the checklist for the author.
4. Submit without asking for confirmation.
