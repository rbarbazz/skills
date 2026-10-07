---
name: cleanup-worktrees
description: Remove a repo's linked worktrees whose PR is merged or closed or whose remote branch is gone, prune its stale worktree records, and report what every kept worktree still holds. Takes repo paths as arguments, defaults to the current repo.
disable-model-invocation: true
---

# Cleanup worktrees

Every removal goes through `scripts/cleanup-worktrees.sh` (zsh, macOS): it
carries the guards a manual `git worktree remove` skips (uncommitted changes,
detached HEAD, never-pushed branch, failed fetch, a lock against overlapping
runs). Its header comment is the single source of the removal rules: read it
when the user asks why a worktree was or was not removed.

The arguments are repo paths (any directory inside the repo works). Without
one, the script runs on the repo of the current directory. Words like
`delete`, `real`, or `--yes` among the arguments are the deletion go-ahead
(see step 2), never a path.

## 1. Preview

```bash
zsh ~/.claude/skills/cleanup-worktrees/scripts/cleanup-worktrees.sh --dry-run <repo>...
```

Summarize per worktree, in plain terms: what would be removed and why, what
is kept and what it still holds (see Reading the output). Complete when every
worktree in the output appears in the summary. Nothing removable: say so and
stop.

## 2. Delete

Only after the user confirms, or when the request already asked for real
deletion (in the message: "clean them up for real", or as a skill argument:
`delete`, `real`, `--yes`):

```bash
zsh ~/.claude/skills/cleanup-worktrees/scripts/cleanup-worktrees.sh <repo>...
```

Report what was removed, every `skip` and `ERROR` line, and what the prune
pass did.

## Reading the output

- `would remove …` (dry-run) / `removed …`: the reason is in parentheses.
- `keep …`: branch still active, with the PR state.
- `skip …`: a guard fired (uncommitted changes, detached HEAD, directory
  missing, argument not a git repository). The user handles these by hand,
  so name each one.
- Indented lines under a `keep` or `skip … uncommitted changes` entry are
  what that worktree still holds: `git status --short` lines for uncommitted
  files, then `unpushed: <sha> <subject>` for commits not yet on the remote.
  Relay them per worktree so the user can decide what to push, commit, or
  drop. A detached HEAD worktree (checked out on a commit, not a branch) has
  no remote to compare against, so it gets no such lines.
- `prune <repo>: …`: stale worktree records cleared from that repo.
- `ERROR: failed to remove …`: `git worktree remove` refused, commonly a
  worktree holding submodules. Tell the user; that removal is theirs to do by
  hand.
- `skip run: another instance … is running`: wait and rerun; the lock clears
  itself when that run ends.
- `skip <repo>: fetch failed`: the network or the keychain holding the `gh`
  token was unavailable. The script touches nothing in that repo; say so.
