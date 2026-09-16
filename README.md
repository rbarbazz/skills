# skills

Personal Claude Code skills. Claude Code loads skills from `~/.claude/skills/<name>/SKILL.md`, so each skill dir is symlinked back into that directory.

## Install (symlink all skills)

Run from the repo root:

```bash
for d in */; do
  name="${d%/}"
  ln -sfn "$PWD/$name" "$HOME/.claude/skills/$name"
done
```

`-sfn` replaces any existing symlink of the same name, so this is safe to re-run after adding a skill.

Steps shared by `babysit-pr` and `greploop` (PR target, review threads, one-finding-per-question triage, verify and commit) live in `pr-loop.md` at the repo root. Each of those skill dirs holds a `pr-loop.md` symlink to it, so the skill reads the file from its own directory.

## Workflow: from ticket to PR

How the skills chain on a ticket. The split is by how well I understand the ticket, not by its size.

- **Straightforward ticket** (dependency bump, rename, a change the ticket already spells out): `stepwise` on the ticket. Its slicing list is the plan.
- **Unclear or complex ticket**:
  1. Read the ticket and restate the scope in my own words, so the understanding is mine before any plan exists.
  2. Grooming session (`mattpocock-skills:grilling`) until scope and approach are settled. Edit the ticket as answers land: the ticket is the spec.
  3. Plan mode, then clear.
  4. `stepwise` on the plan: one commit at a time, each step approved before it is built and handed over as a digest instead of a diff. Its close maps every ticket requirement to a commit and lists the gaps.
- **After either**, in this order:
  1. Clear, then `mattpocock-skills:code-review` against the base commit `stepwise` reported. A fresh session reviews without the assumptions that shaped the code. This replaces `mattpocock-skills:implement`, which runs the review inside the session that wrote the diff.
  2. `greploop` to drive the branch to a clean Greptile review.
- **Review of someone else's PR**: `pr-review`.
- **PR waiting on CI or reviewers**: `babysit-pr`.
