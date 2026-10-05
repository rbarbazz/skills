---
name: commit-and-pr
description: Commit and PR conventions. Use before any git commit, splitting work into commits, addressing PR review feedback, gh pr create, or writing a PR description.
---

# Commits and PRs

- **Commit locally when work is ready, and keep `push` out of chained
  commands** (`git commit && git push` counts as a push).
- **Split work into separate logical commits in dependency order.** Each
  commit leaves the tree working and self-consistent. Group commits the way a
  stacked review would read them: model/migration first, plumbing next, the
  feature that wires them last. Unrelated changes get their own commits.
- **Address PR review feedback with a new commit on top.** The reviewed
  commit is the reviewer's reference point: amending rewrites it, requires a
  force-push, and hides what changed since the review. Amending is fine while
  the branch is pre-review.
- **Always create PRs as draft**: `gh pr create --draft`, and never pass
  `--open` to `gh stack submit`. Ready-for-review PRs trigger reviewer
  notifications and CI expectations I don't want yet.
- **Always use the repo's PR template when one exists**, passed via
  `--body`/`--body-file`. Delete template sections that are irrelevant to the
  change instead of filling them with "N/A". If unsure what to write for a
  section, or whether it is relevant, ask me rather than guessing.
- **Write the PR description as a short re-pitch for a teammate with zero
  conversation context.** It answers one question: what does this PR change,
  and why? Layout, section menu, and the visual formats live in
  [pr-body.md](pr-body.md): read it before writing a PR body. Open the
  Summary with the premise (the product problem and why the change exists)
  in two or three sentences, then the smallest visual that makes the key
  point clear, then one bullet per change, one sentence each. Same
  Simplified Technical English as CLAUDE.md, but define a term only when a
  reviewer could actually misread it: skip the repo's established domain
  nouns.
  - **Description bullets stay at product altitude.** Each one says what a
    user or the system observably does differently after the change: the
    what and the why. The how stays in the diff and in the Summary visual.
    Name a code symbol only when the reader needs it to understand the
    behavior change, not to locate the code.
    - ❌ "`JobLock.release`: a `finally` block now deletes the lock key."
    - ✅ "A job whose worker crashes now frees its lock within 30 seconds
      instead of 10 minutes."
  - **Manual Testing steps are procedural**: one plain sentence each, the
    action and its expected result, commands and keys allowed. A surprising
    timing or behavior goes in a short parenthesis.
  - **Use the product's established domain nouns** (order, invoice,
    workspace, subscription) as the team says them. A parenthetical label like
    "(server-authoritative)" is session vocabulary: write the plain sentence
    it stands for.
  - **Scale to the change's size and risk**, not to the effort behind it: a
    mechanical diff earns a few sentences and no visual. Default target: the
    whole description fits on one screen without scrolling.
- **Carry ticket context into the PR description**: a link to the ticket,
  and any links it contains such as the overarching tech spec.
- **Every PR is reviewable by observation, not just by reading the diff.**
  Each PR ships with its own tests, and its Evidence section shows the change
  working before and after, per pr-body.md. Its Merge Danger section names
  the door (one-way or two-way) and the blast radius.
- **Multi-part work is a GitHub native stack.** Keep each PR under 400
  changed lines: past that, split into another PR in the stack. Invoke
  the `pr-stacks` skill.
