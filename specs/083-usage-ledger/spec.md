# Feature Specification: Usage Ledger (token accounting projection)

**Feature Branch**: `083-usage-ledger`

**Created**: 2026-08-29

**Status**: Draft

**Input**: User description: "Well-defined spec for the Usage Ledger — an aggregate token-accounting read projection over usage entries for budget tracking — that is not yet covered by an existing spec (R4)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Aggregate token cost across a run (Priority: P1)

The engine records per-call `UsageEntry` records (input/output/cache tokens). The `UsageLedger` projection sums these into total input/output/cache-read/cache-write token counts so a budget tracker can decide whether the run is within its allowance.

**Why this priority**: Token accounting is the only signal a budget guard has; incorrect aggregates either over-block or let runs blow the limit.

**Independent Test**: Can be fully tested by constructing a ledger over a known list of `UsageEntry` records and asserting each aggregate equals the hand-computed sum.

**Acceptance Scenarios**:

1. **Given** entries with input tokens `[10, 20]` and output tokens `[5, 15]`, **When** the ledger totals are read, **Then** `totalInputTokens == 30`, `totalOutputTokens == 20`, `totalTokens == 50`.
2. **Given** an empty ledger, **When** totals are read, **Then** every total is 0 and `isEmpty` is true.

---

### User Story 2 - Slice the ledger by turn or model (Priority: P2)

A budget guard may want to inspect cost for a single turn or a single model. The ledger produces sub-ledgers scoped by `turnNumber` or `modelId` without mutating the source.

**Why this priority**: Per-turn / per-model attribution is needed to localize cost spikes.

**Independent Test**: Can be fully tested by building a multi-turn, multi-model ledger and asserting the sub-ledger contains exactly the matching entries and that the source ledger is unchanged.

**Acceptance Scenarios**:

1. **Given** entries across turns 1 and 2, **When** `byTurn(2)` is called, **Then** the sub-ledger contains only turn-2 entries (counts preserved).
2. **Given** entries for models `a` and `b`, **When** `byModel('a')` is called, **Then** the sub-ledger contains only model-`a` entries.

---

### Edge Cases

- A ledger over zero entries reports all totals as 0 and `isEmpty == true`.
- `byTurn`/`byModel` return a fresh ledger; the source ledger is never mutated.
- Entries with `null` model are excluded from `byModel` results (no match on `modelId`).
- Aggregation is a pure fold — no side effects, no external I/O.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `UsageLedger` MUST aggregate over its entries: `totalInputTokens`, `totalOutputTokens`, `totalTokens` (input+output), `totalCacheReadTokens`, `totalCacheWriteTokens`.
- **FR-002**: `byTurn(turnNumber)` MUST return a sub-ledger containing only entries whose `turnNumber` matches.
- **FR-003**: `byModel(modelId)` MUST return a sub-ledger containing only entries whose `model.modelId` matches.
- **FR-004**: `length`, `isEmpty`, `isNotEmpty` MUST reflect the entry count of the (sub-)ledger.

### Key Entities

- **UsageLedger**: a read-only projection over `List<UsageEntry>` providing aggregate token metrics and filtered sub-ledgers.
- **UsageEntry / UsageLedgerEntry**: the raw per-call record (entity + usecase/repository owned elsewhere) — this spec consumes it, does not redefine it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Each aggregate total equals the exact hand-computed sum across all entries (no off-by-one, no dropped field).
- **SC-002**: `byTurn`/`byModel` partition entries correctly and leave the source ledger unchanged.
- **SC-003**: An empty ledger yields zeroed totals and `isEmpty == true`.

## Assumptions

- The underlying `UsageEntry` records are produced by the LLM client layer (spec 007/051) and persisted via the usage-ledger usecases/repository; this spec owns only the aggregation/projection.
- "Budget tracking" is a consumer of these aggregates, not part of this feature.
- This feature maps to **R4 (providers & fallback, issue #5)** — provider usage accounting.
