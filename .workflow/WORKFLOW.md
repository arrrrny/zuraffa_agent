# zuraffa_agent — Spec-Driven Delivery Workflow

One chain per spec, six specs total, fully automated end-to-end:

```
spec → plan → tasks → implement → test → review → patch → test → merge
 │      │       │        │         │       │        │       │      │
 draft  design  checkbox code+tests green  verdict  fixes   green   PR
 spec   doc     tasks    written   gates   +findings apply   again  opened
```

## Stage gates (a stage advances only when its gate passes)

| Stage | Executor | Gate |
|---|---|---|
| spec | `kimi -p` speckit-specify | `specs/<slug>/spec.md` exists, no template placeholders |
| plan | `kimi -p` speckit-plan | `plan.md` exists, no placeholders |
| tasks | `kimi -p` speckit-tasks | `tasks.md` has checkbox tasks covering spec requirements |
| implement | `kimi -p` speckit-implement | all tasks checked `[x]` |
| test | `kimi -p` verification | `dart analyze --fatal-infos` clean + `dart test` green |
| review | `kimi -p` **/coderabbit skill** — opens the draft PR, then produces a CodeRabbit-style review (walkthrough + changes table + effort estimate, pre-merge checks, inline findings with category/severity/effort badges and suggestion blocks, posted to the PR via GitHub MCP) | `review.md` mirrors the findings and ends with `VERDICT: APPROVE`; PR carries the posted review |
| patch | `kimi -p` fixer | no CRITICAL/MAJOR left unaddressed; fixes pushed to the PR branch |
| test (2nd) | same gate | green again after patches |
| merge | `kimi -p` finisher | PR open (non-draft), body carries spec link + verdict + test summary — NOT auto-merged |

State lives in `.workflow/state/<slug>/` — stage logs, `stages.done`, `review.md`, `test-notes.md`.
Resume anytime: `./scripts/pipeline.sh <slug> --from <stage>` skips completed stages.

## Spec → issue mapping (tracking stays on GitHub)

| Spec | Epic R# | Issue |
|---|---|---|
| `001-engine-core-loop` | R1 | arrrrny/zuraffa_agent#2 |
| `002-state-and-sessions` | R2 | #3 |
| `003-tools-and-mcp` | R3 | #4 |
| `004-providers-and-fallback` | R4 | #5 |
| `005-subagents-and-declarative` | R5 | #6 |
| `006-eval-harness-golden` | R6 | #7 |

## Dependency order (bootstrap driver)

```
002 (types/seed) ──► 001 (loop) ──► 003 (tools/MCP) ──► 004 (providers) ──► 005 (sub-agents/specs)
                                                                           006 (evals; needs 001+003)
```

`./scripts/bootstrap.sh` runs pipelines in this order. 004 can start after 001 in parallel;
006 after 001+003. CI (`.github/workflows/pipeline.yml`) triggers the same driver per-PR.

## Rules

1. **No stage skipping** — a failed gate halts the chain; state is resumable, never bypassed.
2. **PRs are never auto-merged** — merge happens after CI green + human approval. The draft PR opens at the review stage (the coderabbit skill needs a PR to review); the merge stage only finalizes it.
3. **Spec is the contract** — the CodeRabbit-style review checks implementation against spec.md, not vibes.
4. **Ports carry attribution** — dart_agent_core/pi-derived code keeps MIT attribution headers (review gate).
5. **Runtime purity** — no dart:io in engine runtime paths (test gate + review gate).
6. **Review is CodeRabbit-style** — via the `coderabbit` user skill + GitHub MCP; findings mirror into `.workflow/state/<slug>/review.md` (severity-tagged, `VERDICT:` line) so the patch stage and gates stay local-machine-readable. On runners without the skill/GitHub MCP (bare CI), the stage falls back to the identical analysis inline on the branch diff — same format, same gate.
7. **Preflight before every real run** — the driver validates the executor contract first (kimi present + one cheap headless round-trip proving flags/auth/non-interactive mode, dart, gh). Executor invocations must come from validated flags only; if the kimi CLI contract changes, preflight fails before any stage burns a run. `--skip-preflight` exists for explicit opt-out only.

## zfa-CLI-only mandate (constitution I, enforced 2026-08-18)

The first run of 001-state-and-sessions was hand-implemented (speckit-only) — a constitution violation kept as `reference/001-manual-port`. All real runs from now on:
- **implement stage**: zfa CLI only (`zfa initialize`, `zfa entity create`, `zfa make`, `zfa build`, `zfa mock data`); tests/scaffolding generated automatically.
- **First zfa misfire halts everything**: `.workflow/state/<spec>/misfire.md` (command, expected, actual, repro) → driver exits → escalate to zuraffa upstream → wait (constitution III).
- **gate_impl** additionally requires `.zfa.json` + at least one `*.zorphy.dart` under lib/.
