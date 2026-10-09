---
name: pr-review
description: Review a GitHub PR — a plain-language summary with the files to read in order, then the two-axis mattpocock-skills:code-review report.
disable-model-invocation: true
---

# PR review

Two layers, summary on top: first a recap of what the PR does in plain terms, with the files to read and in what order, then the `mattpocock-skills:code-review` report so the user can go deeper. Read-only on GitHub.

## 1. Target

The argument is a PR number or URL. Without one, ask for it.

Each review runs in its own worktree, so the main checkout and other reviews stay untouched.

```bash
gh pr view <number> --json number,url,title,body,baseRefName,headRefName,files,commits
```

When the session already runs in a worktree the desktop app made (the "new worktree" checkbox: cwd under `~/HiveHQ/worktrees/`, and `git worktree list` shows it is not the main checkout), review in that worktree: run `gh pr checkout <number>` there and skip the add below. The app then archives the session, and removes its worktree, once the PR merges or closes.

Otherwise, add one under `~/HiveHQ/worktrees/<repo>/pr-<number>`, next to the implementation worktrees:

```bash
cd ~/HiveHQ/<repo>
git fetch origin <baseRefName>
git worktree add --detach ~/HiveHQ/worktrees/<repo>/pr-<number> origin/<baseRefName>
cd ~/HiveHQ/worktrees/<repo>/pr-<number>
gh pr checkout <number>
```

`gh pr checkout` runs inside the worktree so the review diffs against `HEAD` on the PR head branch. When `git worktree list` already shows a worktree on the PR head branch (a previous review, or the user's own branch), reuse it and skip the add. Every later command in this skill runs from the worktree.

Then bind the session to the PR so the app tracks it: call `mcp__ccd_pr__get_status`, and when `bound` is false, call `mcp__ccd_pr__bind_pr` with the PR `url`. Leave the monitor switches as they are (`auto_fix` off: this is a review, not the user's branch). Outside the desktop app these tools are absent: skip the bind.

## 2. Orient

Read the whole diff before summarising anything (`git diff origin/<baseRefName>...HEAD`, plus `--stat`). Skip generated files and lockfiles.

- **The story** — what changes for the product or the system once this PR ships, in one or two sentences, then how the code achieves it. Where the PR description and the diff disagree, the diff wins and the gap is worth a line.
- **The reading order** — the files that carry the change: entry point first (route, command, event handler, migration), then the core logic, then plumbing and tests. One line per file: what to look for there. Pure renames, snapshots, and mechanical fallout go in one closing line.

Orientation is complete when every non-trivial changed file has a place in the order or in the closing line.

## 3. Review

Build the spec for the code-review skill: write the PR title and body to a scratchpad file, then append the content of any issue the body links (Linear key, GitHub `#123`, or URL). Invoke `mattpocock-skills:code-review` with fixed point `origin/<baseRefName>` and that file as the spec path. Let it run to its own report.

Then split its prose into findings and give each one a severity:

- 🔴 **Blocker**: the code does the wrong thing. A spec requirement missing or implemented wrong, or a documented-standard breach that changes behaviour.
- 🟠 **Should fix**: the code does the right thing the wrong way. Scope creep, or a documented-standard breach that only touches convention or structure.
- 🟡 **Judgement call**: a baseline smell, a nit, a comment or line that could go. The code-review report labels these itself.

A finding keeps the axis it came from.

## 4. Report

One message, in the user's reply style (the global CLAUDE.md communication rules), on this template. Headings and table columns stay as written, so the same report reads the same way every run.

```markdown
## Summary

**<one sentence: what changes for the product or the system once this ships>**

<why the change is needed, then how the code achieves it, one short paragraph>

| # | File | Look for |
|---|------|----------|
| 1 | `<entry point>` | <what happens there> |
| 2 | `<core logic>` | ... |

Mechanical fallout: <renames, snapshots, lockfiles, one line>.

| Axis | 🔴 | 🟠 | 🟡 | Worst |
|-----------|---|---|---|-------|
| Standards | <n> | <n> | <n> | <one line, or "none"> |
| Spec | <n> | <n> | <n> | <one line, or "none"> |

## Code review

### Standards

| | File | Finding | Fix |
|---|------|---------|-----|
| 🔴 | `<path:line>` | <what is wrong, one sentence> | <what to do, one sentence> |
| 🟡 | `<path:line>` | ... | ... |

### Spec

| | File | Finding | Fix |
|---|------|---------|-----|
| 🔴 | `<path:line>` | <spec line it misses, then what the code does instead> | ... |
```

Rows sort 🔴 first inside each axis, never across axes. An axis with no finding gets one line, "No finding", instead of an empty table. When the Spec sub-agent skipped for lack of a spec, the Spec section says so in one line. The Worst column repeats the one-line conclusion the code-review skill ends with, split per axis.

The report is complete when every finding in the code-review output has a row and the Axis counts match the rows.
