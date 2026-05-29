# Y-Statement format

Source: [adr.github.io — Y-Statement](https://adr.github.io/) · Sustainable Architectural Decisions (Zdun et al.)

Use for compact entries in an index, changelog, or when the team wants a single-sentence decision record.

## Short form

```text
In the context of {situation},
facing {concern}
we decided for {option}
to achieve {quality},
accepting {downside}.
```

## Long form (adds neglected option and rationale)

```text
In the context of {situation},
facing {concern},
we decided for {option} and neglected {alternative}
to achieve {quality},
accepting {downside},
because {rationale}.
```

## When to use

- Supplement a full MADR ADR with a summary line in `README.md`
- Lightweight decision log without per-file MADR bodies
- Not a replacement for trade-off analysis on high-impact decisions — prefer MADR for those
