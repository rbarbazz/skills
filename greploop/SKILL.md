---
name: greploop
description: Iterate a draft PR through Greptile reviews until 5/5 confidence — recommend a fix for every finding, apply only what the user approves, push, re-review.
disable-model-invocation: true
---

# Greploop

Drive a draft PR to a 5/5 Greptile confidence score with zero unresolved Greptile threads, before human review is requested.

Invoking this skill is explicit authorization to push commits to this PR's branch, to trigger Greptile reviews through the Greptile MCP (each one spends review credits), and to post the thread replies the loop needs. The authorization is scoped to this PR. Regular pushes only, never force-push. No comments or messages anywhere else.

Always show the user any reply text before you post it, and post only after they approve the wording.

Shared steps (Target, Threads, Triage, Verify and commit) live in [pr-loop.md](pr-loop.md). Read it first.

## Setup

1. Target, per pr-loop.md.
2. Confirm it is a draft. If it is not a draft, stop and ask the user whether to continue: a non-draft PR may already have human reviewers watching.
3. Repository tuple for the Greptile MCP: `name` (owner/repo), `remote` (`github`), `defaultBranch`. Read them with `gh repo view --json nameWithOwner,defaultBranchRef`. Every Greptile MCP call below takes this tuple plus the PR number.

## The loop

Repeat until an exit condition, at most 5 iterations.

### 1. Get a review of the current head

- `list_code_reviews` filtered by `prNumber`. The review of the current head is the run whose `commitSha` equals the head commit.
- If that run is `COMPLETED`, move on. If it is `PENDING`, `REVIEWING_FILES`, or `GENERATING_SUMMARY`, wait for it. If there is no run for the head, `trigger_code_review`: a success response means the request is queued, not that the review is done.
- Poll `list_code_reviews` every 30 seconds, up to 10 minutes. On timeout, or on a `FAILED` or `SKIPPED` run for the head, stop and report.

### 2. Read the results

- Confidence score: `get_code_review` with the run's id, then match `Confidence Score: ([0-5])/5` in `body`. If no score is found, show the user the body and ask how to read it.
- Findings: Threads, per pr-loop.md, keeping the unresolved threads authored by the Greptile bot. Thread resolution lives only in GitHub. The MCP's `addressed` flag is Greptile's own bookkeeping and stays false on a declined finding, so it plays no part in the exit check.

### 3. Exit check

Close the loop when either condition holds. Greptile resolves threads itself on re-review once a bug is fixed, so an unresolved thread that is neither fixed nor declined means more work remains.

- **Clean pass** — score is 5/5 and every Greptile thread is resolved.
- **Accepted below 5/5** — every open Greptile comment has been responded to (fixed, or declined with a reply), and the user has intentionally accepted the current sub-5/5 score. Confirm this with the user before stopping, do not assume it.

On either exit, write the report and stop.

Description pass on success: read the current PR description and compare it against the branch's full diff, which now includes every fix the loop made. Draft a revised description in the repo's PR style that covers what changed during the loop. Show the user the current and proposed descriptions and ask for confirmation (AskUserQuestion). Apply only what the user approves, via `gh pr edit --body`; if they decline, leave the description untouched.

### 4. Triage every finding

Triage, per pr-loop.md, over the Greptile findings. On a declined finding (the user picks "leave as is" or gives their own answer), reply on the thread with the user's one-line reasoning.

### 5. Verify, push, resolve

1. Verify and commit, per pr-loop.md.
2. Push. If this PR is part of a gh-stack (its branch belongs to a stack), invoke the `gh-stack` skill to rebase the stack and push, so the branches above it pick up the new commit. Otherwise push the PR branch directly.
3. Return to step 1. Leave thread resolution to Greptile: it resolves a thread on re-review once the bug is fixed.

## Report

End every run (success, timeout, or iteration cap) with: iterations run, final confidence score, counts of findings fixed / declined / remaining, which exit condition fired, and on success whether the PR description was updated.
