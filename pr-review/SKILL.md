---
name: pr-review
description: Review a GitHub PR as a reading guide — a verdict line, then the files in reading order, each saying what to check there, with the verified findings nested under it.
disable-model-invocation: true
---

# PR review

A reading guide beside the diff: the user opens the PR and reads it file by file with the report next to it. A verdict line, then the files in reading order, each saying what to check there, with the verified findings nested under it. Read-only on GitHub.

## 1. Target

The argument is a PR number or URL. Without one, the PR is the current branch's (`gh pr view` with no argument); when there is none, ask for it. The PR can be the user's own, draft or ready, or someone else's: the checkout differs, the review is the same.

```bash
gh pr view <number> --json number,url,title,body,baseRefName,headRefName,isDraft,author,files,commits
```

Pick the checkout, first match wins:

1. **The PR head branch is the current branch** (`git branch --show-current` equals `headRefName`: the user's own PR). Review in place. When `git status` shows uncommitted changes, or `git log origin/<headRefName>..HEAD` shows commits not yet pushed, the report opens with one line saying the review covers the local branch, which is ahead of the PR.
2. **The session runs in a worktree the desktop app made** (cwd under `~/HiveHQ/worktrees/`, and `git worktree list` shows it is not the main checkout). Run `gh pr checkout <number>` there.
3. **Otherwise, someone else's PR from the main checkout.** Add a worktree under `~/HiveHQ/worktrees/<repo>/pr-<number>`, next to the implementation worktrees, so the main checkout and other reviews stay untouched. When `git worktree list` already shows a worktree on `headRefName`, reuse it and skip the add.

```bash
cd ~/HiveHQ/<repo>
git fetch origin <baseRefName>
git worktree add --detach ~/HiveHQ/worktrees/<repo>/pr-<number> origin/<baseRefName>
cd ~/HiveHQ/worktrees/<repo>/pr-<number>
gh pr checkout <number>
```

Every later command runs from that checkout, so the review diffs `origin/<baseRefName>...HEAD` on the PR head branch.

Then bind the session to the PR so the app tracks it: call `mcp__ccd_pr__get_status`, and when `bound` is false, call `mcp__ccd_pr__bind_pr` with the PR `url`. Leave the monitor switches as they are (`auto_fix` stays off on someone else's PR: this is a review, not the user's branch). Outside the desktop app these tools are absent: skip the bind.

## 2. Orient

Read the whole diff before summarising anything (`git diff origin/<baseRefName>...HEAD`, plus `--stat`). Skip generated files and lockfiles.

- **The story** — what changes for the product or the system once this PR ships, in one or two sentences, then how the code achieves it. Where the PR description and the diff disagree, the diff wins and the gap is worth a line.
- **The reading order** — the files that carry the change: entry point first (route, command, event handler, migration), then the core logic, then plumbing and tests. One line per file: what to check there, not what the file contains ("check the refund total still subtracts the fee", not "refund logic"). Pure renames, snapshots, and mechanical fallout go in one closing line.

Orientation is complete when every non-trivial changed file has a place in the order or in the closing line.

## 3. Review

Two sources, run together. Both return findings that name a concrete input and what breaks with it; the report keeps every one.

- **Bugs**: invoke the built-in `code-review` skill with `<number> high`. It fans finder sub-agents over the diff, verifies each candidate adversarially, and reports through `ReportFindings`: `file`, `line`, `summary`, `failure_scenario`, and a verdict of CONFIRMED or PLAUSIBLE.
- **Spec**: one sub-agent, given the diff command and the spec sources below. Its brief: "Report (a) requirements the spec asks for that are missing or partial, (b) behaviour the diff adds that the spec never asked for, (c) requirements that look implemented but wrong. Quote the spec line and name its source for each. Under 300 words." With no body and no linked issue, skip it: the report says so in one line above the list.

The spec sources, gathered before the sub-agent starts, each as its full content:

1. The PR title and body.
2. The issue the body or branch name links (Linear key, GitHub `#123`, or URL), with its comments.
3. The issue's parent: for Linear, the project (`get_issue` names it, `get_project` reads it) and the parent issue when there is one.
4. The tech spec: a Linear document attached to that project (`list_documents` filtered on the project), else a Notion page the issue or project links, else a file under `docs/` or `specs/` in the repo whose name matches the branch or feature.

Gathering is complete when each source is either read in full or recorded as absent. The ticket says what to build; the project and tech spec say why and within which limits, so a diff can match the ticket and still breach them.

Severity:

- 🔴 **Blocker**: the code does the wrong thing. A CONFIRMED bug, or a spec requirement missing or implemented wrong.
- 🟠 **Should fix**: the code does the right thing the wrong way. A PLAUSIBLE bug, a cleanup or conventions finding, or behaviour the spec never asked for.

At most 3 findings per file and 8 per PR, 🔴 first: beyond that, the PR is too big for a useful review and the report says so instead of listing more.

## 4. Report

One message, in the user's reply style (the global CLAUDE.md communication rules), on this template. Headings and item shapes stay as written, so the same report reads the same way every run. Lists only: a list wraps in a narrow terminal where a table scrolls sideways.

```markdown
## <🔴 Blocked | 🟠 Fix first | ✅ Mergeable> · <one sentence: what changes for the product once this ships>

1. `<entry point>`: <what to check there>.
   🔴 L<n> Bug: <what breaks, with the concrete input>. Fix: <what to do>.
2. `<core logic>`: <what to check there>.
   🟠 L<n> Spec: <what the spec asked for, quoted, and what the diff does instead>.
3. `<tests>`: <what the new cases cover, and what they miss>.

Mechanical: <renames, snapshots, lockfiles, one line>.
+<n> findings dropped: PR too big for a useful review.
```

The verdict is 🔴 Blocked with any 🔴 finding, 🟠 Fix first with only 🟠 findings, ✅ Mergeable with none. One item per file, in reading order, one line each. A file with no finding is its line alone. A file that carries a finding but no reading-order line still gets an item, after the reading-order files, with "Mechanical" as what to check. Findings sit under their file, 🔴 first, one sentence each naming the source (Bug, Spec, Cleanup) and line, Fix kept short or left out when obvious. The "+n dropped" line appears only when the cap in step 3 cut findings.

The report is complete when every finding sits under its file and the verdict matches the worst severity in the list.
