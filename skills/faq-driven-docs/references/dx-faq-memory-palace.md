# DX_FAQ — Memory Palace format

**Purpose:** **How** to use the API with high recall for agents and developers.

## Structure

```markdown
# {Project} DX_FAQ - Memory Palace

_Spatial organization for recall. Walk locations in order or jump by emoji._

## 🏠 World Hub

\`\`\`dart
CREATE: ...
QUERY: ...
\`\`\`

## 🏭 Entity Factory

\`\`\`dart
...
\`\`\`
```

## Location naming

- Emoji + 2–4 word label (🏠 World Hub, 🔍 Query Station)
- Under each location: terse labels + fenced code (language tagged)
- No prose paragraphs between blocks unless one line of warning

## When Memory Palace is worth it

| API size | Format |
|----------|--------|
| Small (&lt;10 entry points) | Simple Q&A like DESIGN_FAQ is OK |
| Medium / large | Memory Palace recommended |
| Reference-only generated API | Link to generated docs; DX_FAQ only for patterns |

## Decision matrix inside a location (optional)

```markdown
## 🧭 Choose query API

| Need | Use |
|------|-----|
| Single component | `queryExt<...>()` |
| Two components | `queryExt2<...>()` |
```
