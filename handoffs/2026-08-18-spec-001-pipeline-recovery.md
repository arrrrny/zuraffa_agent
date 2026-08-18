# Handoff — 2026-08-18: Zuraffa_agent Spec-001 Pipeline + Tree-Loss Recovery

## Resume from

No prior handoff. This is the first. (Long goal-mode session: orchestrated the ZikZak AI agent-centric program across 10 repos, then ran the first spec pipeline end-to-end in `zuraffa_agent`.)

## 1. Session Gist

Two phases, same session: **(A)** Design/issue orchestration of "ZikZak AI" — agent-at-the-core rebuild across 10 GitHub repos (zuraffa, zuraffa_agent, zikzak_inappwebview, dart_web_scraper, dart_scraper_sandbox, raptorr, dws_playground, zik_zak, flutter-shadcn-ui, dart_agent_core-superseded), MAESTRO tracker `zik_zak#176`, Waves 0/E/Z/U. **(B)** Set up `arrrrny/zuraffa_agent` (new engine repo): spec-kit + kimi integration, 6 specs (R1–R6) from the epic, an automated 9-stage pipeline (`spec→plan→tasks→implement→test→review→patch→test→merge`), then **ran spec 001-state-and-sessions end-to-end**. That run is mid-flight with a branch tree-loss incident currently being recovered.

## 2. Current State — Where We Are

**Repo: `~/Developer/zuraffa_agent`** (clone of `arrrrny/zuraffa_agent`, branch `001-state-and-sessions`)
- **HEAD = `a26e44f`** — *"fix: address review findings #1-#4 in compaction.dart and hive_adapters.dart"* — this is **the correct, COMPLETE tree**: all 13 `lib/src` files (types, session, session_storage, session_storage_impl, hive_session_store, hive_adapters, compaction, tools, skills, prompt_templates, sse_parser, execution_env, usage_ledger), `lib/zuraffa_agent.dart` barrel, `pubspec.yaml` (hive_ce ^2.19.0, lints, test), `example/session_demo.dart`, full test suite + `test/fixtures/mission_50.jsonl`. It includes the patch stage's fixes for the 3 CodeRabbit Majors.
- **⚠️ WORKING TREE IS DIRTY WITH WRONG VERSIONS**: during recovery I ran `git checkout 002-state-and-sessions -- lib test example pubspec.yaml ...` which OVERWROTE `a26e44f`'s good (patched) files with `002-state-and-sessions` older versions → 29 analyzer errors appeared. **Fix = `git checkout -- lib test example pubspec.yaml analysis_options.yaml NOTICE`** (restore a26e44f's versions).
- Branch `002-state-and-sessions` (local+remote) = the implement lineage that got orphaned; its committed tree is OLDER than a26e44f (missing the patch fixes and final state). Keep as rescue copy; do not push it over.
- `origin` remote = `git@github.com:arrrrny/zuraffa_agent.git`. PR **#9** (draft, branch `001-state-and-sessions` → main): **currently head = 82a78cb** (older, tree was missing most lib files → CI `verify` failed). Needs `a26e44f` pushed to make it complete+patched.

**Pipeline state** (`.workflow/state/001-state-and-sessions/`):
- `stages.done` = `spec plan tasks implement test` (review GATE failed; patch had no `.done` entry)
- All stage logs preserved: spec/plan/tasks/implement/test/review logs.
- `review.md` — the CodeRabbit review (3 Major / 3 Minor) — **already POSTED to PR #9 as a comment** (12,792 chars, clean markdown).
- Driver: **stopped** (0 `pipeline.sh` processes). Last run killed during the tree-loss response.

**Other repos (orchestration only, untouched this session):** zik_zak (`docs/architecture/zikzak-ai-agent-architecture.md` §1–15 amended; MAESTRO `zik_zak#176` carries the full cross-repo graph, Waves 0/E/Z/U).

## 3. The Threads — What's In Flight

1. **Spec 001-state-and-sessions first end-to-end** — the core thread. Progress so far (all machines/agents): `spec ✓` (kimi finalized spec-002→renumbered 001), `plan ✓`+research/data-model/contracts/quickstart, `tasks ✓` (40 tasks; `specs/001-state-and-sessions/tasks.md` — check `- [x]` count for state), `implement ✓` (40/40, **249/249 tests green**, analyze clean, quickstart validated, NOTICE BSD-3), `test ✓` gate, **review: gate FAILED** (3 Majors → correct; gate regex also had a bug, fixed `82a78cb`), **patch: COMMITTED `a26e44f` fixing the 3 Majors**, then I stopped the pipeline to recover the tree.
   - **NEXT ACTION (immediate):** restore working tree to a26e44f (see §7 step 1) → `dart analyze` clean → `git push origin 001-state-and-sessions` (PR #9 becomes complete + patched) → CI `verify` should pass → then drive the **re-review** (see step 5) → **merge** PR #9 → then **post-merge verification** (`dart analyze` + `dart test` on `main`).
2. **Remaining specs of the bootstrapped program** — after 001 merges, run the rest via `./scripts/bootstrap.sh` (order: `001-state-and-sessions` → `002-engine-core-loop` → `003-tools-and-mcp` → `004-providers-and-fallback` → `005-subagents-and-declarative` → `006-eval-harness-golden`). Specs exist; only 001 has been run.
3. **MAESTRO program (zik_zak#176)** — 40+ issues across 10 repos, Waves 0/E/Z/U, plus the engine epic `zuraffa_agent#1` (R1–R6 = issues #2–#7) and Wave-U issues (flutter-shadcn-ui#4, zuraffa#391/#392, zuraffa_agent#8). Not actionable this session — records only.

## 4. Credentials & Access

- **GitHub**: `gh` CLI authed as **arrrrny** (keyring, no manual token needed). All 10 repos: `arrrrny/{zuraffa, zuraffa_agent, zikzak_inappwebview, dart_web_scraper, dart_scraper_sandbox, raptorr, dws_playground, zik_zak, flutter-shadcn-ui, dart_agent_core}`. Issue label: `zikzak-ai` on all.
- **Kimi Code CLI** (`kimi`, at `~/.kimi-code/bin/kimi`): authed; headless = `kimi -p "<prompt>"` (non-interactive, tools run without prompts). NOTE provider 5-hour rate-limit windows (429) — pipeline retries by parsing the reset timestamp.
- **Pi agent source**: `~/Developer/pi/pi_agent/` (BSD-3-Clause © ZikZai AI). Dart engine derives from it (sealed types, session tree, skills, SSE parser, etc.).
- No other secrets used this session.

## 5. GOTCHAS — Hard-Won Lessons (CRITICAL)

1. **The tree-loss incident (VERBATIM root cause + fix):** the review stage's kimi rebuilt the branch: reflog `a415b81 ✓checkout: moving from 002-state-and-sessions to 001-state-and-sessions` — the PR branch `001` was created from an OLD base and did NOT carry the implement lineage (e97ceb1/089a73c orphaned) → PR head had only ~2 `lib/src` files → `dart analyze` failed on undefined types → CI `verify` failed. Recovery: the green+patched tree exists at **`a26e44f`** (current HEAD; the patch stage committed before being stopped). **Restore it with `git checkout -- lib test example pubspec.yaml analysis_options.yaml NOTICE`; never `git checkout` from the orphaned `002-state-and-sessions` branch over it.**
2. **Bash cwd resets to `/Users/ahmettok/Developer/zik_zak` every call** — always `cd ~/Developer/zuraffa_agent` or `git -C`; a bare `git log` showed zik_zak's history and briefly caused a false "repo corrupted" scare.
3. **`nohup ... &` + `rm -f` in one line = backgrounding footgun** — `A && B &` backgrounds the pair; the redirect inode can get unlinked so `.workflow/last-run.log` intermittently vanishes (driver still runs fine; monitor via stage logs). Launch as: single `nohup ./scripts/pipeline.sh ... > .workflow/last-run.log 2>&1 < /dev/null &` with a prior separate `rm`.
4. **macOS has no `setsid`** — use plain `nohup ... &` (untracked background) so the task tracker can't kill the driver.
5. **`kimi --auto` / `--yolo` CANNOT combine with `-p`**; the only headless invocation is `kimi -p`. And there is NO `--allowedTools` flag (misfire #1).
6. **Preflight single-shot probe is flaky** — retry 3× with backoff + save evidence files (misfire #2).
7. **Provider rate-limit 429** — `run_stage` parses "reset at <ts>" from the stage log, sleeps until reset (+60 s, cap `KIMI_MAX_WAIT_SEC` default 8 h), retries (misfire #3).
8. **Stalled executor ≠ slow work** — kimi hung ~2 h at 0% CPU on a dead socket with no child dart processes; kill the executor → clean `stage FAILED` → resume `--from implement` via checkpoints (misfire #5; rule 9 in WORKFLOW.md).
9. **Gate vs agent self-verdict**: the test agent declared PASS while 2 warnings sat in a feature file it called "pre-existing" — the driver's own gate caught it (misfire #6). Now the test prompt mandates fixing ALL analyzer issues in feature-owned files.
10. **Gate regex vs markdown**: CodeRabbit writes `**VERDICT: APPROVE**` (bold) — the old `^VERDICT` anchor failed (misfire #7). Fixed: `gate_review` fails while any `^#### .*🟠 (Major|Critical)` finding remains, then requires an approve token (case/markdown-insensitive).
11. **PR body gobble**: review agent set the PR body as a JSON-escaped string with literal `\n` → GitHub renders them. Use `--body-file` with real newlines (review prompt now mandates this).
12. **Constitution** — `.specify/memory/constitution.md` (v1.1.0): **I. zfa-CLI-built only, II. stop on first misfire, III. escalate to zuraffa & wait, IV. postmortem-every-misfire (commit format: expected/happened/fix/prevention), V. gates non-negotiable (PRs never auto-merged), VI. probes must retain evidence, VII. engine purity (no dart:io in runtime), VIII. attributed ports, IX. Zorphy Is the Model Layer** (entities/enums/VOs via Zorphy; scoped exception for ported MIT/BSD-3 by decision — see `specs/001-state-and-sessions/research.md`).
13. **pi_agent license is BSD-3, not MIT** (corrected in NOTICE + review prompt).
14. **Gate loop design gap (known)**: `stages.done` records a stage as done even if its gate previously failed is NOT true — the loop's skip logic can skip the re-review; to re-review after a patch, force review re-run (clear `review.md` + treat `--from review`), because `review` was never appended to `stages.done` when its gate failed.

## 6. Tools & Conventions We Built

- **`scripts/pipeline.sh`** (driver) — usage: `./scripts/pipeline.sh <spec> [--from <stage>] [--to <stage>] [--dry-run] [--skip-preflight]`. Stages chained with gates; preflight (kimi/dart/gh + a cheap headless round-trip with retries); rate-limit retry; detached-launch via nohup; state in `.workflow/state/<spec>/`.
- **`scripts/bootstrap.sh`** — runs all six specs in dependency order (001→002→003→004→005→006).
- **`.workflow/WORKFLOW.md`** — the pipeline contract (stage gates table, rules 1–9, ordering note). READ IT.
- **`.specify/`** — spec-kit, kimi integration. `specify init . --integration kimi` created skills under `.kimi-code/skills/` and templates/scripts. **`.specify/*` is gitignored except `.specify/memory/constitution.md`.**
- **`specs/001-state-and-sessions/`** — spec.md, plan.md (with research/data-model/contracts/quickstart docs), tasks.md (40 tasks), checklists/. The 4 remaining specs under `specs/00[2-6]-*` are scaffolding (spec.md only).
- **PR comments / body**: always `--body-file <file>` with real newlines.
- Conventions: checkpoint-everything (per-task checkboxes, per-group commits, preserved logs) so a resume = `--from <stage>` never a restart.

## 7. What To Do Next (first concrete actions)

1. **Restore the good tree (do FIRST):** `cd ~/Developer/zuraffa_agent && git checkout -- lib test example pubspec.yaml analysis_options.yaml NOTICE && dart analyze` → expect **0 issues** (verifies the patch fixes compile).
2. **Push the complete patched tree to the PR:** `git push origin 001-state-and-sessions` (HEAD → a26e44f). Watch CI `verify` on PR #9 — it should now pass (`dart analyze` + `dart test`).
3. **Drive re-review → merge:** the CodeRabbit review (3 Majors) was already posted/committed-for. Options: (a) repoint review.md to reflect the a26e44f fixes + re-run the review gate manually, or (b) relaunch the pipeline `--from review` (its gate failed before, so it will re-run the review stage freshly against the patched diff, expect 0 Majors + approve). Then `merge` stage finalizes PR #9 (still NOT auto-merged — CI + human as the final gate per constitution V).
4. **Post-merge end-to-end verification (goal's completion criterion):** on `main`, run `dart analyze` + `dart test` (expect 249/249) and confirm PR #9 merged + issue #3 closed.
5. **Close the goal** only after (4) passes: verify merged code end-to-end with testing on main, and the misfire ledger (8 events + the tree-loss) recorded in the repo commit history.

## 8. Open Questions / Decisions Pending

- **Branch naming** is confusing post-renumber (the implement lineage branch is literally called `002-state-and-sessions`). Consider renaming that rescue branch to something like `rescue/implement-lineage-orphaned` to avoid future accidental checkouts over the PR branch.
- **Re-review loop driver semantics** (item 5.14): decide whether to make the pipeline force re-run the review stage after a successful patch (auto REQUEST_CHANGES loop) or keep the operator-driven `--from review` approach. Recommend operator-driven for now (constitution V).
- **Spec 001's constitution-IX tension** resolved as a scoped ported-code exception; confirm this stands when R2/R3 specs run (they may trigger it again).

## UPDATE (same session, post-handoff — READ THIS)

Recovery is EXECUTED and the tree is REPAIRED:
- Restored `lib/src/compaction.dart` + `lib/src/hive_adapters.dart` from the green baseline **`4425b57`** (the patch commit `a26e44f` had stripped the estimator entry points `estimateEntriesTokens`/`estimateContextTokens`/`shouldCompact` that `test/compaction_test.dart` calls → 29 analyzer errors; only the test file was broken).
- Fixed 2 unused-local warnings in `test/session_test.dart` (lines 78/115).
- **`dart analyze` = `No issues found!`** · full tests green (compaction+storage+session suites: 101 + 59 pass).
- Hardened the PATCH prompt in `scripts/pipeline.sh` (test-before-commit + analyze-clean before committing; never break API tests).
- Commit **`d731209`** pushed to `origin/001-state-and-sessions` → **PR #9 now carries the complete, analyze-clean tree** (was missing/broken → CI `verify` was failing).
- **No driver is running** (the `--from patch` relaunch was interrupted — verify before assuming anything). Goal is PAUSED; resume via `/goal resume`.
- CodeRabbit review (3 Major / 3 Minor) was already POSTED on PR #9 as a comment (12,792 chars, clean markdown). The 3 Majors still need the patch stage to fix them on this now-green baseline ⇒ relaunch `./scripts/pipeline.sh 001-state-and-sessions --from patch` under nohup (untracked), then test → re-review → merge → post-merge `dart analyze` + `dart test` on main.
