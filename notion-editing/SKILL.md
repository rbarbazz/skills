---
name: notion-editing
description: Keep comment anchors intact when editing Notion. Use before editing or updating any existing Notion page.
---

# Notion page edits

When editing a Notion page where the target text carries a comment anchor (a
`<span discussion-urls="discussion://...">` wrapper in the fetched markdown),
always carry the span reference into the new text so the comment stays anchored.

- Fetch the page first and copy the exact `<span discussion-urls="...">`
  wrapper from the old text, and wrap the corresponding part of `new_str` in it.
- Keep `old_str` fully inside or fully outside a span, never crossing its
  boundary: boundary-crossing matches fail silently (tool reports success, edit
  not applied).
- Re-fetch the page after every update batch to verify all edits landed and no
  comment thread got orphaned.
