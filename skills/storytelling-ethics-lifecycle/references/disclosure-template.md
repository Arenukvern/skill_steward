# Disclosure template

Copy into the story. Keep it short. Fill every field or delete the field with a reason.

```markdown
## Disclosure

- **What this is:** {story of how/why the work was made — not product SSOT}
- **Drafted by:** {model or "not drafted by a model"}
- **Curated by:** {named human, or "not yet curated"}
- **Authored by:** {named human for sections they wrote themselves, or "none"}
- **Generated artifacts:** {images, audio, diagrams — or "none"}
- **Sources:** {public conversations, ADRs, articles, interviews — links}
- **Style:** {e.g. "drafted in the style of X's articles, by X's request"}
- **Not a claim:** {one sentence the story refuses}
```

Place this **before** the narrative when the story will be read as a personal essay. Place it **after** only when the host forbids a preamble; then add one sentence at the top: "Authorship and generation notes are at the end."

## Platform notes

- **DEV / blog:** keep the block in the body. Frontmatter `canonical_url` does not replace it.
- **Talk:** say the drafted/curated line out loud in the first minute.
- **Repo README:** one sentence + link to the full story and its disclosure.
- **Video or image:** if a technical credential exists (for example C2PA Content Credentials), use it *in addition to* this human-readable block. A label in metadata is not a substitute for a sentence a reader can see.

## Edit rule

If any role in the [ledger](role-ledger.md) changes, change this block in the same commit or publish.
