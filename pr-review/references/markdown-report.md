# Markdown report

The report shape when the `Artifact` tool is absent (a terminal session). One message, in the user's reply style (the global CLAUDE.md communication rules). Headings and item shapes stay as written, so the same report reads the same way every run. Lists only: a list wraps in a narrow terminal where a table scrolls sideways.

```markdown
## <🔴 Blocked | 🟠 Fix first | ✅ Mergeable> · <one sentence: what changes for the product once this ships>

1. `<entry point>`
   🔴 L<n> Bug: <what breaks, with the concrete input>. Fix: <what to do>.
2. `<core logic>`
   🟠 L<n> Spec: <what the spec asked for, quoted, and what the diff does instead>.
3. `<tests>`

Mechanical: <renames, snapshots, lockfiles, one line>.
+<n> findings dropped: PR too big for a useful review.
```

One item per file, in reading order, the path alone. A file that carries a finding but no place in the reading order still gets an item, after the reading-order files. Findings sit under their file, 🔴 first, one sentence each naming the source (Bug, Spec, Cleanup) and line, Fix kept short or left out when obvious. The "+n dropped" line appears only when the cap in step 3 cut findings.
