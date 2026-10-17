# Sources

| Topic | URL | Used for |
|-------|-----|----------|
| Agent Skills spec | https://agentskills.io/ | SKILL.md format |
| Skill Steward STANDARDS | https://github.com/arenukvern/skill_steward/blob/main/docs/STANDARDS.mdx | Repo conventions |

| Official MCP conformance | https://github.com/modelcontextprotocol/conformance | Version/role/transport-specific protocol testing |
| MCP security practices | https://modelcontextprotocol.io/docs/2025-11-25/tutorials/security/security_best_practices | Runtime security boundaries beyond schemas |
| AgentDojo | https://github.com/ethz-spylab/agentdojo | Paired benign/injected tasks and unauthorized-effect measurement |
| OWASP Agentic Top 10 2026 | https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/ | Threat coverage, not certification |
| Executable-contract audit (September 29, 2026) | https://arxiv.org/abs/2609.37315 | State-effect and false-success controls |
| Injection detector evaluation (October 2, 2026) | https://arxiv.org/abs/2610.03448 | Local tool-output coverage and false-positive measurement |
| Terminal-Bench authors | https://www.tbench.ai/news/announcement-2-0 | Optional isolated terminal task pattern |
| Berkeley Function Calling Leaderboard | https://gorilla.cs.berkeley.edu/leaderboard.html | Optional tool-selection and argument cases; not effect proof |

| MCP server prompts | https://modelcontextprotocol.io/specification/2025-11-25/server/prompts | Explicit user-selected interpretation surface; checked 2026-10-13 |
| MCP stdio transport | https://modelcontextprotocol.io/specification/2025-11-25/basic/transports | Newline-delimited JSON-RPC; local tests are not conformance certification; checked 2026-10-13 |

## Changelog

- 2026-10-13: Added primary sources for protocol, effect, safety and purpose assurance; external suites not claimed as run locally.

- 2026-06-05: align routing language with merged governance skills and typed action candidates.
- 2026-05-31: update routing table for repo-brand-identity and governance skills.
- 2026-05-29: initial
