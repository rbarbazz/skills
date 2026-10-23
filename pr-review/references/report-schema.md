# Review data

The JSON that fills the `__REVIEW_DATA__` placeholder in `assets/report.html`. The page renders it: verdict first, then one collapsible section per file in reading order, findings under each.

## Shape

```json
{
  "pr": { "repo": "owner/name", "number": 482, "title": "PR title", "url": "https://github.com/owner/name/pull/482" },
  "verdict": "blocked | fix | mergeable",
  "story": "One sentence: what changes for the product once this ships.",
  "notes": ["Optional lines shown under the verdict: local branch ahead of the PR, spec sources absent."],
  "files": [
    {
      "path": "src/billing/invoice.py",
      "role": "entry point | core logic | plumbing | tests | (empty when the file is only here for its findings)",
      "findings": [
        {
          "severity": "blocker | should",
          "line": 42,
          "source": "Bug | Spec | Cleanup",
          "text": "One sentence: what breaks with the concrete input, or what the spec asked for (quoted) and what the diff does instead.",
          "fix": "Optional. Short, left out when obvious."
        }
      ]
    }
  ],
  "mechanical": "Optional. Renames, snapshots, lockfiles, one line.",
  "dropped": 0
}
```

Rules the page relies on:

- `verdict` matches the worst severity: `blocked` with any `blocker`, `fix` with only `should`, `mergeable` with none.
- `files` is the reading order from step 2. A file with findings but no place in the order comes last with an empty `role`.
- Findings under a file are `blocker` first. At most 3 per file and 8 per PR; `dropped` counts the rest and is `0` when the cap did not cut.
- The JSON sits inside a `<script>` tag: write `<\/` for any `</` in a string, or the page breaks at that point.
- Plain text only in `text`, `fix`, `story`, `notes`: the page escapes nothing and renders no Markdown.

## Example

```json
{
  "pr": { "repo": "acme/billing", "number": 482, "title": "Charge VAT on EU invoices", "url": "https://github.com/acme/billing/pull/482" },
  "verdict": "blocked",
  "story": "EU customers get VAT added to their invoices, computed from the billing country at invoice time.",
  "notes": ["Spec sources past the PR body are absent: no Linear issue linked, no tech spec found."],
  "files": [
    {
      "path": "src/billing/invoice.py",
      "role": "entry point",
      "findings": [
        { "severity": "blocker", "line": 58, "source": "Bug", "text": "vat_rate() is called with customer.country, which is None for customers created before the country column existed, so invoice creation raises TypeError for every legacy customer.", "fix": "Fall back to the billing address country, and skip VAT when both are missing." }
      ]
    },
    {
      "path": "src/billing/vat.py",
      "role": "core logic",
      "findings": [
        { "severity": "should", "line": 21, "source": "Cleanup", "text": "The 27 rates are a dict literal in code; the PR body says they come from the finance team quarterly.", "fix": "Load them from a data file so finance can update them without a deploy." },
        { "severity": "should", "line": 34, "source": "Spec", "text": "The PR body says \"reverse charge for B2B customers with a VAT number\", the diff applies the full rate to every EU invoice." }
      ]
    },
    { "path": "tests/billing/test_vat.py", "role": "tests", "findings": [] }
  ],
  "mechanical": "Snapshot updates in tests/billing/__snapshots__, poetry.lock bump for pycountry.",
  "dropped": 0
}
```
