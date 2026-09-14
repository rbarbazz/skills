---
name: pr-review
description: Review a GitHub PR — a plain-language summary with the files to read in order, the two-axis mattpocock-skills:code-review report, then a quiz the user answers in chat.
disable-model-invocation: true
---

# PR review

Three layers, summary on top: first a recap of what the PR does in plain terms, with the files to read and in what order, then the `mattpocock-skills:code-review` report so the user can go deeper, then a short quiz the user answers to check they understood the PR. Read-only on GitHub: nothing is posted, nothing is pushed.

## 1. Target

- No argument → the open PR for the current branch (`gh pr view`).
- A number or URL → that PR.
- Several PRs match the branch → ask which one.

```bash
gh pr view <number> --json number,title,body,baseRefName,headRefName,files,commits
git fetch origin <baseRefName>
```

The review diffs against `HEAD`, so the local checkout must sit on the PR head branch. If it does not, `gh pr checkout <number>`. A dirty working tree stops here: ask the user to stash or commit before continuing.

## 2. Orient

Read the whole diff before summarising anything (`git diff origin/<baseRefName>...HEAD`, plus `--stat`). Skip generated files and lockfiles.

- **The story** — what changes for the product or the system once this PR ships, in one or two sentences, then how the code achieves it. Where the PR description and the diff disagree, the diff wins and the gap is worth a line.
- **The reading order** — the files that carry the change: entry point first (route, command, event handler, migration), then the core logic, then plumbing and tests. One line per file: what to look for there. Pure renames, snapshots, and mechanical fallout go in one closing line.

Orientation is complete when every non-trivial changed file has a place in the order or in the closing line.

## 3. Review

Build the spec for the code-review skill: write the PR title and body to a scratchpad file, then append the content of any issue the body links (Linear key, GitHub `#123`, or URL). Invoke `mattpocock-skills:code-review` with fixed point `origin/<baseRefName>` and that file as the spec path. Let it run to its own report.

## 4. Quiz

Write the questions the user answers in chat. Each question names one file to read and asks for something that file shows, so the answer lives in the code and the question only points at it.

- **Two general questions** on the flow around the change: what triggers the changed code (which route, event, job, or user action reaches it), and what happens downstream once it has run (who consumes the result, what the user or system sees). Add a "why this way" question when the PR made a visible choice over an alternative (a new column instead of a computed value, a flag instead of a delete).
- **Two or three technical questions** on the code itself: what a specific changed function or branch does, what a given input produces, or what happens in an edge case the PR handles (empty list, retry, missing field).

The quiz is complete when the entry point and the core logic from the reading order each carry at least one question. A PR of pure mechanical fallout (renames, dependency bumps, generated code) gets one line saying the quiz is skipped instead.

## 5. Report

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

| Axis | Findings | Worst |
|-----------|----|-----|
| Standards | <n> | <one line, or "none"> |
| Spec | <n> | <one line, or "none"> |

## Code review

<the code-review report as it came, its `## Standards` and `## Spec` headings demoted to `###`>

## Quiz

| # | File | Question |
|---|------|----------|
| 1 | `<path>` | <flow question> |
| 2 | `<path>` | <flow question> |
| 3 | `<path>` | <code question> |

<one-line invitation to answer in chat>
```

The Axis table repeats the one-line conclusion the code-review skill ends with, split per axis, no reranking across axes.

## 6. Grade

When the user answers, re-read the diff hunk behind each question before grading it, then reply on this template:

```markdown
| # | Verdict | Answer |
|---|---------|--------|
| 1 | correct | |
| 2 | partial | <only the missing piece, with `file:line`> |
| 3 | wrong | <the right answer, with `file:line`> |
| 4 | skipped | <the right answer, with `file:line`> |

<when an answer reveals a wrong mental model about the flow: one or two sentences that correct the model>

Re-read: `<file>`, `<file>`
```

Grading is complete when every question has its row. The Re-read line lists the files behind every partial or wrong row, or is dropped when all rows are correct.
