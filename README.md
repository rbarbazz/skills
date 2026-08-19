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
