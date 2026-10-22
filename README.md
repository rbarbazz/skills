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

## Skills in regular use

Skills from this repo are named bare. Plugin skills carry their plugin prefix.

### Shaping the work

- **`mattpocock-skills:grilling`**: stress-test a plan or idea until scope and approach are settled.
- **`mattpocock-skills:to-spec`**: turn a settled grilling into a spec, when it holds more than one ticket.
- **`mattpocock-skills:to-tickets`**: cut a spec into tickets.

### Building

- **`stepwise`**: implement one ticket, one approved commit at a time, each handed over as a digest. Its close maps every requirement to a commit and lists the gaps.
- **`commit-and-pr`**: commit conventions and the draft PR body (effect sentence, one diagram, evidence).
- **`pr-stacks`**: split multi-part work into a stack of PRs with `gh stack`.

### Reviewing

- **`pr-review`**: review a PR, mine or someone else's, as a reading guide: verdict, files in reading order, verified findings under each file, spec checked against the ticket, its project and the tech spec.
- **`ponytail:ponytail-review`**: review for over-engineering only, when a solution feels heavier than the problem. One line per finding: what to delete, what replaces it.
- **`greploop`**: drive a draft PR through Greptile reviews until 5/5 confidence.
- **`babysit-pr`**: sit on an open PR until CI is green and every review comment is addressed.

### Understanding

- **`mattpocock-skills:wait-what`**: the last message did not land. Re-pitch it with context, in Simplified Technical English and the repo's ubiquitous language.

### Writing

- **`writing-docs`**: structure and style for tech specs, design docs, proposals and Notion pages in my voice.
- **`notion-editing`**: keep comment anchors intact when editing an existing Notion page.
- **`mattpocock-skills:writing-for-agents`**: write or edit a skill, `AGENTS.md` or `CLAUDE.md`.

### Housekeeping

- **`cleanup-worktrees`**: remove a repo's worktrees whose PR is merged or closed, report what the kept ones still hold.
