# Ethics as a Living Science and Stewardship Practice

Ethics in software development is not a static rulebook or a predefined set of compilation limits. It is a **living framework of constraints and stewardship** that must be discovered, defined, and refined for each specific project. 

This document guides AI agents and humans on how to work side-by-side to **elicit, translate, enforce, and audit** a project's unique ethical boundaries.

---

## 1. The Stewardship Workflow: Elicitation to Refinement

Rather than imposing external rules, agents and humans should collaboratively shepherd the codebase through a four-phase lifecycle:

```text
1. Elicit & Define ──► 2. Translate to Science ──► 3. Enforce as Practice ──► 4. Audit & Refine
```

---

## 2. Phase 1: Elicit & Define (Choosing the Core Values)

Ethical principles are highly context-dependent. A medical diagnostics application, a local offline game, and an open-source development tool have fundamentally different moral priorities. 

To help human teams define their ethics, agents should analyze the repository and initiate collaborative alignment loops:

### Elicitation Prompts (Agent to Human)
*   *“Looking at the design FAQ and the North Star, what is the single most critical promise we make to our end users? How does that translate to code requirements?”*
*   *“Where do we experience the most developer friction or technical debt? What implicit value are we violating that causes this friction?”*
*   *“What form of AI collaboration makes us feel most in control of our craft, and where do we feel AI takes away our agency?”*

### Analyzing Implicit Values
Agents should look for existing patterns in the codebase to extract undocumented ethical choices:
*   **Dependency Taste:** Does the project favor a tiny, zero-dependency footprint (valuing *simplicity/longevity*) or rapid library inclusion (valuing *speed/prototyping*)?
*   **Code Ownership:** Do commit logs show highly collaborative peer-review patterns (valuing *team cohesion/artisan credit*) or siloed, rapid pushes?
*   **Privacy Stance:** Is configuration kept purely local, or is there telemetry and cloud integration?

---

## 3. Phase 2: Scientific Translation (Virtues to Bounded Constraints)

Once values are identified, they must be translated into **context-appropriate technical boundaries**. Do not copy rules from other projects; instead, map abstract virtues to quantifiable system properties.

### The Translation Matrix (Framework)
Use this template to translate any newly defined ethical principle into architectural science:

1.  **Identify the Virtue:** Define the core value (e.g., *Self-Reliance*, *Inclusivity*, *Longevity*).
2.  **Define the System Proxy:** Identify which part of the codebase directly impacts this virtue (e.g., build times, network access, telemetry, file structures).
3.  **Establish the Limit:** Define a boundary that, when crossed, signals a violation of the virtue (e.g., "no remote requests during compilation," or "telemetry must be opt-in by default").

### Example Translations by Context
*   **Context A: An Offline-First App**
    *   *Virtue:* User Privacy.
    *   *Architectural Proxy:* Network I/O.
    *   *Constraint:* No network requests permitted in core business modules; telemetry must reside in a strictly decoupled, visible interface package.
*   **Context B: A High-Performance Developer Tool**
    *   *Virtue:* Simplicity and Speed.
    *   *Architectural Proxy:* Dependency Graph.
    *   *Constraint:* Pin all dependency versions; require a decision checkpoint (ADR) before adding any external packages.

---

## 4. Phase 3: Operational Enforcement (Building the Practice)

To turn ethics into practice, the chosen constraints must be **mechanically enforced** within the developer and agent environment. 

### Enforce via the Environment
*   **Remediable Gates:** Design validation commands, linters, or check-scripts that do not just raise errors, but explicitly teach the builder *why* the boundary matters and *how* to resolve the violation.
*   **Sandbox Configuration:** If the project values security or determinism, configure the agent's workspace permissions (e.g. read/write files, network access) to match those constraints, making the workspace itself a mechanical gate.
*   **Traceability Mapping:** Maintain a central reference (like `brand.md` or `references/sources.md`) where architectural constraints are linked directly to their originating design decision (ADR) or visual specification.

---

## 5. Phase 4: Audit & Refine (Handling Drift)

Ethics is not a fixed monument. As technology, teams, and user requirements evolve, the ethical framework must be audited and adjusted.

### The Refinement Loop
*   **Monitor Drift:** Periodically analyze if manual code changes or agent suggestions are consistently bypassing or conflicting with the documented constraints.
*   **Trigger Refinement Checkpoints:** If a constraint is frequently bypassed (e.g., a "no external libraries" rule is repeatedly circumvented because the standard library lacks a critical function), treat this not as a developer failure, but as a signal to refine the constraint.
*   **Document and Extract:** Use the plan-hygiene lifecycle. Discuss the boundary shift with the team, log the agreed changes in a new ADR, update the project's North Star, and adjust the validation gates to match the new reality.

---

## Conclusion

By treating ethics as a living, adaptable stewardship workflow, humans and agents can establish a shared moral compass. The role of the agent is to help discover the project's implicit values, enforce the chosen boundaries, and assist in refining them as the codebase grows.
