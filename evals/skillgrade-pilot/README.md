# Bounded Skillgrade pilot

These are **development fixtures from real Steward work**, not unseen acceptance
cases or an official external benchmark. `eval.yaml` uses JSON-compatible YAML.
`skillgrade@0.5.0` is optional tooling; it is not a repository runtime dependency.

Tasks: repair the original validate-on-save hook; assess the actual native hook
control without upgrading it into agent/H4 evidence. The second fixture includes
an untrusted instruction and a protected maturity marker. The hook oracle is
owned by the existing plugin regression test. The agent receives a public copy
of that native development check and the hook fixture; the protected
grader uses its own independent copy. This is a development pilot, not a hidden
acceptance benchmark. Do not modify an oracle to make a
candidate pass. Freeze fixture, grader, skill, client and model hashes before a
new comparison. The October 13 rerun completed real Codex pairs and a bounded
ZCode cohort; see `results/2026-10-13-rerun.json` and
`docs/evidence/archive/skillgrade-pilot-2026-10-13.mdx`. The original blocked setup
result remains in `results/2026-10-13.json`; do not pool those cohorts.

## Run after client preflight

1. Choose an isolated client command that accepts the prompt on stdin. Prove it
   can read and edit a disposable fixture and that known global/plugin/canonical
   skill copies are inaccessible. Also check inherited AGENTS/memory/config.
   A successful text reply is insufficient. Do not change global installations.
2. Keep the grader **outside** the agent-readable/writable workspace. Check that
   the adapter denies grader access and the source checkout but permits the
   legitimate task. Enforce the declared process-tree timeout in the adapter;
   a runner promise timeout alone is insufficient cancellation.
3. Set `STEWARD_PILOT_ROOT` to this directory and `STEWARD_PILOT_COMMAND` to the
   preflighted adapter command. From this directory run:

   ```sh
   npx --yes skillgrade@0.5.0 --provider=local --agent=command --trials=1 --parallel=1 --format=json --output=/absolute/path/to/run
   ```

4. For the candidate, copy this eval directory into a separate run directory and
   add frozen copies of `repo-quality-system-lifecycle` and `skill-eval-improve`
   under its `skills/`. Keep `STEWARD_PILOT_ROOT` pointing at the protected oracle.
   Skillgrade discovers that bundle; baseline has no `skills/` directory.
5. Alternate arms B/C, C/B, B/C with fresh workspaces, same explicit model,
   permissions, prompt, budget and grader. Preserve discovery separately from
   forced-invocation experiments. First verify actual candidate discovery/read.
6. Export observations to the existing paired comparator. Inspect raw agent
   output for infrastructure errors even when Skillgrade emits score zero.
   Preserve skipped candidates as not run; never invent missing duration/cost.

The command adapter reports two outer commands (prompt staging and launch), not
agent tool calls. Its estimated tokens are not provider usage. Prefer client
usage events, retain cached-token accounting, and leave unknown cost null.
Run sequentially: version 0.5.0's local command adapter shares `/tmp/.prompt.md`.
Never run hostile fixtures against an unrestricted local client.

## Qualified local adapters

`isolated_client.py` supports macOS Codex and the installed ZCode app. Both use
native authentication; the adapter never reads or copies credentials. It denies
known global skill copies, global instructions/memory, the source checkout and
the staged grader. Codex runs under the outer sandbox so it does not attempt an
unsupported nested sandbox. Client runtime writes remain available; auth,
configuration and installed skills remain protected. This is targeted skill and
grader isolation, not a general hostile-workload container.

Set `STEWARD_PILOT_ROOT` to this directory and `STEWARD_PILOT_ARTIFACTS` to a new
receipt directory inside the checkout's `.dart_tool/`. The command is:

```sh
export STEWARD_PILOT_COMMAND="python3 \"$STEWARD_PILOT_ROOT/isolated_client.py\" codex"
```

For ZCode, change the final argument to `zcode`. Also set
`STEWARD_PILOT_ZCODE_STORAGE` to a dedicated, prewarmed directory outside the
checkout. Its native `ZCODE_STORAGE_DIR` setting redirects plugin bootstrap;
`ZCODE_DATA_BASE_DIR` alone does not. Prewarm using the bundled CLI's `skills list`
with `ZCODE_STORAGE_DIR` set to that directory and
`ZCODE_BUILTIN_PROVIDER_CONFIG_FILE` pointing at
`/Applications/ZCode.app/Contents/Resources/config/provider/zcode-builtin.json`.
The evaluated client gets a fresh session database per trial, disabled external
MCP/plugins/memory, and the existing native provider configuration by path.
Check the resolved model in each receipt; this ZCode CLI has no documented
per-prompt model override, so stop if the selected model drifts.

Set `STEWARD_PILOT_CATALOG_PREFLIGHT=1` for the initial baseline/candidate
qualification. Subsequent same-configuration trials reuse that qualification;
recheck after changing the skill bundle, client, or configuration. The client
still performs its normal discovery each run. Avoid a second catalog process
on every trial. Log collection starts at the launch cursor and keeps only the
new session's selected telemetry fields, rather than rescanning all daily logs.

The client deadline is 240 seconds. The outer Skillgrade timeout is 330 seconds
to include catalog preflight, cancellation and receipt collection. A shorter
outer deadline can delete the workspace before the client receipt is saved.
All timeouts and setup attempts remain evidence; they are not silently retried.

Use separate output directories and alternating arms. Stock Skillgrade 0.5.0
uses a shared `/tmp/.prompt.md`; do not launch concurrent stock runners. The
October rerun used a separately hashed copy for ZCode with a distinct prompt
filename, while each client remained sequential. That patch is recorded with
the local receipts; it is not an upstream release or a required new dependency.

The corrected pilot, prior setup failures and post-edit routing probes are
separate cohorts in the [evidence report](../../docs/evidence/archive/skillgrade-pilot-2026-10-13.mdx).
A routing probe is a development check, not a replacement for the frozen paired
cohort or a new acceptance claim. Paid runs remain opt-in, outside ordinary CI.

The tracked hook fixture is executable. Skillgrade 0.5.0 applies YAML `chmod`
through Dockerfile generation, not its local provider; local runs must preserve
the source file mode before copying. The recorded corrected cohort used Bash
explicitly and did not rely on the YAML mode setting.
