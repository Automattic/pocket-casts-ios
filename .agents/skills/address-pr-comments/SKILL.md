---
name: address-pr-comments
description: Address PR review comments by fixing code, replying to each comment, and re-requesting review. Use this skill when the user wants to handle, fix, resolve, or address PR feedback, review comments, or code review suggestions. Also use when the user says things like "fix the PR comments", "handle review feedback", "address the review", or "respond to PR feedback".
argument-hint: [pr-number]
---

# Address PR Review Comments

Read all review comments on a PR, fix the code for each one, reply to each comment,
push the changes, post a summary, and re-request review.

## Arguments

- `$ARGUMENTS`: Optional. A PR number. If omitted, detect the PR from the current branch
  using `gh pr view --json number`.

## Steps

### 1. Identify the PR

If a PR number was provided, use it. Otherwise, detect it from the current branch:

```bash
gh pr view --json number -q '.number'
```

If no PR is found, tell the user and stop.

### 2. Fetch all review comments

Fetch inline review comments, general issue comments, and PR review submissions:

```bash
# Inline review comments (code-level feedback)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  --paginate --jq '.[] | {id, path, line, original_line, side, diff_hunk, body, user: .user.login, in_reply_to_id, created_at}'

# General PR comments (issue-level)
gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
  --paginate --jq '.[] | {id, body, user: .user.login, created_at}'

# PR review submissions (top-level review body from "Submit review")
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --paginate --jq '.[] | select(.body != "" and .body != null) | {id, body, state, user: .user.login, created_at: .submitted_at}'
```

Get the repo owner and name (used as `{owner}/{repo}` in API paths):

```bash
gh repo view --json owner,name -q '"\(.owner.login)/\(.name)"'
```

### 3. Filter to actionable comments

Skip comments that are:

- Your own replies (from previous runs or the PR author)
- Pure acknowledgments ("LGTM", "looks good", "thanks", etc.)
- Already addressed by this automation (check if a previous reply contains "Done in")
- Bot comments (github-actions, dependabot, etc.) — but NOT Copilot (`copilot`),
  which posts actionable review feedback that should be addressed
- Inline thread replies where `in_reply_to_id` is non-null — only treat top-level
  inline comments (those with `in_reply_to_id == null`) as separate actionable items

Focus on comments that contain feedback, suggestions, questions, or requested changes.

For PR review submissions, treat reviews with `state: CHANGES_REQUESTED` or `COMMENTED`
that have a non-empty `body` as actionable. Skip reviews with `state: APPROVED` or
`DISMISSED`, and skip reviews from bots (same rules as above).

### 4. Address each comment (one commit per comment)

Process each actionable comment one at a time. For each comment: fix, commit, push.
Do NOT reply to comments during this phase — all replies happen at the end.

1. **Read the relevant code**: Use the file path and line number from inline comments.
   If `line` is null (outdated comment), fall back to `original_line` and use the
   `diff_hunk` to locate the relevant code in the current file.
   For general comments, identify which files they reference.

2. **Understand the ask**: Determine what the reviewer wants — a bug fix, style change,
   refactor, clarification, etc.

3. **Make the fix**: Edit the code to address the feedback. Follow the project conventions
   from AGENTS.md / CLAUDE.md.

4. **Commit and push**: Stage only the files changed for this comment, commit, and push
   immediately. This ensures the commit hash is available on the remote for linking.

    ```bash
    git add <changed-files>
    git commit -m "$(cat <<'EOF'
    Address review: <short description of what was fixed>

    Co-Authored-By: Claude <noreply@anthropic.com>
    EOF
    )"
    git push
    ```

5. **Track what you did**: Record the comment, the action taken, and the full commit hash
   (`git rev-parse HEAD`) for the replies and summary later.

If a comment asks for something that would be incorrect, harmful to the codebase, or
contradicts project conventions, don't make the change. Instead, prepare a respectful
explanation of why. No commit is created for declined comments.

### 5. Reply to all comments

After all comments have been addressed and pushed, reply to each one:

**If fixed** (inline review comment):

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  --method POST -f body="Done in ${FULL_COMMIT_HASH}"
```

**If fixed** (general PR comment):

```bash
gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
  --method POST -f body="@reviewer Re: your comment about X — Done in ${FULL_COMMIT_HASH}"
```

**If not fixed** (inline review comment):

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  --method POST -f body="I considered this but didn't make the change because: [reason]"
```

**If not fixed** (general PR comment):

```bash
gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
  --method POST -f body="@reviewer Re: your comment about X — I considered this but didn't make the change because: [reason]"
```

**If fixed** (PR review submission):

```bash
gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
  --method POST -f body="@reviewer Re: your review — Done in ${FULL_COMMIT_HASH}"
```

**If not fixed** (PR review submission):

```bash
gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
  --method POST -f body="@reviewer Re: your review — I considered this but didn't make the change because: [reason]"
```

### 6. Post a summary comment

Post a single summary comment on the PR listing everything you did:

```bash
gh pr comment {pr_number} --body "$(cat <<'EOF'
## Review feedback addressed

{For each comment, one bullet point:}
- **File.swift:42** (@reviewer): [what was asked] — Done in <full-sha>
- **File.swift:87** (@reviewer): [what was asked] — Done in <full-sha>
- **General** (@reviewer): [what was asked] — Not changed because [reason]
- **Review** (@reviewer): [what was asked] — Done in <full-sha>
EOF
)"
```

### 7. Re-request reviews

Collect the unique usernames of all human commenters (exclude bot accounts like
`copilot`, `github-actions`, etc.), then re-request their review:

```bash
gh pr edit {pr_number} --add-reviewer reviewer1,reviewer2
```

Note: Bot accounts like Copilot cannot be re-requested for review — they will
automatically re-review when new commits are pushed.

### 8. Output

Print a summary to the user:

- How many comments were addressed
- How many were skipped (with reasons)
- The list of commit hashes
- The PR URL
