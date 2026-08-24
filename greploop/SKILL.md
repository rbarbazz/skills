---
name: greploop
description: Iterate a draft PR through Greptile reviews until 5/5 confidence — recommend a fix for every finding, apply only what the user approves, push, re-review.
disable-model-invocation: true
---

# Greploop

Drive a draft PR to a 5/5 Greptile confidence score with zero unresolved Greptile threads, before human review is requested.

Invoking this skill is explicit authorization to push commits to this PR's branch and to post the comments the loop needs: `@greptileai review` triggers and thread replies, plus deleting the loop's own trigger comments during final cleanup. The authorization is scoped to this PR. Regular pushes only, never force-push. No comments or messages anywhere else.

Always show the user any comment or reply text before you post it, and post only after they approve the wording.

## Setup

1. Resolve the PR: use the argument (number or URL), otherwise the PR for the current branch (`gh pr view --json number,url,isDraft,headRefName`).
2. Confirm it is a draft. If it is not a draft, stop and ask the user whether to continue: a non-draft PR may already have human reviewers watching.
3. Confirm the local checkout is on the PR head branch with a clean working tree, and pull if behind. A dirty tree or wrong branch stops the loop before it starts.

## The loop

Repeat until an exit condition, at most 5 iterations.

### 1. Get a review of the current head

- Check for a Greptile review or comment on the current head commit (PR reviews and issue comments authored by the Greptile bot, newer than the head commit's push).
- If none exists, post a PR comment containing exactly `@greptileai review`.
- Poll every 30 seconds, up to 10 minutes. On timeout, stop and report.

### 2. Read the results

- Confidence score: match `([0-5])/5` in the newest Greptile review or summary comment. If no score is found, show the user the comment and ask how to read it.
- Findings: every unresolved review thread authored by Greptile (GraphQL `reviewThreads`, `isResolved: false`).

### 3. Exit check

Close the loop when either condition holds. Greptile resolves threads itself on re-review once a bug is fixed, so an unresolved thread that is neither fixed nor declined means more work remains.

- **Clean pass** — score is 5/5 and every Greptile thread is resolved.
- **Accepted below 5/5** — every open Greptile comment has been responded to (fixed, or declined with a reply), and the user has intentionally accepted the current sub-5/5 score. Confirm this with the user before stopping, do not assume it.

On either exit, clean up, write the report, and stop.

Cleanup on success: list this PR's issue comments whose body is `@greptileai review`, and delete all but the newest, so the PR keeps a single trigger comment. Delete only these exact trigger comments, nothing else.

Description pass on success: read the current PR description and compare it against the branch's full diff, which now includes every fix the loop made. Draft a revised description in the repo's PR style that covers what changed during the loop. Show the user the current and proposed descriptions and ask for confirmation (AskUserQuestion). Apply only what the user approves, via `gh pr edit --body`; if they decline, leave the description untouched.

### 4. Triage every finding

Every code change goes through the user: read each unresolved Greptile comment, form a recommendation, and leave the code untouched until the user approves.

For each comment, work out the fix options you see and pick the one you would apply. Then present all findings to the user in one batch (AskUserQuestion, one entry per item: the comment and file:line, then the fix options). Put your pick first, labeled `(Recommended)`, and always include a "leave as is" option. Apply exactly the fixes the user chooses. For a declined item (the user picks "leave as is" or gives their own answer), reply on the thread with the user's one-line reasoning.

Triage is complete only when every unresolved Greptile comment has been approved-and-fixed or declined by the user.

### 5. Verify, push, resolve

1. Run the repo's checks on the touched files (lint plus the relevant tests). Fix failures before pushing.
2. Commit in the repo's commit style. One commit per iteration is fine.
3. Push. If this PR is part of a gh-stack (its branch belongs to a stack), invoke the `gh-stack` skill to rebase the stack and push, so the branches above it pick up the new commit. Otherwise push the PR branch directly.
4. Return to step 1. Leave thread resolution to Greptile: it resolves a thread on re-review once the bug is fixed.

## Report

End every run (success, timeout, or iteration cap) with: iterations run, final confidence score, counts of findings fixed / declined / remaining, which exit condition fired, and on success whether the PR description was updated.

## Command reference

Unresolved review threads with authors:

```bash
gh api graphql -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$pr){
        reviewThreads(first:100){
          nodes{ id isResolved comments(first:10){
            nodes{ author{login} body path line url } } }
        }
      }
    }
  }' -f owner=OWNER -f repo=REPO -F pr=NUMBER
```

List and delete trigger comments (cleanup):

```bash
gh api "repos/OWNER/REPO/issues/NUMBER/comments" --paginate \
  --jq '.[] | select(.body == "@greptileai review") | {id, created_at}'
```

```bash
gh api -X DELETE "repos/OWNER/REPO/issues/comments/COMMENT_ID"
```
