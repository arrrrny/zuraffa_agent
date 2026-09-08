# Traceability: 011-loop-detection-llm

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:e0b748534449b62a34b17ed0074445c17aefcf948ba915ae61571d5ff71edc56
statements: 12
automated: 12
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** the same tool call signature (name + arguments) repeated `toolLoopThreshold` times in succession, **When** the threshold is reached, **Then** a loop is detected (isLoop=true, reason "tool_call_loop", confidence 1.0) and the mission should stop. **[AC-1]** | A1 | automated |
| AC-2 | 27 | 2. **Given** a tool-call streak interrupted by a *different* tool call, **When** the different call is observed, **Then** the streak resets and no loop is detected from the earlier run. **[AC-2]** | A2 | automated |
| AC-3 | 29 | 3. **Given** tool-result or user messages interleaved between identical tool calls, **When** the detector observes them, **Then** they do not reset the streak (a call→result→call→result chain still accumulates). **[AC-3]** | A3 | automated |
| AC-4 | 42 | 4. **Given** llmCheckAfterTurns=30, **When** 30 turns pass, **Then** an LLM diagnosis is triggered (exactly one LLM call at the boundary). **[AC-4]** | A4 | automated |
| AC-5 | 44 | 5. **Given** the LLM diagnoses stagnation with confidence > stagnationThreshold (default 0.8), **When** the diagnosis returns, **Then** the loop is detected and the mission stops. **[AC-5]** | A5 | automated |
| AC-6 | 46 | 6. **Given** a diagnosis below the confidence threshold, **When** it returns, **Then** the mission continues normally (no detection). **[AC-6]** | A6 | automated |
| AC-7 | 59 | 7. **Given** custom thresholds, **When** detection runs, **Then** the configured thresholds are used. **[AC-1/AC-4/AC-6 with non-default settings]** | A7 | automated |
| FR-001 | 66 | - **FR-001**: The engine MUST detect tool call loops by tracking recent call signatures. | U1 | automated |
| FR-002 | 67 | - **FR-002**: The engine MUST detect cognitive stagnation via periodic LLM diagnosis. | U2 | automated |
| FR-003 | 68 | - **FR-003**: LLM diagnosis MUST be triggered after a configurable number of turns. | U3 | automated |
| FR-004 | 69 | - **FR-004**: Stagnation detection MUST use a confidence threshold (default 0.8). | U4 | automated |
| FR-005 | 70 | - **FR-005**: Detection parameters MUST be configurable. | U5 | automated |

