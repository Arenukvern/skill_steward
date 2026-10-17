# Sources

| Topic | URL | Used for |
|-------|-----|----------|
| SkillOpt | https://microsoft.github.io/SkillOpt/ | Bounded edit + gate loop |
| SkillOpt paper | https://arxiv.org/abs/2605.23904 | Rollout/reflect/edit methodology |
| SkillsBench | https://arxiv.org/abs/2602.12670 | Paired eval inspiration |
| Claude skill best practices | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices | Human eval workflow |
| skills-best-practices | https://github.com/mgechev/skills-best-practices | skillgrade, disclosure |
| skillgrade | https://github.com/mgechev/skillgrade | Regression testing |
| Codex plugin-eval | ~/.codex/plugins/cache/openai-curated/plugin-eval/ | Static analyze + benchmark |
| Skill Steward validator | https://github.com/arenukvern/skill_steward/blob/main/packages/steward_cli/lib/src/commands/validate_command.dart | Layer 0 gate |
| Skill Steward eval runner | https://github.com/arenukvern/skill_steward/blob/main/packages/steward_cli/lib/src/commands/eval_command.dart | Layer 0b T1 behavior-critical |
| Chrome eval design | https://developer.chrome.com/docs/ai/evals/design | Failure modes, rubrics |
| Chrome evals course | https://developer.chrome.com/docs/ai/evals | Layered pipeline |
| ADR 0011 | https://github.com/arenukvern/skill_steward/blob/main/docs/decisions/0011-tiered-skill-evals-and-rule-based-ci.mdx | T1/T2 skill quality gate policy |
| ADR 0027 | https://github.com/arenukvern/skill_steward/blob/main/docs/decisions/0027-t-named-skill-quality-gates.mdx | Naming and new-tier creation rules |

| SkillsBench 1.1 (June 16, 2026) | https://www.skillsbench.ai/blogs/skillsbench-1-1 | Paired trials, invocation measurement, task-level regressions |
| ACES (August 20, 2026) | https://arxiv.org/abs/2608.20614 | Runtime skill effects separate from static quality |
| NVIDIA SkillEvaluator | https://docs.nvidia.com/skills/skillevaluator | Optional live-evaluation runner; experimental support and explicit runtime prerequisites |
| Agent evaluation reliability (September 30, 2026) | https://arxiv.org/abs/2610.00651 | Match claims to client/scaffold coverage |
| Measurement-first auditing (October 5, 2026) | https://arxiv.org/abs/2610.05830 | Validate scorers, preserve inconclusive results, distinguish leakage channels |
| Anthropic agent eval practice | https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents | Outcome graders, repeated trials, capability versus regression |
| SkillOpt implementation | https://github.com/microsoft/SkillOpt | Bounded edits and offline replay, not automatic adoption |
| Inspect AI logs | https://inspect.aisi.org.uk/eval-logs.html | Reusable transcripts, scoring, provenance rather than a new telemetry store |
| Harbor | https://docs.harborframework.com/ | Optional isolated execution and trajectory interoperability |
| agent-skill-eval | https://github.com/tardigrde/agent-skill-eval | Optional paired client runner and preflight; local compatibility unverified |
| Promptfoo assertions | https://www.promptfoo.dev/docs/configuration/expected-outputs/ | Optional deterministic prompt/output assertions |

| Official MCP conformance | https://github.com/modelcontextprotocol/conformance | Version/role/transport-specific protocol testing |
| MCP security practices | https://modelcontextprotocol.io/docs/2025-11-25/tutorials/security/security_best_practices | Runtime security boundaries beyond schemas |
| AgentDojo | https://github.com/ethz-spylab/agentdojo | Paired benign/injected tasks and unauthorized-effect measurement |
| OWASP Agentic Top 10 2026 | https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/ | Threat coverage, not certification |
| Executable-contract audit (September 29, 2026) | https://arxiv.org/abs/2609.37315 | State-effect and false-success controls |
| Injection detector evaluation (October 2, 2026) | https://arxiv.org/abs/2610.03448 | Local tool-output coverage and false-positive measurement |
| Terminal-Bench authors | https://www.tbench.ai/news/announcement-2-0 | Optional isolated terminal task pattern |
| Berkeley Function Calling Leaderboard | https://gorilla.cs.berkeley.edu/leaderboard.html | Optional tool-selection and argument cases; not effect proof |

## Changelog

- 2026-10-13: Primary-source review through this date; added paired dogfood methods and optional runner tradeoffs; corrected obsolete local JavaScript source links. Live docs are retrieval snapshots, not claims of October releases.

- 2026-05-29: v1.1 — Chrome eval reference, eval-case schema, T1 behavior-critical CI (`pnpm run eval`)
- 2026-05-29: initial (SkillOpt, plugin-eval, SkillsBench, skillgrade)
