# Gap Analysis: zuraffa_agent vs dart_agent_core

**Date**: 2026-08-27
**Purpose**: Identify features in dart_agent_core that are missing from zuraffa_agent

## Executive Summary

dart_agent_core is a mature, production-ready agent library with 19 major feature areas. zuraffa_agent has implemented the state/persistence layer (Spec 001) and engine core loop (Spec 002), but is missing critical runtime features: LLM clients, fallback chains, context compression, episodic memory, advanced loop detection, and the full eval harness.

## Feature Comparison Matrix

| # | Feature | dart_agent_core | zuraffa_agent | Gap |
|---|---------|-----------------|---------------|-----|
| 1 | Core Engine Loop | ✅ StatefulAgent (run/stream/resume) | ✅ EngineLoop | Equivalent |
| 2 | LLM Clients | ✅ 5 providers (OpenAI, Claude, Gemini, Responses, Bedrock) | ❌ None | **CRITICAL** |
| 3 | Tool System | ✅ Full (definition, dispatch, inject) | ⚠️ Validation only | Registry/dispatch missing |
| 4 | Session Persistence | ✅ FileStateStorage | ✅ InMemory/JSONL/Hive | Equivalent |
| 5 | Sub-agent Delegation | ✅ Full (clone + named) | ⚠️ Entity stubs only | Runtime missing |
| 6 | Skill System | ✅ In-memory + directory | ✅ Directory only | In-memory mode missing |
| 7 | Planner/TODO | ✅ write_todos tool | ❌ None | **MISSING** |
| 8 | Context Compression | ✅ LLM-based XML snapshots | ⚠️ Heuristic only | LLM-based missing |
| 9 | Episodic Memory | ✅ Full + retrieval tool | ❌ None | **MISSING** |
| 10 | Loop Detection | ✅ Tool + LLM-based | ⚠️ Basic stop policy | LLM-based missing |
| 11 | Agent Hooks | ✅ 9-point pipeline | ❌ None | **MISSING** |
| 12 | Event Bus | ✅ Pub/sub + request/response | ⚠️ EngineEvent only | General bus missing |
| 13 | Multimodal Messages | ✅ Full (text/image/video/audio) | ✅ Text/image/audio/doc | Equivalent |
| 14 | JavaScript Runtime | ✅ Node.js bridge | ❌ None | Not needed (engine) |
| 15 | Eval Harness | ✅ Full (runner, graders, metrics) | ⚠️ Entity stubs only | Runtime missing |
| 16 | Langfuse Observability | ✅ Full integration | ❌ None | Separate concern |
| 17 | Metrics (pass@k) | ✅ Unbiased estimator | ❌ None | **MISSING** |
| 18 | Suite Health | ✅ Saturation, calibration | ❌ None | Advanced eval |
| 19 | Data-driven Loading | ✅ SuiteLoader | ❌ None | Advanced eval |

## Critical Gaps (Must Implement)

### 1. LLM Provider Clients (CRITICAL)
**dart_agent_core**: 5 production clients with streaming, retry, multimodal
**zuraffa_agent**: Only data model (ProviderConfig, ResolvedModel)
**Impact**: Engine cannot make LLM calls without clients
**Priority**: P0

### 2. Fallback Chain with Circuit Breaker
**dart_agent_core**: Implicit via provider selection
**zuraffa_agent**: Entity stubs only (FallbackChain, ClientHealth)
**Impact**: No production reliability
**Priority**: P0

### 3. Context Compression (LLM-based)
**dart_agent_core**: LLMBasedContextCompressor with XML snapshots
**zuraffa_agent**: HeuristicSummarizer only
**Impact**: Long conversations will hit token limits
**Priority**: P1

### 4. Episodic Memory
**dart_agent_core**: Full episodic memory with retrieval tool
**zuraffa_agent**: None
**Impact**: No long-term memory across compactions
**Priority**: P1

### 5. Loop Detection (LLM-based)
**dart_agent_core**: Tool-loop + LLM stagnation diagnosis
**zuraffa_agent**: Basic StopPolicy (maxTurns, timeout, repetition)
**Impact**: Missing cognitive stagnation detection
**Priority**: P1

### 6. Agent Hooks Pipeline
**dart_agent_core**: 9-point lifecycle hooks
**zuraffa_agent**: None
**Impact**: No extensibility for plugins/middleware
**Priority**: P1

## Important Gaps (Should Implement)

### 7. Event Bus
**dart_agent_core**: General pub/sub + request/response
**zuraffa_agent**: EngineEvent sealed hierarchy only
**Impact**: Limited observability
**Priority**: P2

### 8. Planner/TODO System
**dart_agent_core**: write_todos tool with PlanState
**zuraffa_agent**: None
**Impact**: No built-in task decomposition
**Priority**: P2

### 9. MCP Client
**dart_agent_core**: N/A (uses direct tool injection)
**zuraffa_agent**: Spec 003 defined but not implemented
**Impact**: No remote tool access
**Priority**: P1

## Lower Priority Gaps

### 10. In-Memory Skill Mode
**dart_agent_core**: Two skill modes
**zuraffa_agent**: Directory only
**Impact**: Minor - directory mode is sufficient

### 11. JavaScript Runtime
**dart_agent_core**: Node.js bridge for skills
**zuraffa_agent**: None
**Impact**: Not needed for engine use case

### 12. Langfuse Observability
**dart_agent_core**: Full integration
**zuraffa_agent**: None
**Impact**: Can be added as separate integration

### 13. Suite Health / Calibration
**dart_agent_core**: Advanced eval analytics
**zuraffa_agent**: None
**Impact**: Advanced eval feature

## Recommended Spec Order

Based on dependencies and impact:

1. **Spec 007: LLM Provider Clients** - Foundation for everything
2. **Spec 008: Fallback Chain Runtime** - Production reliability
3. **Spec 009: Context Compression (LLM-based)** - Long conversation support
4. **Spec 010: Episodic Memory** - Long-term memory
5. **Spec 011: Loop Detection (LLM-based)** - Safety
6. **Spec 012: Agent Hooks Pipeline** - Extensibility
7. **Spec 013: Event Bus** - Observability
8. **Spec 014: Planner/TODO System** - Task decomposition
9. **Spec 015: MCP Client** - Remote tools
