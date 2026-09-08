---
name: pr-review
description: Review a GitHub PR — a plain-language summary with the files to read in order, then the two-axis mattpocock-skills:code-review report underneath.
disable-model-invocation: true
---

# PR review

Two layers, summary on top: first a recap of what the PR does in plain terms, with the files to read and in what order, then the `mattpocock-skills:code-review` report so the user can go deeper. Read-only on GitHub: nothing is posted, nothing is pushed.

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
- **The reading order** — a numbered list of the files that carry the change: entry point first (route, command, event handler, migration), then the core logic, then plumbing and tests. One line per file: what to look for there. Pure renames, snapshots, and mechanical fallout go in one closing line, not in the list.

Orientation is complete when every non-trivial changed file has a place in the order or in the closing line.

## 3. Review

Build the spec for the code-review skill: write the PR title and body to a scratchpad file, then append the content of any issue the body links (Linear key, GitHub `#123`, or URL). Invoke `mattpocock-skills:code-review` with fixed point `origin/<baseRefName>` and that file as the spec path. Let it run to its own report.

## 4. Report

One message, two sections, in this order:

1. **Summary** — in the user's reply style (the global CLAUDE.md communication rules):
   - What this PR does, effect first, then the mechanism.
   - Why the change is needed: the problem it fixes or the feature it enables.
   - The reading order from step 2.
   - Review conclusion: the one-line summary the code-review skill ends with (findings per axis, worst issue within each). No reranking across axes.
2. **Code review** — the code-review report as it came, `## Standards` and `## Spec` headings intact.
