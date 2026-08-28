# Verification: Agent memory persistence (spec 076)

---
feature: 076-memory-persistence
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
executed_at: feat/spec-076-memory-persistence (off feat/spec-073-agent-memory 4dd76e2)
gates:
  analyze: "dart analyze --fatal-infos → No issues found! (exit 0)"
  tests: "dart test → 935 passed / 0 failed / 2 skipped (baseline 925/2 at 4dd76e2, +10 new)"
---

## Cycle integrity

- **RED (genuine)**: `test/engine/persistent_agent_memory_test.dart`
  written first and run against a missing library —
  `Error: Method not found: 'PersistentLongTermMemoryStore'` (+ further
  `MemoryJsonCodec` / `PersistentMemoryGraph` not-found errors), exit 1,
  loading failure. The implementation did not exist.
- **GREEN**: implementation landed; target file 10/10 first full run.
  One honest compile-fix iteration during GREEN (process finding #1):
  the test initially wrapped the codec's Map return values in
  `jsonDecode(...)` (which takes a String) — 5 analyze errors, fixed in the
  TEST by calling the codec directly and proving the wire format via
  `jsonDecode(jsonEncode(...))` in the round-trip test. No production code
  was changed by this fix.
- All mutation runs executed in this session with outputs captured
  verbatim; every mutant cp-restored and re-verified 10/10 green before the
  next.

## Acceptance criteria → tests (all FRs traced)

| FR | Test (test/engine/persistent_agent_memory_test.dart) | Result |
| --- | --- | --- |
| FR-001 codec lossless round-trip | `MemoryJsonCodec round-trips records and links` (incl. wire-format jsonEncode/Decode) | PASS |
| FR-002 LT write-through | `PersistentLongTermMemoryStore write-through persists to disk` | PASS |
| FR-003 restore + missing file | `restore round-trips records and links with full fidelity`; `restore on a missing file starts empty` | PASS |
| FR-004 malformed skip / corrupt loud | `restore skips malformed entries and fails loud on a corrupt file` | PASS |
| FR-005 same-id replace no duplication | `same-id replace writes through without duplication` | PASS |
| FR-006 graph write-through + restore | `PersistentMemoryGraph round-trips links and replaces idempotently` | PASS |
| FR-007 atomic writes | `atomic writes leave no temp files and always-valid JSON` (checked after EVERY mutation step) | PASS |
| FR-008 facade composition incl. promote | `full system persistence — promote survives a restart` | PASS |
| FR-009 session store not persisted | design decision documented in spec.md; pinned by A4's session note only surviving via promotion | PASS |
| FR-010 gates | analyze clean; 935/2 | PASS |

## Mutation results (deliberate, one at a time, cp-restored)

| id | mutant | result | evidence (test file run) |
| -- | ------ | ------ | ------------------------ |
| M1 | `remember` drops the write-through call (in-memory only) | **KILLED** | +4 −6: write-through `Expected: true` (file must exist); round-trip / replace / atomic / full-system / default-salience all fail on missing or stale file |
| M2 | `restore` returns before loading (no-op) | **KILLED** | +5 −5: `Expected: an object with length of <1> Actual: []` — restored records vanished (graph + codec tests unaffected, correctly) |
| M3 | per-entry malformed-skip removed (errors propagate) | **KILLED** | +9 −1: exactly the skip test fails — corrupt entry throws instead of being skipped (`Expected: length <2>`, reason `corrupt entry skipped`) |
| M4 | atomic write stops at `*.tmp` (rename skipped) | **KILLED** | +3 −7: `Expected: true` (file exists), `Expected: false` (no tmp sibling), length failures — snapshot never lands |
| M5 | codec drops `tags` on decode | **KILLED** | +8 −2: value-equality diffs `tags: [preference, style]` vs `tags: []` in codec round-trip and restore fidelity tests |

**5/5 killed.**

## Gates (actual runs at branch HEAD)

- `dart analyze --fatal-infos` → **No issues found!** (exit 0)
- `dart test` → **935 passed / 0 failed / 2 skipped** (2 pre-existing
  KIMI_API_KEY skips, unrelated)

## Findings

1. **GREEN-phase test compile fix (process, minor).** The first test run
   failed analyze 5× — the tests wrapped `MemoryJsonCodec.recordToJson`
   (returns `Map<String, dynamic>`) in `jsonDecode` (takes `String`).
   Fixed in the tests by calling the codec directly; the wire-format
   concern is retained via `jsonDecode(jsonEncode(...))` in the round-trip
   test. No production code changed.
2. **PersistentMemoryGraph shadows the base link list (design).** The
   073 `MemoryGraph.link()` stamps `createdAt: DateTime.now()` internally,
   so replaying restored links through `super.link()` would silently lose
   the persisted timestamps (FR-001 fidelity broken). The subclass
   therefore owns its link list, replicates the base semantics exactly
   (self-link ArgumentError, idempotent (from,to,type) replace), and
   overrides the read paths (`links` / `neighborsOf` / `linksOf`;
   `contradictions()` dispatches virtually). The long-term store needs no
   shadowing — `remember()` is its only mutation, super-delegation
   round-trips cleanly.
3. **Promotion persists for free (the payoff of the store-subclass
   pattern).** The facade's `promote()` routes through
   `longTermMemory.remember(...)`, so the persistent override fires without
   any facade change — pinned by the full-system restart test (the
   session note re-appears as long-term after the rebuild).
4. **Corrupt-file policy is asymmetric by design.** A malformed ENTRY is
   skipped (010 precedent — one bad record must not lose the rest); a
   malformed FILE throws `StateError` loudly. Atomic writes make torn
   files structurally impossible, so a wholly unparseable file means
   external damage — swallowing it would hide data loss.

## Verdict

**PASS.** All 10 FRs traced to passing tests; RED was genuine (missing
library); 5/5 mutants killed with verbatim evidence; gates clean at 935/2
(baseline 925/2 + 10).
