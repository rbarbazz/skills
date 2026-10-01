---
name: pr-stacks
description: Preferences for stacked PRs on GitHub native stacks. Use when splitting multi-part work into a stack, or creating, submitting, or rebasing a stack with gh stack.
---

# PR stacks

- **Multi-part work is a GitHub native stack**, not one big PR and not
  separate PRs that merely cross-reference each other. Load the `gh-stack`
  skill for the commands (init, add, submit, sync, rebase, navigation).
- **Commit locally and stop for my review before submitting.** After
  `gh stack submit`, apply the repo's PR template and issue link via
  `gh pr edit` (submit auto-generates PR bodies).
- **The PR body carries the ticket link and each PR's standalone notes**
  ("safe to merge alone", "no consumer yet"). The native stack renders the
  chain and links the siblings, so the body needs no ASCII diagram and no
  "Layer N of the stack" line.
- **After any stack rewrite, run tests at every branch tip, bottom first.**
  Every PR in the stack must pass CI on its own: a symbol used by commit N
  must be introduced in commit N or earlier, and testing only the top tip
  hides a broken lower layer. `git checkout <each-branch>` and run the
  relevant tests per layer before calling it done.
- **When rebasing a stack onto a squash-merged trunk, resolve each conflict
  as master's current version plus the branch commit's intended delta.** Read
  the original commit's diff (`git show <sha> -- file`), then apply that
  change on top of master's version. Taking the old branch tip's file
  wholesale (`git checkout <old-branch-tip> -- file`) silently reverts what
  master gained since the branch was based.
