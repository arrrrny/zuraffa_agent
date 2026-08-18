#!/usr/bin/env bash
# zuraffa_agent — spec-driven pipeline driver
# Chains: spec → plan → tasks → implement → test → review → patch → test → merge
# Each stage runs `kimi -p` headless with the repo's speckit skills (.kimi-code/skills).
# Stage gates: a stage only advances when its exit condition passes.
#
# Usage: ./scripts/pipeline.sh <spec-slug> [--from <stage>] [--dry-run]
# Stages: spec plan tasks implement test review patch merge
set -euo pipefail

SPEC="${1:-}"
FROM="spec"
DRY_RUN=false
[[ "${2:-}" == "--from" ]] && FROM="${3:-spec}"
[[ "${4:-}" == "--from" ]] && FROM="${5:-spec}"
[[ "${*:-}" == *"--dry-run"* ]] && DRY_RUN=true

if [[ -z "$SPEC" ]]; then
  echo "usage: $0 <spec-slug> [--from <stage>] [--dry-run] [--skip-preflight]" >&2
  exit 1
fi

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
STATE_DIR=".workflow/state/$SPEC"
mkdir -p "$STATE_DIR"

issue_for() {
  case "$1" in
    001-engine-core-loop) echo 2 ;;
    002-state-and-sessions) echo 3 ;;
    003-tools-and-mcp) echo 4 ;;
    004-providers-and-fallback) echo 5 ;;
    005-subagents-and-declarative) echo 6 ;;
    006-eval-harness-golden) echo 7 ;;
    *) echo "" ;;
  esac
}
ISSUE="$(issue_for "$SPEC")"
ISSUE_REF="arrrrny/zuraffa_agent#${ISSUE:-n}"

log() { printf '[pipeline:%s] %s\n' "$SPEC" "$*" >&2; }

KIMI_BIN="${KIMI_BIN:-kimi}"

preflight() {
  log "preflight: validating executor contract"
  command -v "$KIMI_BIN" >/dev/null 2>&1 || { log "preflight FAIL: kimi CLI not found"; return 1; }
  command -v dart >/dev/null 2>&1 || { log "preflight FAIL: dart not found"; return 1; }
  command -v gh >/dev/null 2>&1 || { log "preflight FAIL: gh not found"; return 1; }
  # Headless round-trip with retries: a transient LLM/network/quota error must
  # not kill the run. Evidence of each attempt is kept for diagnosis.
  local i out rc attempts=3
  for i in 1 2 3; do
    out="$("$KIMI_BIN" -p "Reply with exactly: PREFLIGHT_OK" 2>"$STATE_DIR/preflight-attempt-$i.err")" && rc=0 || rc=$?
    printf '%s\n' "$out" >"$STATE_DIR/preflight-attempt-$i.out"
    if [[ $rc -eq 0 && "$out" == *"PREFLIGHT_OK"* ]]; then
      [[ $i -gt 1 ]] && log "preflight OK (passed on attempt $i)"
      return 0
    fi
    log "preflight attempt $i/$attempts failed (rc=$rc)"
    [[ $i -lt $attempts ]] && sleep $((i * 10))
  done
  log "preflight FAIL: headless round-trip failed 3x — evidence in $STATE_DIR/preflight-attempt-*.{out,err} (auth? quota? network? try: kimi doctor)"
  return 1
}

run_stage() {
  local stage="$1" prompt="$2" gate="$3"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN stage=$stage gate=[$gate]"
    return 0
  fi
  log "stage=$stage starting"
  if ! "$KIMI_BIN" -p "$prompt" >"$STATE_DIR/$stage.log" 2>&1; then
    log "stage=$stage FAILED (see $STATE_DIR/$stage.log)"
    return 1
  fi
  if [[ -n "$gate" ]] && ! eval "$gate"; then
    log "stage=$stage GATE FAILED: $gate"
    return 1
  fi
  printf '%s\n' "$stage" >>"$STATE_DIR/stages.done"
  log "stage=$stage OK"
}

gate_spec()   { [[ -f "specs/$SPEC/spec.md" && ! "$SPEC" == *"[FEATURE"* ]] && ! grep -q '\[FEATURE NAME\]' "specs/$SPEC/spec.md"; }
gate_plan()   { [[ -f "specs/$SPEC/plan.md" ]] && ! grep -qE '^\[|PLACEHOLDER' "specs/$SPEC/plan.md"; }
gate_tasks()  { [[ -f "specs/$SPEC/tasks.md" ]] && grep -qE '^- \[[ x]\]' "specs/$SPEC/tasks.md"; }
gate_impl()   { grep -qE '^- \[x\]' "specs/$SPEC/tasks.md" && ! grep -qE '^- \[ \]' "specs/$SPEC/tasks.md" && [[ -f ".zfa.json" ]] && find lib -name "*.zorphy.dart" 2>/dev/null | grep -q . && ! dart analyze 2>&1 | grep -qE "^  (error|warning)"; }
gate_test()   { dart analyze --fatal-infos >/dev/null 2>&1 && dart test 2>&1 | tail -1 | grep -qE 'All tests passed|No tests'; }
gate_review() { [[ -f "$STATE_DIR/review.md" ]] && grep -qE '^(VERDICT|## Verdict|Status).*(APPROVE|PASS|LGTM|approve)' "$STATE_DIR/review.md"; }
gate_patch()  { ! grep -qE '^#### .*🔴 (Critical|Blocker)' "$STATE_DIR/review.md" 2>/dev/null && git diff --quiet -- lib test example pubspec.yaml; }
gate_merge()  { gh pr view --json state --jq '.state == "OPEN"' 2>/dev/null | grep -q true; }

skip_if_done() { grep -qx "$1" "$STATE_DIR/stages.done" 2>/dev/null; }

stages=(spec plan tasks implement test review patch test merge)

declare -A prompts=(
  [spec]="Use the speckit-specify skill. Finalize the spec at specs/$SPEC/spec.md — it is already drafted from epic arrrrny/zuraffa_agent#1. Resolve template placeholders, tighten acceptance scenarios, keep Status: Draft. Do not create plan/tasks."
  [plan]="Use the speckit-plan skill. Create specs/$SPEC/plan.md from specs/$SPEC/spec.md following .specify/templates/plan-template.md. Technology context: pure Dart package, no Flutter dependency, MIT, ported sources attributed."
  [tasks]="Use the speckit-tasks skill. Create specs/$SPEC/tasks.md from specs/$SPEC/plan.md following .specify/templates/tasks-template.md. Every requirement and acceptance scenario in the spec must map to at least one checkbox task. Include unit tests as tasks."
  [implement]="Use the speckit-implement skill. Execute every unchecked task in specs/$SPEC/tasks.md in order. CONSTITUTION I (zfa-CLI-built only, NON-NEGOTIABLE): ALL project scaffolding, entities, enums, value objects, repositories, datasources, usecases, adapters and tests MUST be produced by the zfa CLI — zfa initialize/zfa entity create/zfa make/zfa build/zfa mock data. NEVER hand-write generated-surface code (entities, models, architecture scaffolding). Hand-write ONLY integration glue the generator genuinely cannot emit, and only if zfa produced it error-free first. CONSTITUTION X: after EVERY zfa build, run dart analyze and report BOTH errors and warnings — it MUST be pristine (zero errors, zero warnings); any finding after a build is a misfire. Never create files or import symbols from the reference/001-manual-port lineage (src/session.dart, src/compaction.dart, src/execution_env.dart, AgentSession, HeuristicSummarizer, …) — tests and barrels are generated or written strictly against zfa-generated symbols; the plan's API names must match the GENERATED surface only. ON THE FIRST zfa misfire (non-zero exit, non-compiling generated code, missing expected output, crash, or any post-build analyzer finding): your FIRST action is to write .workflow/state/$SPEC/misfire.md (exact command, expected output, actual output, root cause, reproduction), then STOP IMMEDIATELY — no workarounds, no retries with different flags, no hand-patching; the pipeline halts there. Testing comes automatically from zfa (--test). Mark tasks [x] as you complete them. Do not skip tasks; if blocked, record the blocker in the task line and stop."
  [test]="Run the full verification: dart analyze --fatal-infos and dart test. Fix ONLY failures caused by the new code (do not expand scope). If unrelated pre-existing failures exist, note them in .workflow/state/$SPEC/test-notes.md and continue. Report a one-line PASS/FAIL summary at the end."
  [review]="Prepare the work for review, then produce a CodeRabbit-style review. Steps: (1) Ensure branch '$SPEC' exists (create from main if missing), commit ALL current changes with a conventional message referencing specs/$SPEC and $ISSUE_REF, push to origin. (2) If no PR exists for the branch, open a DRAFT PR to main titled '$SPEC: <short spec title>'. (3) Invoke the coderabbit skill (Skill tool, name 'coderabbit') on the PR you opened (arrrrny/zuraffa_agent) so it fetches the diff and posts the CodeRabbit-style review: walkthrough with changes table and effort estimate, pre-merge checks, inline findings with category/severity/effort badges and committable suggestion blocks. (4) After the skill run, write .workflow/state/$SPEC/review.md mirroring every finding (file, line, severity CRITICAL/MAJOR/MINOR, one-line fix), then end the file with a final line 'VERDICT: APPROVE' (zero Critical/Major findings) or 'VERDICT: REQUEST_CHANGES'. Review contract: acceptance scenarios in specs/$SPEC/spec.md are the definition of done; ported code must carry MIT attribution headers; engine runtime paths must not import dart:io; tests must be meaningful, not tautological. If the coderabbit skill or GitHub MCP tools are unavailable (e.g. bare CI runner), skip posting and perform the identical analysis inline on git diff main...$SPEC, writing the same review.md format with badges."
  [patch]="Fix every CRITICAL and MAJOR finding listed in .workflow/state/$SPEC/review.md. MINOR findings: fix if trivial, otherwise add a TODO comment referencing the review line. Keep changes minimal; constitution I applies — zfa-generated surfaces stay generated (regenerate via zfa, never hand-edit generated files). BEFORE committing: dart analyze must be clean AND dart test must pass in full. Then commit the fixes to branch '$SPEC' and push — the open PR updates automatically."
  [merge]="The PR was opened at review stage. Finalize only: (1) confirm .workflow/state/$SPEC/review.md ends with 'VERDICT: APPROVE' — if not, stop and report. (2) Push any uncommitted changes to branch '$SPEC'. (3) Update the PR body with: spec link (specs/$SPEC/spec.md), the review verdict and link to the posted CodeRabbit review, and the test summary. (4) Convert the PR from draft to ready-for-review if applicable. Do NOT merge the PR — CI and the human merge it."
)

# stage → gate function name
declare -A gates=(
  [spec]=gate_spec [plan]=gate_plan [tasks]=gate_tasks [implement]=gate_impl
  [test]=gate_test [review]=gate_review [patch]=gate_patch [merge]=gate_merge
)

if [[ "$DRY_RUN" != true && "${*:-}" != *"--skip-preflight"* ]]; then
  preflight || { log "halting: preflight failed"; exit 1; }
fi

started=false
for s in "${stages[@]}"; do
  # second 'test' after patch is the same gate, no skip-marker conflict: use order marker
  if [[ "$FROM" == "$s" || "$started" == true ]]; then
    started=true
    if skip_if_done "$s" && [[ "$s" != "test" ]]; then
      log "stage=$s already done, skipping"
      continue
    fi
    run_stage "$s" "${prompts[$s]}" "${gates[$s]}" || { log "pipeline halted at stage=$s"; exit 1; }
    # Constitution I/II: a zfa misfire halts everything — no stage may proceed past it.
    if [[ -f "$STATE_DIR/misfire.md" ]]; then
      log "ZFA MISFIRE recorded in $STATE_DIR/misfire.md — pipeline halted (constitution I/II). Fix zuraffa upstream, then resume with --from implement."
      exit 1
    fi
    if [[ "$s" == "merge" ]]; then
      log "pipeline complete: PR opened for $SPEC"
    fi
  fi
done
