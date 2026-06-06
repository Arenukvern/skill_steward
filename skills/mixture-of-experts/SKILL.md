---
name: mixture-of-experts
description: Run a Mixture of Experts (MoE) audit on any topic, plan, codebase, or process. Dynamically spawns specialized subagents with different critical lenses to cross-reference findings and detect flaws, overlap, or drift. Use when designing architectures, analyzing complex code, verifying multi-step plans, or looking for duplicated intent in a repo.
license: MIT
type: governance
metadata:
  author: skill-steward
  version: "1.1.0"
  category: governance
---

# Mixture of Experts (MoE) Audit

The Mixture of Experts pattern is a powerful critical-thinking framework. It prevents tunnel vision by forcing multiple independent "expert personas" to analyze a single topic from completely different angles, before cross-referencing their findings.

It can be applied to literally anything: a codebase, a feature plan, a deployment process, or a repository's governance skills.

## When to use

- "Review this architecture plan using a mixture of experts"
- "Do we have skills with duplicated intent?"
- "Audit this deployment script for security and performance"
- You encounter a complex design decision and need rigorous, multi-faceted critique.

## Workflow

1. **Identify the Topic**
   Understand what the user wants to audit (e.g. "repo skills overlap", "new caching architecture", "release process").
2. **Define Expert Personas**
   Invent 2-3 specialized experts whose lenses are highly relevant but orthogonal to the topic. For example:
   - *For repo governance:* "Codebase Auditor", "Skills Analyst"
   - *For a system architecture:* "Security Specialist", "Scalability Engineer", "Cost Analyst"
   - *For a frontend component:* "Accessibility Auditor", "Performance Expert"
   - *For E2E Execution & Evals (Dogfooding):* **"Harness QA Expert"**. Any time a workflow, toolchain, typed action, or benchmark loop is updated, you MUST spawn a Harness QA Expert subagent. Its job is to simulate a user/agent experiencing the system in a real repository (e.g. discovering actions, triggering skill evals, or checking MCP/CLI parity without relying on raw shell pipelines).
3. **Spawn Subagents**
   Use the available subagent capability for the current host (for example Codex `spawn_agent`) to launch these experts independently. Give them explicit prompts to audit the target topic through their specific lens. If no subagent tool is available, run the expert lenses sequentially and label the output as a non-parallel MoE.
4. **Cross-reference Findings**
   Wait for all subagents to report back. Synthesize their independent critiques. Look for structural contradictions, missed edge cases, or (in the case of repo skills) duplicated intent.
5. **Choose output mode**
   - **Read-only critique mode:** If the user asks to analyze, discuss, criticize, or validate only, summarize findings in chat. Do not create files or plans.
   - **Implementation planning mode:** If the user asks for a plan or approved changes, draft a concise implementation plan or learning artifact.
   - **Execution mode:** If the user explicitly approves implementation, apply the smallest scoped changes and validate them.
6. **Present to User**
   Lead with critical findings, contradictions, and actionable recommendations. Ask for approval only when the next step would mutate files or widen scope.

## Install

```bash
npx skills add arenukvern/skill_steward --skill mixture-of-experts
```

## Sources

See [references/sources.md](references/sources.md).
