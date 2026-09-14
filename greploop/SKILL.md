---
name: greploop
description: Iterate the current branch through Greptile CLI reviews until 5/5 — recommend a fix for every finding, apply only what the user approves, commit, re-review. Runs before a PR exists or while it is a draft.
disable-model-invocation: true
---

# Greploop

Drive the current branch to a 5/5 Greptile confidence score with no open findings, before human review is requested. The review runs locally through `greptile review`: nothing is posted to GitHub and nothing is pushed. The user pushes.

Every code change goes through the user: recommend, then apply only what they approve.

## Setup

1. `greptile whoami` must print a signed-in account. It exits 0 even when signed out, so read the text. If signed out, stop and ask the user to run `greptile login` (interactive browser flow).
2. Clean working tree on the branch to review (`git status --porcelain` empty). `greptile review` reads committed changes only, and the loop commits once per iteration. A dirty tree stops the loop: the user commits or stashes, not you.
3. Base branch: the PR's base when a PR exists (`gh pr view --json isDraft,baseRefName`), otherwise the argument, otherwise the CLI default. If a PR exists and is not a draft, stop and ask whether to continue: human reviewers may be watching.

## The loop

Repeat until an exit condition, at most 5 iterations.

### 1. Review

```bash
greptile review --json > review.json
```

Add `-b BASE` when setup resolved a base. A review takes about a minute; wait for it, and never start a second one while one runs. Exit 0 with findings is the normal case.

On a non-zero exit the review often finished server-side. Recover before giving up: `greptile review status --json` (exit 3 means still running, wait 30 s and retry), then `greptile review show RUN_ID --json > review.json` with the `runId` from status. If recovery fails, quote stderr and stop.

### 2. Read the results

From `review.json`: `confidence` (1..5 or null), `confidenceReasoning`, and `comments[]`. Each comment carries `path`, `startLine`, `endLine`, `side` (`"old"` anchors to the pre-change file), `severity` (P0 worst, then P1, P2), `securityIssue`, `body`, and `suggestion` (replacement code for `startLine..endLine`, a proposal to check against the file, never a patch to apply blind).

Two findings are the same finding when they share `path`, overlap in lines after your edits, and describe the same issue. A finding the user declined earlier this run stays declined: record it, do not ask again.

### 3. Exit check

- **Clean pass**: `confidence` is 5 and every finding is fixed or declined.
- **Accepted below 5/5**: every finding is fixed or declined, and the user confirms they accept the current score. Ask, do not assume. When `confidence` is 3 or lower with nothing left to fix, read `confidenceReasoning` first: a concrete failure it describes that no comment raised is a finding, triage it.

Re-reviewing an unchanged commit returns no new information, so a review with nothing left to fix ends the loop without a confirmation review.

On either exit: description pass, report, stop.

Description pass, only when a PR exists: compare the PR description against the branch's full diff, which now includes the loop's fixes. Draft a revised description in the repo's PR style. Show current and proposed (AskUserQuestion) and apply only on approval, via `gh pr edit --body`.

### 4. Triage every finding

Take open findings in order: `securityIssue`, then P0, P1, P2. For each, read the file around `startLine..endLine` (the file is ground truth, `hunk.before` is a snippet), work out the fix options, and pick the one you would apply. A finding you believe is wrong still goes to the user, with "leave as is" recommended and your evidence in one line.

Present all findings in one batch (AskUserQuestion, one entry per finding: the body and file:line, then the options). Your pick first, labeled `(Recommended)`, and always a "leave as is" option. Apply exactly the fixes the user chooses, and record each declined finding with the user's one-line reason.

Triage is complete only when every open finding is approved-and-fixed or declined.

### 5. Verify and commit

1. Run the repo's checks on the touched files (lint plus the relevant tests). Fix failures before committing.
2. Stage only the files you edited, by path (`git add -- PATH...`), and commit in the repo's commit style. One commit per iteration is fine.
3. Return to step 1. No push.

## Report

End every run (success, review failure, or iteration cap) with: iterations run, final confidence score, counts of findings fixed / declined / remaining, which exit condition fired, each declined finding with the user's reason, and whether the PR description was updated.
