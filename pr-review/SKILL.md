---
name: pr-review
description: Review a GitHub PR — a plain-language summary, then the files to read in order, each with the mattpocock-skills:code-review findings nested under it.
disable-model-invocation: true
---

# PR review

A recap of what the PR does in plain terms, then the files to read in order, each with the `mattpocock-skills:code-review` findings that land in it nested under it. Read-only on GitHub.

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

One message, in the user's reply style (the global CLAUDE.md communication rules), on this template. Headings and item shapes stay as written, so the same report reads the same way every run. Lists only: every line wraps in a narrow terminal, where a table scrolls sideways.

```markdown
## Summary

**<one sentence: what changes for the product or the system once this ships>**

<why the change is needed, then how the code achieves it, one short paragraph>

- **Standards**: 🔴 <n> 🟠 <n> 🟡 <n>. Worst: <one line, or "none">.
- **Spec**: 🔴 <n> 🟠 <n> 🟡 <n>. Worst: <one line, or "none">.

## Files

1. **`<entry point>`**: <what happens there>.
   - 🔴 Spec L<n>: <spec line it misses, then what the code does instead>. Fix: <what to do>.
   - 🟡 Standards L<n>: <what is wrong>. Fix: <what to do>.
2. **`<core logic>`**: <what happens there>. No finding.

Mechanical fallout: <renames, snapshots, lockfiles, one line>.
```

One item per file, in reading order. A file that carries a finding but no reading-order line still gets an item, after the reading-order files, with "Mechanical" as what happens there. Findings nest under their file, 🔴 first, each naming its axis and line. A file with no finding ends its line with "No finding". When the Spec sub-agent skipped for lack of a spec, one line above the list says so. Worst repeats the one-line conclusion the code-review skill ends with, split per axis.

The report is complete when every finding in the code-review output sits under its file and the axis counts match the findings in the list.
