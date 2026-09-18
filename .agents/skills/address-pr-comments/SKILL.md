---
name: address-pr-comments
description: Address PR review comments by fixing code, replying to each comment, and re-requesting review. Use this skill when the user wants to handle, fix, resolve, or address PR feedback, review comments, or code review suggestions. Also use when the user says things like "fix the PR comments", "handle review feedback", "address the review", or "respond to PR feedback".
argument-hint: [pr-number]
---

# Address PR Review Comments

Fix each review comment in its own commit, reply to every comment, post a summary, and re-request review.

`$ARGUMENTS` is an optional PR number. Without it, use `gh pr view --json number -q .number`; if there's no PR, tell the user and stop.

## 1. Fetch the comments

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
# Inline comments
gh api repos/$REPO/pulls/$PR/comments --paginate \
  --jq '.[] | {id, path, line, original_line, diff_hunk, body, user: .user.login, in_reply_to_id}'
# General comments
gh api repos/$REPO/issues/$PR/comments --paginate --jq '.[] | {id, body, user: .user.login}'
# Review bodies
gh api repos/$REPO/pulls/$PR/reviews --paginate \
  --jq '.[] | select((.body // "") != "") | {id, body, state, user: .user.login}'
```

## 2. Pick the actionable ones

Address feedback, suggestions, questions and requested changes. Skip:

- The PR author's replies, acknowledgments ("LGTM", "thanks"), and comments already answered with "Done in"
- Replies inside a thread (`in_reply_to_id` set); each top-level inline comment is one item
- `APPROVED` and `DISMISSED` reviews
- Bots, except the reviewers `claude[bot]` and Copilot (`Copilot`, `copilot-pull-request-reviewer[bot]`). `claude[bot]` also posts a summary comment linking to its inline comments; address the inline comments, not the summary

## 3. Fix each comment in its own commit

Don't reply until every comment is done. For each one:

1. Read the code. For an outdated comment `line` is null, so use `original_line` and `diff_hunk`.
2. Make the fix, following AGENTS.md. If the request would be wrong or break project conventions, don't make it; note why instead.
3. Run `make format` and build the app. Don't push code that doesn't build.
4. Commit only this comment's files (`make format` touches the whole repo) and push, so the hash can be linked. Record the full hash from `git rev-parse HEAD`.

```bash
git add <changed-files>
git commit -m "Address review: <what was fixed>"
git push
```

## 4. Reply

Reply "Done in <full-sha>" or "I didn't make this change because <reason>":

- Inline comment: `gh api repos/$REPO/pulls/$PR/comments/<id>/replies -f body="..."`
- General comment or review: `gh api repos/$REPO/issues/$PR/comments -f body="@<reviewer> Re: <topic> — ..."`

## 5. Summarize and re-request review

Post one summary comment with `gh pr comment $PR --body "..."`:

```markdown
## Review feedback addressed

- **File.swift:42** (@reviewer): <what was asked> — Done in <full-sha>
- **General** (@reviewer): <what was asked> — Not changed because <reason>
```

Re-request review from the human commenters with `gh pr edit $PR --add-reviewer <user1>,<user2>`. Bots can't be re-requested; they review again when you push.

## 6. Report

Tell the user how many comments you addressed and skipped (with reasons), the commit hashes, and the PR URL.
