#!/usr/bin/env bash
# Bootstrap driver: runs spec pipelines in dependency order.
# 002 (types/seed) → 001 (loop) → 003 (tools/MCP) → 004 (providers) → 005 (sub-agents) → 006 (evals)
# --dry-run prints the order without executing.
set -euo pipefail
cd "$(dirname "$0")/.."
ORDER=(002-state-and-sessions 001-engine-core-loop 003-tools-and-mcp 004-providers-and-fallback 005-subagents-and-declarative 006-eval-harness-golden)
for spec in "${ORDER[@]}"; do
  echo "[bootstrap] === $spec ==="
  ./scripts/pipeline.sh "$spec" "$@"
done
echo "[bootstrap] all pipelines finished"
