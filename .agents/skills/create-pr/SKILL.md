---
name: create-pr
description: Create a pull request using the repository template and current branch changes
user-invocable: true
---

# Create Pull Request

## Steps

1. **Verify the project compiles** — Build the project and confirm it succeeds with no errors. Do NOT proceed if the build fails; fix any issues first.

2. **Gather context** — Run `git diff trunk...HEAD` and `git log trunk..HEAD --oneline` to understand all changes included in the PR.

3. **Create the PR** using `gh pr create` with the body template from `.github/PULL_REQUEST_TEMPLATE.md`.

4. Fill in the template sections based on the actual changes:
   - Replace the summary placeholder with a real description of what changed and why.
   - Fill in the "To test" section with concrete numbered steps.
   - If you know the issue number, fill in the `PCIOS-` and project number. Otherwise ask the user.
   - Keep the checklist items as-is for the author to check off.

5. Submit the PR without asking for confirmation.
