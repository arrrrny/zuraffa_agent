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
  echo "usage: $0 <spec-slug> [--from <stage>] [--dry-run]" >&2
  exit 1
fi

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
STATE_DIR=".workflow/state/$SPEC"
mkdir -p "$STATE_DIR"

log() { printf '[pipeline:%s] %s\n' "$SPEC" "$*" >&2; }

run_stage() {
  local stage="$1" prompt="$2" gate="$3"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN stage=$stage gate=[$gate]"
    return 0
  fi
  log "stage=$stage starting"
  if ! kimi -p "$prompt" --allowedTools 'Bash,Read,Write,Edit,Glob,Grep' >"$STATE_DIR/$stage.log" 2>&1; then
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
gate_impl()   { grep -qE '^- \[x\]' "specs/$SPEC/tasks.md" && ! grep -qE '^- \[ \]' "specs/$SPEC/tasks.md"; }
gate_test()   { dart analyze --fatal-infos >/dev/null 2>&1 && dart test 2>&1 | tail -1 | grep -qE 'All tests passed|No tests'; }
gate_review() { [[ -f "$STATE_DIR/review.md" ]] && grep -qE '^(VERDICT|## Verdict|Status).*(APPROVE|PASS|LGTM|approve)' "$STATE_DIR/review.md"; }
gate_patch()  { ! grep -qiE 'CRITICAL|BLOCKER' "$STATE_DIR/review.md" 2>/dev/null || git diff --quiet; }
gate_merge()  { git rev-parse --verify "origin/main" >/dev/null 2>&1 || git rev-parse --verify "origin/master" >/dev/null 2>&1; }

skip_if_done() { grep -qx "$1" "$STATE_DIR/stages.done" 2>/dev/null; }

stages=(spec plan tasks implement test review patch test merge)

declare -A prompts=(
  [spec]="Use the speckit-specify skill. Finalize the spec at specs/$SPEC/spec.md — it is already drafted from epic arrrrny/zuraffa_agent#1. Resolve template placeholders, tighten acceptance scenarios, keep Status: Draft. Do not create plan/tasks."
  [plan]="Use the speckit-plan skill. Create specs/$SPEC/plan.md from specs/$SPEC/spec.md following .specify/templates/plan-template.md. Technology context: pure Dart package, no Flutter dependency, MIT, ported sources attributed."
  [tasks]="Use the speckit-tasks skill. Create specs/$SPEC/tasks.md from specs/$SPEC/plan.md following .specify/templates/tasks-template.md. Every requirement and acceptance scenario in the spec must map to at least one checkbox task. Include unit tests as tasks."
  [implement]="Use the speckit-implement skill. Execute every unchecked task in specs/$SPEC/tasks.md in order. Follow the plan. Write code + tests. Mark tasks [x] as you complete them. Do not skip tasks; if blocked, record the blocker in the task line and stop."
  [test]="Run the full verification: dart analyze --fatal-infos and dart test. Fix ONLY failures caused by the new code (do not expand scope). If unrelated pre-existing failures exist, note them in .workflow/state/$SPEC/test-notes.md and continue. Report a one-line PASS/FAIL summary at the end."
  [review]="Act as a strict senior reviewer. Read the full diff (git diff main...HEAD or uncommitted changes) against specs/$SPEC/spec.md and plan.md. Check: acceptance scenarios satisfied, tests meaningful (not tautological), no scope creep, attribution headers on ported code, no dart:io in engine runtime paths, error paths handled. Write .workflow/state/$SPEC/review.md with findings tagged CRITICAL / MAJOR / MINOR and end with a line 'VERDICT: APPROVE' or 'VERDICT: REQUEST_CHANGES'."
  [patch]="Fix every CRITICAL and MAJOR finding listed in .workflow/state/$SPEC/review.md. MINOR findings: fix if trivial, otherwise add a TODO comment referencing the review line. Keep changes minimal and re-run dart analyze on touched files."
  [merge]="Branch check: ensure current branch is $SPEC (create from main if missing). Commit all changes with a conventional message referencing specs/$SPEC and issue arrrrny/zuraffa_agent#<n>. Then push and open a PR to main titled '$SPEC: <spec title>' body summarizing spec link, review verdict, and test summary. Do NOT merge the PR — leave it for CI + human."
)

# stage → gate function name
declare -A gates=(
  [spec]=gate_spec [plan]=gate_plan [tasks]=gate_tasks [implement]=gate_impl
  [test]=gate_test [review]=gate_review [patch]=gate_patch [merge]=gate_merge
)

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
    if [[ "$s" == "merge" ]]; then
      log "pipeline complete: PR opened for $SPEC"
    fi
  fi
done
