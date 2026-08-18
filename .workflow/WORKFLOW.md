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
| review | `kimi -p` strict reviewer | `review.md` ends with `VERDICT: APPROVE` |
| patch | `kimi -p` fixer | no CRITICAL/MAJOR left unaddressed |
| test (2nd) | same gate | green again after patches |
| merge | `kimi -p` finisher | branch committed, pushed, PR opened (NOT auto-merged — CI + human) |

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
2. **PRs are never auto-merged** — merge happens after CI green + human approval.
3. **Spec is the contract** — review stage checks implementation against spec.md, not vibes.
4. **Ports carry attribution** — dart_agent_core/pi-derived code keeps MIT attribution headers (review gate).
5. **Runtime purity** — no dart:io in engine runtime paths (test gate + review gate).
