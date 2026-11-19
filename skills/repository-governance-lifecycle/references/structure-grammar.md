# Structure grammar — the shape of a G1 layer

**Canonical:** this file (`repository-governance-lifecycle/references/structure-grammar.md`) · portable mirror: the owner's `generational-architecture` skill
**Parent pattern:** [Evolutionary simplicity](evolutionary-simplicity.md) · **When to apply:** [Generational architecture ladder](generational-architecture-ladder.md)
**Source:** ["Flutter app AI-centric architecture for small startups"](https://github.com/Arenukvern/articles/blob/main/articles/2025_feb_flutter_app_architecture/en.md) (Feb 2025), proven in two repository structure cleanups (an ECS simulation game, an AI product, Nov 2026)
**Status:** concept reference for installed skills

The structure grammar is the shape of a **G1 layer** — the smallest useful visible repo grammar a repository promotes to when people and agents repeatedly ask where truth lives. The ladder decides *when* and *how much*; this grammar is *what the layer contains*.

It is written as patterns: the **mechanisms** are the law, the **names** are the article's Flutter instantiation — translate names, keep mechanisms. One deliberate exception: prefixes themselves are a mechanism, not a name style.

## Why prefixes are the mechanism, not decoration

Give every layer family a short role prefix (`data_*`, `ui_*`) and every domain a short domain prefix (`city_*`, `payments_*`). The prefix is what buys three things, and everything else follows from them:

1. **Explore** — the folder list alone reads as the architecture. A reader (human or agent) sees the layer stack, where domains begin and end, and which folders are shared facilities. "Where does this go" becomes a table lookup, not a judgment call.
2. **Extract and scale** — everything belonging to a layer or a domain is enumerable by its prefix. Moving a layer into a package is a mechanical glob, not an audit. Extraction cost is what prefixes exist to keep near zero.
3. **See violations** — because the family is visible in every path, import direction is checkable by grep or in review — without lint machinery.

Without prefixes the same information exists only in people's heads, extraction turns into archaeology, and the nearest unprefixed folder becomes the default home of every new subsystem (the mega-folder failure: one folder grew past a hundred files exactly this way).

Prefix *spellings* are translatable; the three payoffs are not. A naming convention that does not make layers enumerable and domains glob-able is decoration, not grammar — that is the test of whether a repo's prefixes are earning their place.

## Vertical axis — layer families

| Family | Function (what belongs) | Default prefix | In other stacks |
|--------|------------------------|----------------|-----------------|
| **Source** | Folders that serve data, named after the project's actual sources — a local runtime, remote clients, or both. Never a facade for one another; composition belongs to the optional repository member | `data_` | `adapters/`, `clients/`, `stores/`, `gateways/` |
| **Kit** | Shared vocabulary components; a standalone library with zero business rules | `ui_kit` | `components/`, `design_system/` |
| **Composition** | Bootstrap, assembly, registration; the manifest lives here | `di/`, `ui_root/` | `bootstrap/`, composition root, app wiring |
| **Interface** | Experience domains (app archetypes) | `ui_` | `features/`, `screens/`, `modules/` |

Members of the source family: `{domain}_models` (domain-specific models), `api_dto` (transfer objects, preferably generated), `data_repositories` (optional composition of local + remote), `data_states` (optional global runtime state usable by all domains — **absent when the runtime already provides it**: ECS resources + components, a service's own runtime, a package's private `src/`).

Root files are part of the taxonomy, not leftovers: envs, router, the app entry point, an optional common-imports barrel.

## Horizontal axis — anatomy of a domain

A domain is the self-describing unit:

- **One registration row in the manifest** — wherever domains are wired together: a systems/plugin register in a game, a route table or DI modules in an app, a handler table in a service, the public export barrel in a package.
- Inside: **flows → screens → features** (flow = screens in one user direction; feature = single-purpose capability; screen = the layout where features are placed).

Two boundary rules:

- **Domain or facility?** A domain has a manifest row and a domain prefix; shared infrastructure beneath the manifest stays *unprefixed* on purpose (`persistence/`, `camera/`, `content/`). The absence of a prefix is what marks it as not-a-domain. Don't prefix facilities; don't let domains lose their prefix.
- **Flow too big?** Promote it to a domain (move it up a level) or split it into several flows — never let it remain a deeply nested semi-domain.

**Knowledge files are a rare adjacency, default none.** Most domains need no markdown at all. The canonical owner for explanations is the contract file (plus decision records / FAQ where the repo has them — see the [doc lattice](https://docs.page/arenukvern/skill_steward/core/doc-lattice)); behavior truth is code, schemas and tests, and docs link inward instead of paraphrasing. Write a per-domain `{DOMAIN}_KNOWLEDGE.md` only when a domain holds non-derivable knowledge (invariants, external constraints, hard-won "why"), keep it small and name-aligned with the folder so one search finds it. A file that paraphrases code, tests or the manifest is pollution.

## The laws

One line each; every violation should be greppable in any stack:

1. **Prefix the families and the domains** — the tree self-describes, a layer is a glob, direction is visible in every import.
2. **Names carry direction** — interface imports nothing above its layer except through composition/manifest; source imports no interface.
3. **Placement is a lookup** — the contract file holds the decision table; no placement judgment calls.
4. **Birth law** — new domain = new folder + one manifest row. If a feature needs three unrelated touches, the birth law is missing or stale. A knowledge file is a rare adjacency, not a birth requirement.
5. **One public door** — each folder exposes itself through its barrel/index/public module; internal moves stay invisible to callers.
6. **Data does not cross domains** — reuse interfaces/widgets/flows; shared data moves to the source family.
7. **Contract file wins** — one ARCHITECTURE.md/STRUCTURE.md holds the map and the laws; other docs describe intent, it describes the tree; changed in the same commit that moves folders.

Maintenance set: state placement evolves with the runtime; file size is a seam question (~1k lines); close or formally supersede every migration; retire legacy behind a one-way door (count entry edges first; user data needs an explicit, visible migration; never delete storage on open); keep the grammar alive (PENDING markers, a do-not-resurrect list, falsifiers, gates only for mechanical laws).

## Entering a repo — detection before prescription

Answer from the repo, not from this page:

1. Where do imports point today? (the de facto vertical axis)
2. What serves data, and where does it live?
3. What is the shared vocabulary (kit), and is it actually standalone?
4. Where is assembly/registration — one place or scattered?
5. Which units do people and agents repeatedly need context for?

Then apply the ladder: **no grammar at all** → write the contract from the de facto laws first, before any physical move. **Grammar exists but drifted** → fix doc-ahead-of-tree with PENDING markers. **Grammar + repeated mechanical violations** → gate. Never gates first; never a doctrine transplant.

## Archetype map

The same families survive the archetype question ("what serves data?" changes shape, the layers do not):

```
Game (simulation / ECS)
  data_*           = named after the real sources; a local simulation has one
                     source - the ECS world - so data_local_api: systems are
                     the business logic, components the schema, actions the
                     use cases; a networked game adds data_remote_api
  data_states      = absent: resources + components are the state layer
  ui_{domain}      = ui_city, ui_players, ui_debug (debug panels are a domain too)
  manifest         = the systems/plugin register; one row per domain
  contract         = ARCHITECTURE.md wins; tests carry the mechanical laws

Service (backend / daemon)
  data_*           = named after the actual sources: local queue/cache/job
                     runtime, generated DB clients, upstream/third-party APIs
  ui_{domain}      = admin console / dashboard domains
  manifest         = route/handler table or DI module list
  contract         = ARCHITECTURE.md + a runbook link

Package (library)
  data_*           = the engine/store behind the public API
  data_states      = absent: internal state stays private inside src/
  ui_{domain}      = examples, demo gallery, docs site as "domains"
  manifest         = the public export barrel + changelog
  contract         = README + CONTRIBUTING is the contract

App (product)
  data_local_api   = local database, files, preferences
  data_remote_api  = generated API clients from backend schemas
  data_states      = notifiers/controllers/blocs usable by all domains
  ui_{domain}      = the product experience domains
  manifest         = router table / surface registry
  contract         = ARCHITECTURE.md wins
```

A repository can be several archetypes at once (an app with an embedded game, a package with a demo app). Pick the dominant one for the folder map; the secondary appears as domains. Knowledge files are rare adjacencies in every archetype — default none. The map is a reading aid for detecting what a repo already is — not a template to impose.

## Anti-patterns

- **Doctrine transplant** — imposing this page's example names on a repo whose de facto grammar differs. Detect first, translate always.
- **Prefix cargo** — prefixes without the payoffs (a `data_` folder that interface code imports freely is decoration).
- **Mega-folder gravity** — the nearest unprefixed folder becomes the default home of new subsystems; the symptom of a missing birth law.
- **Adjacency sprawl** — a markdown file beside every folder "for context". Md files accumulate, paraphrase behavior truth, and become a second codebase to maintain.
- **Doc-ahead-of-tree** — the contract describes moves not yet applied; fix with PENDING markers, not silence.
- **Gates-first** — lint machinery for laws nobody has written down.

## Falsifiers

- Humans/agents still ask "where does X go" after the contract lands → the decision table is incomplete; extend the table, don't re-explain in chat.
- A knowledge file nobody opens within a month → delete it (it was paraphrase or an orphan); the contract stays the canonical owner.
- An md file appears beside every folder → adjacency sprawl; consolidate into the contract before the tree becomes a second codebase.
- Extracting a family cannot be done by globbing its prefix → the prefixes have drifted; fix names before moving code.
- The contract is stale for more than a release cycle → the grammar is not maintained by habit; promote the mechanical laws to gates.

Provenance: from the February 2025 article and the November 2026 structure cleanups; composed as the G1-content companion to the ladder. Per-folder knowledge files demoted from default to rare adjacency (owner correction, Nov 2026: markdown pollution; behavior SSOT is code and schemas — docs link inward).
