---
name: babysit-pr
description: Babysit an open GitHub PR until CI is green and every review comment is addressed — fix CI failures locally, triage review comments one at a time, the user pushes and replies.
disable-model-invocation: true
---

# Babysit a PR

A collaborative loop: snapshot → exit check → CI → comments → commit → recap → the user acts → repeat. The loop closes when CI is green and every review comment is addressed. Each iteration ends in a recap of what landed and of the actions only the user can take (push, post replies, re-run checks), so the loop advances one user turn at a time and never runs unattended.

Shared steps (Target, Threads, Triage, Verify and commit) live in [pr-loop.md](pr-loop.md). Read it first.

**Two kinds of code change.** A fix for a failing CI check is written on this skill's own initiative (step 3): diagnose, edit, test, commit locally. A fix for a review comment is written only after the user approves it in Triage, one comment per question. Every action that touches GitHub (push, thread reply, check re-run) belongs to the user: the recap proposes, the user acts.

**Thread resolution belongs to reviewers.** A reviewer closes their own thread once satisfied. This skill never resolves a thread and never proposes resolving one.

## Setup

Target, per pr-loop.md.

## The loop

Repeat until the exit check passes, at most 5 iterations. An issue surviving three iterations → flag it to the user as stuck.

### 1. Snapshot

Fetch head SHA, mergeability, and the check rollup:

```bash
gh pr view <number> --json number,title,body,headRefOid,mergeable,mergeStateStatus,statusCheckRollup
gh pr checks <number>
```

Scan the PR body for TODOs and placeholder sections: an unfinished description is a report item like any other.

Threads, per pr-loop.md. Top-level PR comments (bots often post here too, outside any thread) come from REST:

```bash
gh api --method GET --paginate "repos/{owner}/{repo}/issues/<number>/comments?per_page=100"
```

Filter comments by content, not author: drop pure CI-status noise and resolved threads; keep any comment carrying a finding, even from a bot (review bots are content, not noise). Some review bots edit one general comment in place each cycle instead of posting a new one: read the latest version of each bot comment by `updated_at` before concluding it carries nothing new.

### 2. Exit check

Close the loop when both conditions hold:

- **CI green** — every check on the current head passing, none failing or pending.
- **Comments addressed** — every outstanding comment is either fixed in a commit that is on the PR branch, or answered by a reply the user approved and posted. Nothing is waiting on our side; open threads may still wait on a reviewer to resolve them, and that wait belongs to the reviewer, not the loop.

On exit, write the report and stop.

### 3. CI

All checks green → move on. Checks still pending or queued and no other work remains this iteration → wait for them (`gh pr checks <number> --watch`), then re-snapshot; otherwise list them as pending and continue.

List the failing checks with their target URLs first: the URL tells you which system to pull logs from.

```bash
gh pr checks <number> | grep -iE 'fail|error'
```

For each failing check, pull the failed job's log:

- **GitHub Actions** (URL contains `github.com/.../actions/runs/`): `gh run view <run-id> --log-failed` once the run is complete, or `gh api --method GET repos/{owner}/{repo}/actions/jobs/<job-id>/logs` while it is still running. The run-id and job-id are in the check's details URL.
- **CircleCI** (URL contains `circleci.com`): use the CircleCI MCP tools (load via ToolSearch if deferred), not `gh`, which can't reach CircleCI job logs. `mcp__circleci-mcp-server__get_build_failure_logs` takes the failed job's URL (the one from `gh pr checks`) or the PR's branch/project.

Name the root cause before writing any fix: no patch without a named cause. Then classify:

- **Branch-related** — the log points at changed code (compile, test, lint, type, or snapshot failures in touched areas) → fix it locally and commit. The commit stays local.
- **Flaky / infra** — timeouts, runner provisioning, registry or network outages → no code change; propose a re-run in the recap.
- **Invisible** — the finding lives in an external dashboard the CLI can't reach (SonarQube, Snyk, …) → stop guessing; ask the user to paste the findings before processing anything else.

### 4. Comments

Triage, per pr-loop.md, over every outstanding comment: unresolved threads plus top-level findings. The options offered for a comment follow from what the comment is:

- **Fix** — a real bug, security issue, logic error, or clear actionable suggestion: the option names the fix in one line. Approved → apply it now and draft the thread reply.
- **Reply only** — a design tradeoff, a possible misread of the code, a request outside this PR's stated goal, or something a later commit on the branch already resolves (name that commit): the option carries the draft reply, plus a ticket-worthy summary when deferring.
- **Leave as is** — always present.

When unsure between fix and reply, recommend the reply. Draft replies go in the recap for the user to post; this skill posts nothing.

### 5. Verify and commit

Per pr-loop.md, covering the comment fixes approved in step 4. CI fixes were already committed in step 3.

### 6. Recap

End the iteration with:

1. **CI** — green, or each failure with its named cause, its class, and the local fix commit SHA if one was made; pending checks listed as pending.
2. **Comments** — every item with its decision: fixed (commit SHA) with the draft reply, reply drafted, or left as is.
3. **Description** — TODOs or placeholder sections found in the PR body, if any.
4. **Your turn** — push, post the drafted replies, re-run flaky checks.

An iteration is complete only when every failing check has a named cause and every outstanding comment has a decision.

The user pushes and posts the replies themselves, then tells the loop to continue. Return to step 1.

## Report

End every run (success, iteration cap, or stuck) with: iterations run, which exit condition fired (or why the loop stopped short), CI state, and counts of comments fixed / replied / left as is / remaining.
