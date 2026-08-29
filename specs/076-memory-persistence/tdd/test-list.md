# Test List: Agent memory persistence (spec 076)

---
feature: 076-memory-persistence
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
spec_criteria: 10 # FR-001..FR-010 in spec.md
planned_at: feat/spec-073-agent-memory (4dd76e2)
updated_at: feat/spec-076-memory-persistence (all A/U behaviors green, 5/5 mutants killed)
suite_baseline: green # 925 passed / 2 skipped at 4dd76e2 (073 branch tip)
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | Restart round-trip: remember + link → fresh store instances on the same files → restore() → record and link survive with value-object equality | FR-002, FR-003, FR-006, FR-008 | example | PASSING | `test/engine/persistent_agent_memory_test.dart::spec 076 — persistence::restore round-trips records and links with full fidelity` |
| A2  | Crash-safety: across a mutation sequence no `.tmp` survives and the target file parses as valid JSON after every step | FR-007 | example | PASSING | `…::atomic writes leave no temp files and always-valid JSON` |
| A3  | One corrupt entry among good ones is skipped on restore (010 precedent); a wholly unparseable file fails loud with StateError | FR-004 | example | PASSING | `…::restore skips malformed entries but fails loud on a corrupt file` |
| A4  | Full-system story: facade over persistent stores → remember (LT + session), link, promote → rebuild from restored stores → recall finds both long-term, graph resolves | FR-008, FR-009 | example | PASSING | `…::full system persistence — promote survives a restart` |
| A5  | Gates: `dart analyze --fatal-infos` exit 0; full `dart test` green (baseline 925/2 + new) | FR-010 | gate | PASSING | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### `lib/src/engine/persistent_agent_memory.dart` (new)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | Codec round-trips a record: id, content, tags set, source triple, UTC createdAt, salience | FR-001 | unit | PASSING | `…::MemoryJsonCodec round-trips records and links` |
| U2  | Write-through: remember lands the record in the file's records array | FR-002 | unit | PASSING | `…::PersistentLongTermMemoryStore write-through persists to disk` |
| U3  | Same-id replace: file ends with one record carrying the new content | FR-005 | unit | PASSING | `…::same-id replace writes through without duplication` |
| U4  | Missing file → restore leaves the store empty, no throw | FR-003 | unit | PASSING | `…::restore on a missing file starts empty` |
| U5  | Graph write-through + restore: type, note, createdAt survive; idempotent re-link replaces in the snapshot | FR-006 | unit | PASSING | `…::PersistentMemoryGraph round-trips links and replaces idempotently` |
| U6  | Write-through creates missing parent directories | FR-007 | unit | PASSING | `…::write-through creates missing parent directories` |
| U7  | A JSON document of the wrong shape (top-level array, missing `records`/`links`) → `StateError` | FR-004 | unit | PASSING | `…::restore fails loud on a JSON document of the wrong shape` |
| U8  | An unsupported snapshot `version` → `StateError`, not a silently truncated load | FR-004 | unit | PASSING | `…::restore fails loud on an unsupported snapshot version` |
| U9  | A record whose `tags` is not a list is skipped, not loaded with its tags dropped | FR-004 | unit | PASSING | `…::restore skips a record whose tags are not a list` |

> **U6–U9 (review round, HEAD `27371ab`)** — added after the spec-076 code
> review, each driven test-first against the unfixed implementation:
>
> | id | red command | decisive failure |
> | -- | ----------- | ---------------- |
> | U6 | `dart test test/engine/persistent_agent_memory_test.dart` | `Expected: true / Actual: <false>` with `file.parent.createSync` removed — the branch was previously untested |
> | U7 | same | characterization only — pins the two `StateError` branches no test reached; no production change |
> | U8 | same | a `{"version":2}` file loaded as an empty v1 store instead of throwing |
> | U9 | same | `Expected: false / Actual: <true>` — the bad-tags record loaded with its tags silently dropped, which the next write-through would make permanent |

## Edge cases & invariants

- Corrupt individual entry (not a map / bad field / bad salience / blank
  source) → skipped, remaining good entries load (FR-004).
- Corrupt whole file (`{not json`) → `StateError` (FR-004).
- Directory of the target file may not exist yet → created on write.
- Session memory deliberately not persisted (FR-009) — pinned by A4's
  session note only surviving *via promotion*.

## Out of scope

- `SessionMemoryStore` persistence (evaporating layer — spec 073 contract).
- Append-log format, cross-process locking, migration across versions.
- Any change to `lib/src/engine/agent_memory.dart`.

## Verification commands

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Analyze: `dart analyze --fatal-infos`
