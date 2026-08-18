#!/usr/bin/env bash
# Bootstrap driver: runs spec pipelines in dependency order.
# 001 (state/sessions/types seed) → 002 (loop) → 003 (tools/MCP) → 004 (providers) → 005 (sub-agents) → 006 (evals)
# --dry-run prints the order without executing.
set -euo pipefail
cd "$(dirname "$0")/.."
ORDER=(001-state-and-sessions 002-engine-core-loop 003-tools-and-mcp 004-providers-and-fallback 005-subagents-and-declarative 006-eval-harness-golden)
for spec in "${ORDER[@]}"; do
  echo "[bootstrap] === $spec ==="
  ./scripts/pipeline.sh "$spec" "$@"
done
echo "[bootstrap] all pipelines finished"
