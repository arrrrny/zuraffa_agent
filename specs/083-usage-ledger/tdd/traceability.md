# Traceability: 083-usage-ledger

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:ed84787170150bcbdf0c821f58ad9194aaff7a8e5cfdf2252fd4b92357cb903e
statements: 26
automated: 26
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 107 | - **FR-001**: The system MUST satisfy this requirement: `UsageLedger` is constructed by defensive copy into an | U1 | automated |
| FR-002 | 110 | - **FR-002**: The system MUST satisfy this requirement: `UsageLedger.entries` exposes the (unmodifiable) entry | U2 | automated |
| FR-003 | 112 | - **FR-003**: The system MUST satisfy this requirement: `UsageLedger.toJson()` serializes the projection as | U3 | automated |
| FR-004 | 116 | - **FR-004**: The system MUST satisfy this requirement: Equality is ordered-sequence equality over structurally | U4 | automated |
| FR-005 | 119 | - **FR-005**: The system MUST satisfy this requirement: Existing aggregate surface is unchanged: | U5 | automated |
| FR-006 | 125 | - **FR-006**: The system MUST satisfy this requirement: Sub-ledgers are themselves full projections: `byTurn` / | U6 | automated |
| FR-007 | 129 | - **FR-007**: The system MUST satisfy this requirement: Edge cases: an empty ledger equals every other empty ledger, | U7 | automated |
| FR-008 | 132 | - **FR-008**: The system MUST satisfy this requirement: Gates — `dart analyze` reports no new issues relative to the | U8 | automated |
| AC-1 | 168 | 1. **Given** the feature implementation under its clean-architecture seams **When** T1: structurally-identical ledgers are == and hash-equal **Then** the pinned regression test passes (`test/usage_ledger_083_test.dart`). | A1 | automated |
| AC-2 | 170 | 2. **Given** the feature implementation under its clean-architecture seams **When** T2: any content difference breaks equality **Then** the pinned regression test passes (`test/usage_ledger_083_test.dart`). | A2 | automated |
| AC-3 | 172 | 3. **Given** the feature implementation under its clean-architecture seams **When** T3: fromJson(toJson()) == ledger with all five totals preserved **Then** the pinned regression test passes (`test/usage_ledger_083_test.dart`). | A3 | automated |
| AC-4 | 174 | 4. **Given** the feature implementation under its clean-architecture seams **When** T4: empty-ledger edge — equal, round-trips, zero totals **Then** the pinned regression test passes (`test/usage_ledger_083_test.dart`). | A4 | automated |
| AC-5 | 176 | 5. **Given** the feature implementation under its clean-architecture seams **When** T5: source-list mutation after construction changes nothing **Then** the pinned regression test passes (`test/usage_ledger_083_test.dart`). | A5 | automated |
| AC-6 | 178 | 6. **Given** the feature implementation under its clean-architecture seams **When** T6: byTurn(1) round-trips and equals an independent ledger **Then** the pinned regression test passes (`test/usage_ledger_083_test.dart`). | A6 | automated |
| AC-7 | 180 | 7. **Given** the feature implementation under its clean-architecture seams **When** T7 (pin): byModel(m).byTurn(t) totals equal the intersection **Then** the pinned regression test passes (`test/usage_ledger_083_test.dart`). | A7 | automated |
| AC-8 | 182 | 8. **Given** the feature implementation under its clean-architecture seams **When** totalInputTokens sums all entries **Then** the pinned regression test passes (`test/usage_ledger_test.dart`). | A8 | automated |
| AC-9 | 184 | 9. **Given** the feature implementation under its clean-architecture seams **When** totalOutputTokens sums all entries **Then** the pinned regression test passes (`test/usage_ledger_test.dart`). | A9 | automated |
| AC-10 | 186 | 10. **Given** the feature implementation under its clean-architecture seams **When** totalTokens is input + output **Then** the pinned regression test passes (`test/usage_ledger_test.dart`). | A10 | automated |
| AC-11 | 188 | 11. **Given** the feature implementation under its clean-architecture seams **When** byTurn filters to specific turn **Then** the pinned regression test passes (`test/usage_ledger_test.dart`). | A11 | automated |
| AC-12 | 190 | 12. **Given** the feature implementation under its clean-architecture seams **When** byTurn with no matching entries returns empty ledger **Then** the pinned regression test passes (`test/usage_ledger_test.dart`). | A12 | automated |
| AC-13 | 192 | 13. **Given** the feature implementation under its clean-architecture seams **When** byModel filters to specific model **Then** the pinned regression test passes (`test/usage_ledger_test.dart`). | A13 | automated |
| AC-14 | 194 | 14. **Given** the feature implementation under its clean-architecture seams **When** byModel with no matching entries returns empty ledger **Then** the pinned regression test passes (`test/usage_ledger_test.dart`). | A14 | automated |
| AC-15 | 196 | 15. **Given** the feature implementation under its clean-architecture seams **When** empty ledger has zero totals **Then** the pinned regression test passes (`test/usage_ledger_test.dart`). | A15 | automated |
| AC-16 | 198 | 16. **Given** the feature implementation under its clean-architecture seams **When** byTurn preserves cache tokens **Then** the pinned regression test passes (`test/usage_ledger_test.dart`). | A16 | automated |
| AC-17 | 200 | 17. **Given** the feature implementation under its clean-architecture seams **When** length reflects entry count **Then** the pinned regression test passes (`test/usage_ledger_test.dart`). | A17 | automated |
| AC-18 | 202 | 18. **Given** the feature implementation under its clean-architecture seams **When** totalCacheWriteTokens sums correctly **Then** the pinned regression test passes (`test/usage_ledger_test.dart`). | A18 | automated |

