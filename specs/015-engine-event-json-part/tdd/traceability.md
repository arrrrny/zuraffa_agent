# Traceability: 015-engine-event-json-part

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:2605e5abc19c5c48f9aea71c4e8ba57f688c0447e1e352b9a5282b225a9954d9
statements: 1
automated: 1
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 28 | 1. **Given** the hand-curated sealed `EngineEvent` library with its `part 'engine_event.g.dart'` placeholder **When** the repository suite compiles and runs **Then** the part directive resolves and every engine-event behavior test passes (compilation is the pin; owner arrrrrny). | A1 | automated |

