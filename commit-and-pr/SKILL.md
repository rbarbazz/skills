---
name: commit-and-pr
description: Commit and PR conventions. Use before any git commit, splitting work into commits, addressing PR review feedback, gh pr create, or writing a PR description.
---

# Commits

- Commit locally, never push. `git commit && git push` counts as a push.
- One logical change per commit, in dependency order (model, plumbing,
  feature). Each commit leaves the tree working.
- Review feedback goes in a new commit on top. Amend only pre-review.
- Over 400 changed lines: split into a stack, per the `pr-stacks` skill.

# PR

Always `gh pr create --draft`. Use the repo's PR template when one exists and
map the sections below onto its headings. Drop template sections that do not
apply. Carry the ticket link and the links it contains.

```markdown
## Summary

<two or three sentences: the product problem and why the change exists>

<diagram, diff-sketch, or tree>

- <one bullet per change: what a user or the system does differently>

## Evidence

- **Before:** <screenshot/output/failing test run>
  **After:** <screenshot/output/passing test run>

## Merge Danger

**Door:** <one-way or two-way>

**Blast Radius:** <one-word description>

<optional: ramifications>
```

Skip preambles, keep prose brief, use the product's domain nouns. Fits on
one screen.

## Summary

Pick the smallest view that makes the key point clear: pseudocode for
logic, a call tree for control flow, a component tree for UI, a shallow file
tree for a refactor, Mermaid for data flow, a `diff` of one of those when the
shape already exists. Keep only the calls, files, and states needed to make
the point. A mechanical diff gets no visual.

Bullets stay at product altitude: the how lives in the diff.

- ❌ "`JobLock.release`: a `finally` block now deletes the lock key."
- ✅ "A job whose worker crashes now frees its lock within 30 seconds."

## Evidence

Screenshots when the change is visual. Otherwise a shell snippet
(`./manage.py shell`, `rails console`), a command, or the exact test that
failed before and passes now, with output. Proof lives here, not in
committed scripts.

## Merge Danger

Two-way doors can be walked back, one-way doors (data migrations, dropped
columns, public API changes) cannot. Blast radius: every surface that breaks
if the PR misbehaves (consumers, layout, mobile, background jobs).

Credits: Matt Pocock's [`pr`](https://github.com/mattpocock/skills/tree/main/skills/engineering/pr) (MIT), itself after Dex Horthy's `show-me`.
