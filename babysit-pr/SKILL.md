---
name: babysit-pr
description: Babysit an open GitHub PR until CI is green and every review comment is addressed — fix CI failures locally, triage review comments, recap before anything touches GitHub.
disable-model-invocation: true
---

# Babysit a PR

A collaborative loop: snapshot → exit check → CI → comments → recap → the user acts → repeat. The loop closes when CI is green and every review comment is addressed. Each iteration ends in a recap the user must act on — approving fixes, posting replies, pushing — so the loop advances one user turn at a time and never runs unattended.

Parse JSON output with `jq` — it runs without a permission prompt, so each pass stays hands-off.

**The recap is the gate.** The only code this skill writes on its own is a fix for a failing CI check (loop step 3) — diagnose, edit, run the test, commit locally. It writes **no** code for review comments until the user approves the recap: every comment is triaged into a recommendation first. Every action that touches GitHub — push, thread reply, check re-run — is likewise a proposed action in the recap. The user pushes and replies themselves unless they explicitly hand one back.

**Thread resolution belongs to reviewers.** A reviewer closes their own thread once they're satisfied; this skill never resolves a thread and never proposes resolving one — not even in the recap.

## Target

- No argument → the open PR for the current branch (`gh pr view`).
- A number or URL → that PR.
- Several PRs match the branch → ask which one.
- PR is merged or closed → say so and stop.

## The loop

Repeat until the exit check passes, at most 5 iterations. An issue surviving three iterations → flag it to the user as stuck.

### 1. Snapshot

Fetch head SHA, mergeability, and the check rollup:

```bash
gh pr view <number> --json number,title,body,headRefOid,mergeable,mergeStateStatus,statusCheckRollup
gh pr checks <number>
```

Scan the PR body for TODOs and placeholder sections — an unfinished description is a report item like any other.

Fetch every review thread with its resolved state (query in the command reference). Resolved/outdated state lives only in GraphQL, and the GraphQL endpoint is POST-only — this is the one read that does *not* take `--method GET`, but it is still read-only. While `hasNextPage` is true, repeat with `-F cursor=<endCursor>` — the snapshot is complete only when every thread page is in.

Top-level PR comments (bots often post here too, outside any thread) come from REST:

```bash
gh api --method GET --paginate "repos/{owner}/{repo}/issues/<number>/comments?per_page=100"
```

Filter comments by content, not author: drop pure CI-status noise and resolved threads; keep any comment carrying a finding, even from a bot (review bots are content, not noise). Some review bots edit one general comment in place each cycle instead of posting a new one — read the latest version of each bot comment by `updated_at` before concluding it carries nothing new.

### 2. Exit check

Close the loop when both conditions hold:

- **CI green** — every check on the current head passing, none failing or pending.
- **Comments addressed** — every outstanding comment is either fixed in a commit that is on the PR branch, or answered by a reply the user approved and posted. Nothing is waiting on our side; open threads may still wait on a reviewer to resolve them, and that wait belongs to the reviewer, not the loop.

On exit, write the report and stop.

### 3. CI

All checks green → move on. Checks still pending or queued and no other work remains this iteration → wait for them (`gh pr checks <number> --watch`), then re-snapshot; otherwise list them as pending and continue.

List the failing checks with their target URLs first — the URL tells you which system to pull logs from:

```bash
gh pr checks <number> | grep -iE 'fail|error'
```

For each failing check, pull the failed job's log:

- **GitHub Actions** (URL contains `github.com/.../actions/runs/`): `gh run view <run-id> --log-failed` once the run is complete, or `gh api --method GET repos/{owner}/{repo}/actions/jobs/<job-id>/logs` while it is still running. The run-id and job-id are in the check's details URL.
- **CircleCI** (URL contains `circleci.com`): use the CircleCI MCP tools (load via ToolSearch if deferred), not `gh` — `gh` can't reach CircleCI job logs. `mcp__circleci-mcp-server__get_build_failure_logs` takes the failed job's URL (the one from `gh pr checks`) or the PR's branch/project.

Name the root cause before writing any fix — no patch without a named cause. Then classify:

- **Branch-related** — the log points at changed code (compile, test, lint, type, or snapshot failures in touched areas) → fix it locally and commit. First confirm the local checkout is on the PR head branch with a clean working tree, and pull if behind; a dirty tree or wrong branch turns the fix into a proposed action in the recap instead. The commit stays local.
- **Flaky / infra** — timeouts, runner provisioning, registry or network outages → no code change; propose a re-run in the recap.
- **Invisible** — the finding lives in an external dashboard the CLI can't reach (SonarQube, Snyk, …) → stop guessing; ask the user to paste the findings before processing anything else.

### 4. Comments

Bucket every outstanding comment into exactly one recommendation. When unsure, it is Discuss.

- **Valid** — real bug, security issue, logic error, or clear actionable suggestion → describe the fix you would make and draft the thread reply. Do not write or commit it yet.
- **Discuss** — ambiguous, a design tradeoff, or a possible misread of the code → draft a recommended response with your assessment.
- **Out-of-scope** — outside this PR's stated goal → recommend deferring, with a suggested reply and, when it fits, a ticket-worthy summary.
- **Already addressed** — a later commit on the branch resolves it → one line naming that commit and a draft reply the reviewer can verify against; the reviewer resolves the thread themselves.

Across iterations, a comment already covered by an earlier recommendation or an approved fix gets one line pointing back to it, not a fresh triage.

### 5. Recap and go-ahead

End the iteration with the recap:

1. **CI** — green, or each failure with its named cause, its class, and the local fix commit SHA if one was made; pending checks listed as pending.
2. **Comments** — every item with its bucket and recommendation: the fix you propose (not yet written), a draft reply, or a defer.
3. **Description** — TODOs or placeholder sections found in the PR body, if any.
4. **Awaiting go-ahead** — the comment fixes to write once approved, plus the actions only the user can take: push, post replies, re-run checks.

An iteration is complete only when every failing check has a named cause and every outstanding comment has a bucket and a recommendation.

Then act on the user's answer:

- Approved comment fixes → write them, run the repo's checks on the touched files, commit locally.
- The user pushes and posts the approved replies themselves, then tells the loop to continue.
- Return to step 1.

## Report

End every run — success, iteration cap, or stuck — with: iterations run, which exit condition fired (or why the loop stopped short), CI state, and counts of comments fixed / replied / deferred / remaining.

## Command reference

Review threads with resolved state (paginated):

```bash
gh api graphql -F owner='{owner}' -F repo='{repo}' -F pr=<number> -f query='
query($owner:String!, $repo:String!, $pr:Int!, $cursor:String) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$pr) {
      reviewThreads(first:100, after:$cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          isResolved
          isOutdated
          path
          line
          comments(first:50) { nodes { author { login } body url } }
        }
      }
    }
  }
}'
```
