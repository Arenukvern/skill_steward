---
name: missing-description
---

# Missing Description

This frontmatter block intentionally omits the required `description` field.

The validator must report an error for the missing description (while name validation still runs because parse succeeded).

Body content here is sufficient length to avoid the short-body warning.