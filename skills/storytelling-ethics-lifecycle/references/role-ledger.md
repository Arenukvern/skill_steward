# Role ledger

Single vocabulary for public storytelling. Do not invent synonyms in the story body.

| Role | Who acts | Public meaning | Must not be called |
|------|----------|----------------|--------------------|
| `authored` | Named human | These words are that person's own writing | "co-written by AI" unless a model also drafted |
| `drafted` | Named model | First text produced from sources and a brief | `authored` |
| `curated` | Named human | Reviewed, corrected, accepted, or refused the draft | silent; "lightly edited" that hides invention |
| `generated` | Named model or tool | A published artifact (prose, image, code, audio) produced by a generator | "stock", "original photo", `authored` |
| `transcribed` | Recorder | Existing speech or text captured without new claims | `authored` |
| `quoted` | Original speaker/writer | Their words, attributed, in context | paraphrased as the storyteller's insight |
| `refused` | Named human or gate | Asked for and not done, or withdrawn | omitted as if it never happened when the refusal matters |
| `unknown` | Nobody can honestly say | Gap is visible | guessed role |

## Rules

1. One artifact, one primary role. A second role is allowed only as a pair: `drafted` + `curated`.
2. Style transfer ("in the style of X") is never `authored` by X. It is `drafted` by the model, `curated` by the person who asked.
3. A locked product decision is not a model role. Record the human as the lock; the model may have drafted the ADR text.
4. `unknown` is more honest than a polite guess.
5. Update the ledger in the same change as the story.

## Minimum rows

- The story text itself
- Cover or figures
- Any substantial quoted conversation
- Any code or config presented as "what we built"

## Example

| Artifact | Role | Who | Notes |
|----------|------|-----|-------|
| Article body | drafted + curated | Grok drafted; Anton curated | Style of Anton's DEV posts, by request |
| Cover still-life | generated | Imagine / Grok | No readable text; not a photograph of a real event |
| Scaffold share | quoted | Public Grok share | Linked, not pasted in full |
| ADR 0003 change | authored (decision) | Anton, after argument | Story reports; ADR remains SSOT |
